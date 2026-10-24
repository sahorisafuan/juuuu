-- Every public-schema application table is protected by RLS.
do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'user_profiles', 'roles', 'permissions', 'role_permissions', 'user_roles',
    'user_permissions', 'teacher_invitations', 'teacher_profiles', 'classes',
    'categories', 'courses', 'course_categories', 'course_teachers',
    'course_prerequisites', 'course_modules', 'lessons', 'lesson_resources',
    'lesson_progress', 'admission_applications', 'admissions', 'enrollments',
    'enrollment_events', 'fee_policies', 'billing_plans', 'invoices',
    'invoice_items', 'payment_attempts', 'payment_events', 'payment_reconciliation',
    'refunds', 'manual_payment_adjustments', 'live_sessions', 'question_bank',
    'question_options', 'exams', 'exam_questions', 'exam_question_keys',
    'exam_attempts', 'attempt_answers', 'manual_grading', 'exam_results',
    'site_settings', 'homepage_sections', 'announcements', 'notifications',
    'notification_preferences', 'audit_logs', 'session_audit_events'
  ]
  loop
    execute format('alter table public.%I enable row level security', table_name);
  end loop;
end
$$;

grant usage on schema public to anon, authenticated, service_role;
grant usage on schema app_private to anon;
grant all privileges on all tables in schema public to service_role;

-- Public catalog reads are deliberately narrow. Mutations go through server-side
-- actions that verify the Clerk identity and app permission before using the
-- server-only service key.
grant select on public.classes, public.categories, public.courses,
  public.course_categories, public.course_teachers, public.teacher_profiles,
  public.course_modules, public.lessons, public.lesson_resources,
  public.fee_policies, public.billing_plans, public.site_settings,
  public.homepage_sections, public.announcements
to anon, authenticated;

create policy "active classes are public"
  on public.classes for select to anon, authenticated
  using (is_active);
create policy "admins manage classes"
  on public.classes for all to authenticated
  using (app_private.has_permission('manage_courses'))
  with check (app_private.has_permission('manage_courses'));

create policy "active categories are public"
  on public.categories for select to anon, authenticated
  using (is_active);
create policy "admins manage categories"
  on public.categories for all to authenticated
  using (app_private.has_permission('manage_categories'))
  with check (app_private.has_permission('manage_categories'));

create policy "published courses are public"
  on public.courses for select to anon, authenticated
  using (status = 'published' and visibility = 'public');
create policy "authorized users read assigned courses"
  on public.courses for select to authenticated
  using (
    app_private.has_permission('manage_courses')
    or app_private.is_teacher_for_course(id)
    or app_private.has_active_course_access(id)
  );
create policy "course managers manage courses"
  on public.courses for all to authenticated
  using (
    app_private.has_permission('manage_courses')
    or (
      app_private.has_permission('manage_course_content')
      and app_private.is_teacher_for_course(id)
    )
  )
  with check (
    app_private.has_permission('manage_courses')
    or (
      app_private.has_permission('manage_course_content')
      and app_private.is_teacher_for_course(id)
    )
  );

create policy "public course categories"
  on public.course_categories for select to anon, authenticated
  using (
    exists (
      select 1 from public.courses c
      where c.id = course_id and c.status = 'published' and c.visibility = 'public'
    )
  );
create policy "authorized course category access"
  on public.course_categories for select to authenticated
  using (
    app_private.has_permission('manage_courses')
    or app_private.is_teacher_for_course(course_id)
    or app_private.has_active_course_access(course_id)
  );
create policy "course managers manage course categories"
  on public.course_categories for all to authenticated
  using (
    app_private.has_permission('manage_courses')
    or (
      app_private.has_permission('manage_categories')
      and app_private.is_teacher_for_course(course_id)
    )
  )
  with check (
    app_private.has_permission('manage_courses')
    or (
      app_private.has_permission('manage_categories')
      and app_private.is_teacher_for_course(course_id)
    )
  );

create policy "public teacher profiles are limited"
  on public.teacher_profiles for select to anon, authenticated
  using (app_private.is_public_teacher(profile_id));
create policy "teachers read own profile and admins read all"
  on public.teacher_profiles for select to authenticated
  using (
    profile_id = app_private.current_profile_id()
    or app_private.has_permission('manage_teachers')
  );

