-- Public catalog projections expose only published learning data.
create or replace view public.public_course_catalog
with (security_invoker = true)
as
select
  c.id,
  c.slug,
  c.title,
  c.summary,
  c.description,
  c.learning_outcomes,
  c.is_featured,
  c.monthly_fee_poisha,
  c.one_time_fee_poisha,
  c.cover_object_key,
  cl.name as class_name,
  cl.slug as class_slug,
  (
    select cat.name
    from public.course_categories cc
    join public.categories cat on cat.id = cc.category_id
    where cc.course_id = c.id and cat.is_active
    order by cat.sort_order, cat.name
    limit 1
  ) as category_name,
  (
    select cat.slug
    from public.course_categories cc
    join public.categories cat on cat.id = cc.category_id
    where cc.course_id = c.id and cat.is_active
    order by cat.sort_order, cat.name
    limit 1
  ) as category_slug,
  (
    select tp.display_name
    from public.course_teachers ct
    join public.teacher_profiles tp on tp.profile_id = ct.profile_id
    where ct.course_id = c.id
      and tp.is_public
      and app_private.is_public_teacher(ct.profile_id)
    order by tp.display_name
    limit 1
  ) as instructor_name
from public.courses c
left join public.classes cl on cl.id = c.class_id
where c.status = 'published' and c.visibility = 'public';

create or replace view public.public_class_catalog
with (security_invoker = true)
as
select
  cl.id,
  cl.name,
  cl.slug,
  cl.sort_order,
  count(c.id)::integer as published_course_count
from public.classes cl
left join public.courses c
  on c.class_id = cl.id
  and c.status = 'published'
  and c.visibility = 'public'
where cl.is_active
group by cl.id, cl.name, cl.slug, cl.sort_order;

create or replace view public.public_course_module_previews
with (security_invoker = true)
as
select
  m.course_id,
  m.title,
  m.sort_order,
  count(l.id)::integer as lesson_count
from public.course_modules m
join public.courses c
  on c.id = m.course_id
  and c.status = 'published'
  and c.visibility = 'public'
left join public.lessons l
  on l.module_id = m.id
  and l.is_public_preview
  and l.published_at is not null
where m.is_public_preview
group by m.id, m.course_id, m.title, m.sort_order;

grant select on public.public_course_catalog,
  public.public_class_catalog,
  public.public_course_module_previews
to anon, authenticated;

create or replace view public.public_category_catalog
with (security_invoker = true)
as
select distinct cat.id, cat.name, cat.slug, cat.sort_order
from public.categories cat
join public.course_categories cc on cc.category_id = cat.id
join public.courses c
  on c.id = cc.course_id
  and c.status = 'published'
  and c.visibility = 'public'
where cat.is_active;

grant select on public.public_category_catalog to anon, authenticated;

create or replace function public.search_public_courses(
  p_class_slug text default null,
  p_category_slug text default null,
  p_search text default null
)
returns table (
  id uuid,
  slug text,
  title text,
  summary text,
  class_name text,
  category_name text,
  cover_object_key text,
  monthly_fee_poisha integer,
  one_time_fee_poisha integer,
  instructor_name text
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    catalog.id,
    catalog.slug,
    catalog.title,
    catalog.summary,
    catalog.class_name,
    catalog.category_name,
    catalog.cover_object_key,
    catalog.monthly_fee_poisha,
    catalog.one_time_fee_poisha,
    catalog.instructor_name
  from public.public_course_catalog catalog
  where (p_class_slug is null or catalog.class_slug = p_class_slug)
    and (p_category_slug is null or catalog.category_slug = p_category_slug)
    and (
      nullif(trim(p_search), '') is null
      or concat_ws(
        ' ',
        catalog.title,
        catalog.summary,
        catalog.class_name,
        catalog.category_name,
        catalog.instructor_name
      ) ilike '%' || trim(p_search) || '%'
    )
  order by catalog.title
  limit 200
$$;

revoke all on function public.search_public_courses(text, text, text) from public;
grant execute on function public.search_public_courses(text, text, text) to anon, authenticated;

create or replace function public.public_overview_counts()
returns table (
  active_student_count bigint,
  published_course_count bigint,
  teacher_count bigint
)
language sql
stable
security definer
set search_path = pg_catalog, public
set row_security = off
as $$
  select
    (
      select count(distinct a.profile_id)
      from public.admissions a
      join public.user_profiles up on up.id = a.profile_id
      join public.user_roles ur on ur.profile_id = a.profile_id
      join public.roles r on r.id = ur.role_id
      where a.status = 'active'
        and up.status = 'active'
        and r.slug = 'student'
    ),
    (
      select count(*)
      from public.courses c
      where c.status = 'published' and c.visibility = 'public'
    ),
    (
      select count(distinct tp.profile_id)
      from public.teacher_profiles tp
      join public.user_profiles up on up.id = tp.profile_id
      join public.user_roles ur on ur.profile_id = tp.profile_id
      join public.roles r on r.id = ur.role_id
      where tp.is_public and up.status = 'active' and r.slug = 'teacher'
    )
$$;

revoke all on function public.public_overview_counts() from public;
grant execute on function public.public_overview_counts() to anon, authenticated;

create or replace function app_private.can_access_course_storage_path(
  object_name text,
  allow_write boolean default false
)
returns boolean
language plpgsql
stable
set search_path = pg_catalog, public, storage, app_private
as $$
declare
  path_parts text[];
  target_course_id uuid;
begin
  path_parts := storage.foldername(object_name);
  if coalesce(array_length(path_parts, 1), 0) < 1
     or path_parts[1] !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    return false;
  end if;

  target_course_id := path_parts[1]::uuid;
  if allow_write then
    return app_private.has_permission('manage_courses')
      or (
        app_private.has_permission('manage_course_content')
        and app_private.is_teacher_for_course(target_course_id)
      );
  end if;

  return app_private.has_active_course_access(target_course_id);
end;
$$;

grant execute on function app_private.can_access_course_storage_path(text, boolean)
  to authenticated;

-- Durable public course covers and private enrolled-course resources.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'course-covers',
    'course-covers',
    true,
    10485760,
    array['image/jpeg', 'image/png', 'image/webp', 'image/avif']
  ),
  (
    'course-content',
    'course-content',
    false,
    209715200,
    array[
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/webp',
      'video/mp4',
      'video/webm',
      'audio/mpeg',
      'audio/mp4'
    ]
  )
on conflict (id) do update
set name = excluded.name,
    public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

alter table storage.objects enable row level security;

create policy "public can read course covers"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'course-covers');
create policy "course managers upload covers"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'course-covers'
    and app_private.has_permission('manage_courses')
  );
create policy "course managers update covers"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'course-covers'
    and app_private.has_permission('manage_courses')
  )
  with check (
    bucket_id = 'course-covers'
    and app_private.has_permission('manage_courses')
  );
create policy "course managers remove covers"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'course-covers'
    and app_private.has_permission('manage_courses')
  );

create policy "enrolled learners and assigned teachers read course content"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'course-content'
    and app_private.can_access_course_storage_path(name, false)
  );
create policy "assigned teachers upload course content"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'course-content'
    and app_private.can_access_course_storage_path(name, true)
  );
create policy "assigned teachers update course content"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'course-content'
    and app_private.can_access_course_storage_path(name, true)
  )
  with check (
    bucket_id = 'course-content'
    and app_private.can_access_course_storage_path(name, true)
  );
create policy "assigned teachers delete course content"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'course-content'
    and app_private.can_access_course_storage_path(name, true)
  );