create policy "public teacher assignments for published courses"
  on public.course_teachers for select to anon, authenticated
  using (
    exists (
      select 1 from public.courses c
      where c.id = course_id and c.status = 'published' and c.visibility = 'public'
    )
    and exists (
      select 1 from public.teacher_profiles tp
      where tp.profile_id = course_teachers.profile_id and tp.is_public
    )
  );
create policy "authorized users read teacher assignments"
  on public.course_teachers for select to authenticated
  using (
    app_private.has_permission('manage_teachers')
    or app_private.is_teacher_for_course(course_id)
  );
create policy "admins manage teacher assignments"
  on public.course_teachers for all to authenticated
  using (app_private.has_permission('manage_teachers'))
  with check (app_private.has_permission('manage_teachers'));

create policy "public prerequisite information"
  on public.course_prerequisites for select to anon, authenticated
  using (
    exists (
      select 1 from public.courses c
      where c.id = course_id and c.status = 'published' and c.visibility = 'public'
    )
  );
create policy "authorized prerequisite access"
  on public.course_prerequisites for select to authenticated
  using (
    app_private.has_permission('manage_courses')
    or app_private.is_teacher_for_course(course_id)
    or app_private.has_active_course_access(course_id)
  );
create policy "course managers manage prerequisites"
  on public.course_prerequisites for all to authenticated
  using (
    app_private.has_permission('manage_courses')
    or (
      app_private.has_permission('manage_course_content')
      and app_private.is_teacher_for_course(course_id)
    )
  )
  with check (
    app_private.has_permission('manage_courses')
    or (
      app_private.has_permission('manage_course_content')
      and app_private.is_teacher_for_course(course_id)
    )
  );

create policy "published module previews"
  on public.course_modules for select to anon, authenticated
  using (
    is_public_preview
    and exists (
      select 1 from public.courses c
      where c.id = course_id and c.status = 'published' and c.visibility = 'public'
    )
  );
create policy "enrolled users and teachers read modules"
  on public.course_modules for select to authenticated
  using (
    app_private.has_active_course_access(course_id)
    or app_private.has_permission('manage_courses')
  );
create policy "authorized users manage modules"
  on public.course_modules for all to authenticated
  using (
    app_private.has_permission('manage_courses')
    or (
      app_private.has_permission('manage_course_content')
      and app_private.is_teacher_for_course(course_id)
    )
  )
  with check (
    app_private.has_permission('manage_courses')
    or (
      app_private.has_permission('manage_course_content')
      and app_private.is_teacher_for_course(course_id)
    )
  );

create policy "published lesson previews"
  on public.lessons for select to anon, authenticated
  using (
    is_public_preview
    and published_at is not null
    and exists (
      select 1
      from public.course_modules m
      join public.courses c on c.id = m.course_id
      where m.id = module_id
        and m.is_public_preview
        and c.status = 'published'
        and c.visibility = 'public'
    )
  );
create policy "enrolled users and teachers read lessons"
  on public.lessons for select to authenticated
  using (
    exists (
      select 1
      from public.course_modules m
      where m.id = module_id and app_private.has_active_course_access(m.course_id)
    )
  );
create policy "authorized users manage lessons"
  on public.lessons for all to authenticated
  using (
    exists (
      select 1 from public.course_modules m
      where m.id = module_id
        and (
          app_private.has_permission('manage_courses')
          or (
            app_private.has_permission('manage_course_content')
            and app_private.is_teacher_for_course(m.course_id)
          )
        )
    )
  )
  with check (
    exists (
      select 1 from public.course_modules m
      where m.id = module_id
        and (
          app_private.has_permission('manage_courses')
          or (
            app_private.has_permission('manage_course_content')
            and app_private.is_teacher_for_course(m.course_id)
          )
        )
    )
  );

create policy "public lesson preview resources"
  on public.lesson_resources for select to anon, authenticated
  using (
    is_public_preview
    and exists (
      select 1
      from public.lessons l
      join public.course_modules m on m.id = l.module_id
      join public.courses c on c.id = m.course_id
      where l.id = lesson_id
        and l.is_public_preview
        and m.is_public_preview
        and c.status = 'published'
        and c.visibility = 'public'
    )
  );
create policy "enrolled users and teachers read lesson resources"
  on public.lesson_resources for select to authenticated
  using (
    exists (
      select 1
      from public.lessons l
      join public.course_modules m on m.id = l.module_id
      where l.id = lesson_id and app_private.has_active_course_access(m.course_id)
    )
  );
create policy "authorized users manage lesson resources"
  on public.lesson_resources for all to authenticated
  using (
    app_private.has_permission('manage_courses')
    or exists (
      select 1
      from public.lessons l
      join public.course_modules m on m.id = l.module_id
      where l.id = lesson_id
        and app_private.has_permission('manage_course_content')
        and app_private.is_teacher_for_course(m.course_id)
    )
  )
  with check (
    app_private.has_permission('manage_courses')
    or exists (
      select 1
      from public.lessons l
      join public.course_modules m on m.id = l.module_id
      where l.id = lesson_id
        and app_private.has_permission('manage_course_content')
        and app_private.is_teacher_for_course(m.course_id)
    )
  );

-- Private identity and role records.
grant select on public.user_profiles, public.roles, public.permissions,
  public.role_permissions, public.user_roles, public.user_permissions,
  public.teacher_invitations
to authenticated;

create policy "users read own profile; admins read all"
  on public.user_profiles for select to authenticated
  using (
    id = app_private.current_profile_id()
    or app_private.has_permission('manage_users')
  );
grant update (full_name, phone, preferred_language)
  on public.user_profiles to authenticated;
create policy "users update permitted profile fields"
  on public.user_profiles for update to authenticated
  using (id = app_private.current_profile_id())
  with check (id = app_private.current_profile_id());
create policy "admins manage profile records"
  on public.user_profiles for all to authenticated
  using (app_private.has_permission('manage_users'))
  with check (app_private.has_permission('manage_users'));

create policy "authenticated users read role catalog"
  on public.roles for select to authenticated using (true);
create policy "admins manage roles"
  on public.roles for all to authenticated
  using (app_private.has_permission('manage_roles'))
  with check (app_private.has_permission('manage_roles'));
create policy "authenticated users read permission catalog"
  on public.permissions for select to authenticated using (true);
create policy "admins manage permissions"
  on public.permissions for all to authenticated
  using (app_private.has_permission('manage_roles'))
  with check (app_private.has_permission('manage_roles'));
create policy "authenticated users read role permissions"
  on public.role_permissions for select to authenticated using (true);
create policy "admins manage role permissions"
  on public.role_permissions for all to authenticated
  using (app_private.has_permission('manage_roles'))
  with check (app_private.has_permission('manage_roles'));
create policy "users read own roles; admins read all"
  on public.user_roles for select to authenticated
  using (
    profile_id = app_private.current_profile_id()
    or app_private.has_permission('manage_roles')
  );
create policy "admins manage user roles"
  on public.user_roles for all to authenticated
  using (
    app_private.has_permission('manage_roles')
    and app_private.has_permission('manage_users')
  )
  with check (
    app_private.has_permission('manage_roles')
    and app_private.has_permission('manage_users')
  );
create policy "users read own permission overrides; admins read all"
  on public.user_permissions for select to authenticated
  using (
    profile_id = app_private.current_profile_id()
    or app_private.has_permission('manage_roles')
  );
create policy "admins manage user permission overrides"
  on public.user_permissions for all to authenticated
  using (
    app_private.has_permission('manage_roles')
    and app_private.has_permission('manage_users')
  )
  with check (
    app_private.has_permission('manage_roles')
    and app_private.has_permission('manage_users')
  );
create policy "admins manage teacher invitations"
  on public.teacher_invitations for all to authenticated
  using (app_private.has_permission('manage_teachers'))
  with check (app_private.has_permission('manage_teachers'));

-- Admission, enrollment, sessions, and student progress.
grant select on public.admission_applications, public.admissions, public.enrollments,
  public.enrollment_events, public.lesson_progress, public.live_sessions
to authenticated;

create policy "students read own admission applications"
  on public.admission_applications for select to authenticated
  using (
    profile_id = app_private.current_profile_id()
    or app_private.has_permission('manage_admissions')
  );
create policy "students submit own admission applications"
  on public.admission_applications for insert to authenticated
  with check (
    profile_id = app_private.current_profile_id()
    and status = 'submitted'
  );
create policy "admins manage admission applications"
  on public.admission_applications for all to authenticated
  using (app_private.has_permission('manage_admissions'))
  with check (app_private.has_permission('manage_admissions'));

create policy "students read own admission; admins manage"
  on public.admissions for select to authenticated
  using (
    profile_id = app_private.current_profile_id()
    or app_private.has_permission('manage_admissions')
  );
create policy "admins manage admissions"
  on public.admissions for all to authenticated
  using (app_private.has_permission('manage_admissions'))
  with check (app_private.has_permission('manage_admissions'));

create policy "students and assigned teachers read enrollments"
  on public.enrollments for select to authenticated
  using (
    profile_id = app_private.current_profile_id()
    or app_private.has_permission('manage_admissions')
    or app_private.is_teacher_for_course(course_id)
  );
create policy "admins manage enrollments"
  on public.enrollments for all to authenticated
  using (app_private.has_permission('manage_admissions'))
  with check (app_private.has_permission('manage_admissions'));

create policy "students, assigned teachers, and admins read enrollment events"
  on public.enrollment_events for select to authenticated
  using (
    app_private.has_permission('manage_admissions')
    or exists (
      select 1
      from public.enrollments e
      where e.id = enrollment_id
        and (
          e.profile_id = app_private.current_profile_id()
          or app_private.is_teacher_for_course(e.course_id)
        )
    )
  );

create policy "students read and update own lesson progress"
  on public.lesson_progress for select to authenticated
  using (
    profile_id = app_private.current_profile_id()
    or exists (
      select 1
      from public.lessons l
      join public.course_modules m on m.id = l.module_id
      where l.id = lesson_id
        and app_private.is_teacher_for_course(m.course_id)
    )
  );
create policy "students manage own lesson progress"
  on public.lesson_progress for all to authenticated
  using (
    profile_id = app_private.current_profile_id()
    and exists (
      select 1
      from public.lessons l
      join public.course_modules m on m.id = l.module_id
      where l.id = lesson_id and app_private.has_active_course_access(m.course_id)
    )
  )
  with check (
    profile_id = app_private.current_profile_id()
    and exists (
      select 1
      from public.lessons l
      join public.course_modules m on m.id = l.module_id
      where l.id = lesson_id and app_private.has_active_course_access(m.course_id)
    )
  );
create policy "authorized users read course sessions"
  on public.live_sessions for select to authenticated
  using (
    app_private.has_active_course_access(course_id)
    or app_private.has_permission('manage_courses')
  );
create policy "authorized users manage course sessions"
  on public.live_sessions for all to authenticated
  using (
    app_private.has_permission('manage_courses')
    or (
      app_private.has_permission('manage_course_content')
      and app_private.is_teacher_for_course(course_id)
    )
  )
  with check (
    app_private.has_permission('manage_courses')
    or (
      app_private.has_permission('manage_course_content')
      and app_private.is_teacher_for_course(course_id)
    )
  );

-- Billing data is visible only to the bill-to student and authorized administrators.
grant select on public.fee_policies, public.billing_plans, public.invoices,
  public.invoice_items, public.payment_attempts, public.payment_events,
  public.payment_reconciliation, public.refunds, public.manual_payment_adjustments
to authenticated;

create policy "currently active fee policies are public"
  on public.fee_policies for select to anon, authenticated
  using (
    is_active
    and valid_from <= now()
    and (valid_until is null or valid_until > now())
  );
create policy "billing admins manage fee policies"
  on public.fee_policies for all to authenticated
  using (app_private.has_permission('manage_billing'))
  with check (app_private.has_permission('manage_billing'));
create policy "active billing plans are public"
  on public.billing_plans for select to anon, authenticated
  using (is_active);
create policy "billing admins manage plans"
  on public.billing_plans for all to authenticated
  using (app_private.has_permission('manage_billing'))
  with check (app_private.has_permission('manage_billing'));

create policy "students read own invoices; billing admins read all"
  on public.invoices for select to authenticated
  using (
    profile_id = app_private.current_profile_id()
    or app_private.has_permission('manage_billing')
  );
create policy "invoice owners read line items"
  on public.invoice_items for select to authenticated
  using (
    exists (
      select 1 from public.invoices i
      where i.id = invoice_id
        and (
          i.profile_id = app_private.current_profile_id()
          or app_private.has_permission('manage_billing')
        )
    )
  );
create policy "students read own payment attempts; billing admins read all"
  on public.payment_attempts for select to authenticated
  using (
    exists (
      select 1 from public.invoices i
      where i.id = invoice_id
        and (
          i.profile_id = app_private.current_profile_id()
          or app_private.has_permission('manage_billing')
        )
    )
  );
create policy "billing admins read payment events"
  on public.payment_events for select to authenticated
  using (app_private.has_permission('manage_billing'));
create policy "billing admins read reconciliation records"
  on public.payment_reconciliation for select to authenticated
  using (app_private.has_permission('manage_billing'));
create policy "students read own refund requests; admins manage"
  on public.refunds for select to authenticated
  using (
    requested_by = app_private.current_profile_id()
    or app_private.has_permission('manage_refunds')
  );
create policy "students request refunds for own payments"
  on public.refunds for insert to authenticated
  with check (
    requested_by = app_private.current_profile_id()
    and status = 'requested'
    and exists (
      select 1
      from public.payment_attempts pa
      join public.invoices i on i.id = pa.invoice_id
      where pa.id = payment_attempt_id
        and i.profile_id = app_private.current_profile_id()
        and pa.status = 'completed'
    )
  );
create policy "refund admins manage requests"
  on public.refunds for all to authenticated
  using (app_private.has_permission('manage_refunds'))
  with check (app_private.has_permission('manage_refunds'));
create policy "billing admins read manual adjustments"
  on public.manual_payment_adjustments for select to authenticated
  using (app_private.has_permission('manage_billing'));

-- Assessment access never exposes answer keys to students.
grant select on public.question_bank, public.question_options, public.exams,
  public.exam_questions, public.exam_attempts, public.attempt_answers,
  public.manual_grading, public.exam_results
to authenticated;

create policy "teachers and admins manage question bank"
  on public.question_bank for all to authenticated
  using (
    app_private.has_permission('manage_exams')
    and (
      course_id is null
      or app_private.has_permission('manage_courses')
      or app_private.is_teacher_for_course(course_id)
    )
  )
  with check (
    app_private.has_permission('manage_exams')
    and (
      course_id is null
      or app_private.has_permission('manage_courses')
      or app_private.is_teacher_for_course(course_id)
    )
  );
create policy "teachers and admins manage question options"
  on public.question_options for all to authenticated
  using (
    exists (
      select 1 from public.question_bank q
      where q.id = question_id
        and app_private.has_permission('manage_exams')
        and (
          q.course_id is null
          or app_private.has_permission('manage_courses')
          or app_private.is_teacher_for_course(q.course_id)
        )
    )
  )
  with check (
    exists (
      select 1 from public.question_bank q
      where q.id = question_id
        and app_private.has_permission('manage_exams')
        and (
          q.course_id is null
          or app_private.has_permission('manage_courses')
          or app_private.is_teacher_for_course(q.course_id)
        )
    )
  );
create policy "published exams visible to enrolled students"
  on public.exams for select to authenticated
  using (
    (
      status = 'published'
      and app_private.has_active_course_access(course_id)
    )
    or app_private.has_permission('manage_courses')
    or (
      app_private.has_permission('manage_exams')
      and app_private.is_teacher_for_course(course_id)
    )
  );
create policy "authorized teachers and admins manage exams"
  on public.exams for all to authenticated
  using (
    app_private.has_permission('manage_courses')
    or (
      app_private.has_permission('manage_exams')
      and app_private.is_teacher_for_course(course_id)
    )
  )
  with check (
    app_private.has_permission('manage_courses')
    or (
      app_private.has_permission('manage_exams')
      and app_private.is_teacher_for_course(course_id)
    )
  );
create policy "students see exam question snapshots only when eligible"
  on public.exam_questions for select to authenticated
  using (
    exists (
      select 1 from public.exams e
      where e.id = exam_id
        and (
          (e.status = 'published' and app_private.has_active_course_access(e.course_id))
          or app_private.has_permission('manage_courses')
          or (
            app_private.has_permission('manage_exams')
            and app_private.is_teacher_for_course(e.course_id)
          )
        )
    )
  );
create policy "authorized teachers and admins manage exam questions"
  on public.exam_questions for all to authenticated
  using (
    exists (
      select 1 from public.exams e
      where e.id = exam_id
        and (
          app_private.has_permission('manage_courses')
          or (
            app_private.has_permission('manage_exams')
            and app_private.is_teacher_for_course(e.course_id)
          )
        )
    )
  )
  with check (
    exists (
      select 1 from public.exams e
      where e.id = exam_id
        and (
          app_private.has_permission('manage_courses')
          or (
            app_private.has_permission('manage_exams')
            and app_private.is_teacher_for_course(e.course_id)
          )
        )
    )
  );
create policy "answer keys stay with authorized graders"
  on public.exam_question_keys for all to authenticated
  using (
    exists (
      select 1
      from public.exam_questions eq
      join public.exams e on e.id = eq.exam_id
      where eq.id = exam_question_id
        and (
          app_private.has_permission('manage_courses')
          or (
            app_private.has_permission('manage_exams')
            and app_private.is_teacher_for_course(e.course_id)
          )
        )
    )
  )
  with check (
    exists (
      select 1
      from public.exam_questions eq
      join public.exams e on e.id = eq.exam_id
      where eq.id = exam_question_id
        and (
          app_private.has_permission('manage_courses')
          or (
            app_private.has_permission('manage_exams')
            and app_private.is_teacher_for_course(e.course_id)
          )
        )
    )
  );

create policy "students read own exam attempts; graders read assigned attempts"
  on public.exam_attempts for select to authenticated
  using (
    profile_id = app_private.current_profile_id()
    or app_private.has_permission('manage_courses')
    or exists (
      select 1 from public.exams e
      where e.id = exam_id
        and app_private.has_permission('manage_exams')
        and app_private.is_teacher_for_course(e.course_id)
    )
  );
create policy "students start attempts only for eligible exams"
  on public.exam_attempts for insert to authenticated
  with check (
    profile_id = app_private.current_profile_id()
    and status = 'in_progress'
    and exists (
      select 1 from public.exams e
      where e.id = exam_id
        and e.status = 'published'
        and app_private.has_active_course_access(e.course_id)
        and (e.starts_at is null or e.starts_at <= now())
        and (e.ends_at is null or e.ends_at > now())
    )
  );
create policy "students update only their in-progress attempts"
  on public.exam_attempts for update to authenticated
  using (
    profile_id = app_private.current_profile_id()
    and status = 'in_progress'
  )
  with check (
    profile_id = app_private.current_profile_id()
    and status in ('in_progress', 'submitted', 'expired')
  );
create policy "authorized graders manage exam attempts"
  on public.exam_attempts for all to authenticated
  using (
    app_private.has_permission('manage_courses')
    or exists (
      select 1 from public.exams e
      where e.id = exam_id
        and app_private.has_permission('manage_exams')
        and app_private.is_teacher_for_course(e.course_id)
    )
  )
  with check (
    app_private.has_permission('manage_courses')
    or exists (
      select 1 from public.exams e
      where e.id = exam_id
        and app_private.has_permission('manage_exams')
        and app_private.is_teacher_for_course(e.course_id)
    )
  );

create policy "students read own answers; graders read assigned answers"
  on public.attempt_answers for select to authenticated
  using (
    exists (
      select 1 from public.exam_attempts a
      where a.id = attempt_id
        and (
          a.profile_id = app_private.current_profile_id()
          or app_private.has_permission('manage_courses')
          or exists (
            select 1 from public.exams e
            where e.id = a.exam_id
              and app_private.has_permission('manage_exams')
              and app_private.is_teacher_for_course(e.course_id)
          )
        )
    )
  );
create policy "students edit answers only in their own active attempts"
  on public.attempt_answers for all to authenticated
  using (
    exists (
      select 1 from public.exam_attempts a
      where a.id = attempt_id
        and a.profile_id = app_private.current_profile_id()
        and a.status = 'in_progress'
    )
  )
  with check (
    exists (
      select 1 from public.exam_attempts a
      where a.id = attempt_id
        and a.profile_id = app_private.current_profile_id()
        and a.status = 'in_progress'
    )
  );
create policy "authorized graders read manual grading"
  on public.manual_grading for select to authenticated
  using (
    app_private.has_permission('manage_courses')
    or exists (
      select 1
      from public.attempt_answers aa
      join public.exam_attempts a on a.id = aa.attempt_id
      join public.exams e on e.id = a.exam_id
      where aa.id = attempt_answer_id
        and app_private.has_permission('manage_exam_results')
        and app_private.is_teacher_for_course(e.course_id)
    )
  );
create policy "authorized graders manage manual grading"
  on public.manual_grading for all to authenticated
  using (
    app_private.has_permission('manage_courses')
    or exists (
      select 1
      from public.attempt_answers aa
      join public.exam_attempts a on a.id = aa.attempt_id
      join public.exams e on e.id = a.exam_id
      where aa.id = attempt_answer_id
        and app_private.has_permission('manage_exam_results')
        and app_private.is_teacher_for_course(e.course_id)
    )
  )
  with check (
    app_private.has_permission('manage_courses')
    or exists (
      select 1
      from public.attempt_answers aa
      join public.exam_attempts a on a.id = aa.attempt_id
      join public.exams e on e.id = a.exam_id
      where aa.id = attempt_answer_id
        and app_private.has_permission('manage_exam_results')
        and app_private.is_teacher_for_course(e.course_id)
    )
  );
create policy "students read published own results; graders read assigned results"
  on public.exam_results for select to authenticated
  using (
    exists (
      select 1
      from public.exam_attempts a
      join public.exams e on e.id = a.exam_id
      where a.id = attempt_id
        and (
          (a.profile_id = app_private.current_profile_id() and is_published)
          or app_private.has_permission('manage_courses')
          or (
            app_private.has_permission('manage_exam_results')
            and app_private.is_teacher_for_course(e.course_id)
          )
        )
    )
  );
create policy "authorized graders manage results"
  on public.exam_results for all to authenticated
  using (
    app_private.has_permission('manage_courses')
    or exists (
      select 1
      from public.exam_attempts a
      join public.exams e on e.id = a.exam_id
      where a.id = attempt_id
        and app_private.has_permission('manage_exam_results')
        and app_private.is_teacher_for_course(e.course_id)
    )
  )
  with check (
    app_private.has_permission('manage_courses')
    or exists (
      select 1
      from public.exam_attempts a
      join public.exams e on e.id = a.exam_id
      where a.id = attempt_id
        and app_private.has_permission('manage_exam_results')
        and app_private.is_teacher_for_course(e.course_id)
    )
  );

-- Public branding and announcements; all edits are server-authorized.
grant select on public.site_settings, public.homepage_sections, public.announcements to anon, authenticated;
create policy "public site settings only"
  on public.site_settings for select to anon, authenticated
  using (is_public);
create policy "site administrators manage settings"
  on public.site_settings for all to authenticated
  using (app_private.has_permission('manage_site_settings'))
  with check (app_private.has_permission('manage_site_settings'));
create policy "published homepage sections are public"
  on public.homepage_sections for select to anon, authenticated
  using (status = 'published');
create policy "site administrators manage homepage sections"
  on public.homepage_sections for all to authenticated
  using (app_private.has_permission('manage_site_branding'))
  with check (app_private.has_permission('manage_site_branding'));
create policy "current published announcements are public"
  on public.announcements for select to anon, authenticated
  using (
    status = 'published'
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at > now())
  );
create policy "site administrators manage announcements"
  on public.announcements for all to authenticated
  using (app_private.has_permission('manage_notifications'))
  with check (app_private.has_permission('manage_notifications'));

-- User notifications and security/audit records.
grant select on public.notifications, public.notification_preferences,
  public.audit_logs, public.session_audit_events
to authenticated;
create policy "users read their notifications"
  on public.notifications for select to authenticated
  using (
    profile_id = app_private.current_profile_id()
    or app_private.has_permission('manage_notifications')
  );
create policy "users update read state of their notifications"
  on public.notifications for update to authenticated
  using (profile_id = app_private.current_profile_id())
  with check (profile_id = app_private.current_profile_id());
create policy "users manage their notification preferences"
  on public.notification_preferences for all to authenticated
  using (profile_id = app_private.current_profile_id())
  with check (profile_id = app_private.current_profile_id());
create policy "authorized administrators read audit logs"
  on public.audit_logs for select to authenticated
  using (app_private.has_permission('view_audit_logs'));
create policy "users and administrators read session audit"
  on public.session_audit_events for select to authenticated
  using (
    profile_id = app_private.current_profile_id()
    or app_private.has_permission('view_audit_logs')
  );
