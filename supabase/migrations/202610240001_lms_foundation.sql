-- Chemistry Tutul LMS foundation.
-- Financial and assessment records are intentionally retained when profiles are deactivated.
create extension if not exists pgcrypto;

create schema if not exists app_private;
revoke all on schema app_private from public, anon;
grant usage on schema app_private to authenticated;

create table public.user_profiles (
  id uuid primary key default gen_random_uuid(),
  clerk_user_id text not null unique,
  email text not null,
  full_name text not null,
  phone text,
  preferred_language text not null default 'bn'
    check (preferred_language in ('bn', 'en')),
  status text not null default 'active'
    check (status in ('active', 'suspended', 'deactivated')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index user_profiles_email_lower_uidx
  on public.user_profiles (lower(email));

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  is_system boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.permissions (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text,
  created_at timestamptz not null default now()
);

create table public.role_permissions (
  role_id uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (role_id, permission_id)
);

create table public.user_roles (
  profile_id uuid not null references public.user_profiles(id) on delete restrict,
  role_id uuid not null references public.roles(id) on delete restrict,
  granted_by uuid references public.user_profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (profile_id, role_id)
);
create index user_roles_role_id_idx on public.user_roles(role_id);

create table public.user_permissions (
  profile_id uuid not null references public.user_profiles(id) on delete restrict,
  permission_id uuid not null references public.permissions(id) on delete restrict,
  effect text not null check (effect in ('allow', 'deny')),
  granted_by uuid references public.user_profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (profile_id, permission_id)
);

create table public.teacher_invitations (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'revoked', 'expired')),
  invited_by uuid not null references public.user_profiles(id) on delete restrict,
  accepted_profile_id uuid references public.user_profiles(id) on delete restrict,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  accepted_at timestamptz
);
create unique index teacher_invitations_email_status_uidx
  on public.teacher_invitations (lower(email), status);

create table public.teacher_profiles (
  profile_id uuid primary key references public.user_profiles(id) on delete restrict,
  display_name text not null,
  biography text,
  avatar_object_key text,
  is_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.courses (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references public.classes(id) on delete restrict,
  title text not null,
  slug text not null unique,
  summary text not null default '',
  description text not null default '',
  learning_outcomes jsonb not null default '[]'::jsonb
    check (jsonb_typeof(learning_outcomes) = 'array'),
  cover_object_key text,
  status text not null default 'draft'
    check (status in ('draft', 'published', 'archived')),
  visibility text not null default 'public'
    check (visibility in ('public', 'private')),
  monthly_fee_poisha integer not null default 0 check (monthly_fee_poisha >= 0),
  one_time_fee_poisha integer not null default 0 check (one_time_fee_poisha >= 0),
  is_featured boolean not null default false,
  created_by uuid not null references public.user_profiles(id) on delete restrict,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index courses_public_catalog_idx
  on public.courses (status, visibility, class_id, is_featured, published_at desc);

create table public.course_categories (
  course_id uuid not null references public.courses(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete restrict,
  created_at timestamptz not null default now(),
  primary key (course_id, category_id)
);
create index course_categories_category_idx on public.course_categories(category_id);

create table public.course_teachers (
  course_id uuid not null references public.courses(id) on delete restrict,
  profile_id uuid not null references public.user_profiles(id) on delete restrict,
  assigned_by uuid not null references public.user_profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  primary key (course_id, profile_id)
);
create index course_teachers_profile_idx on public.course_teachers(profile_id, course_id);

create table public.course_prerequisites (
  course_id uuid not null references public.courses(id) on delete restrict,
  prerequisite_course_id uuid not null references public.courses(id) on delete restrict,
  created_at timestamptz not null default now(),
  primary key (course_id, prerequisite_course_id),
  check (course_id <> prerequisite_course_id)
);

create table public.course_modules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete restrict,
  title text not null,
  description text,
  sort_order integer not null default 0,
  is_public_preview boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (course_id, sort_order)
);

create table public.lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.course_modules(id) on delete restrict,
  title text not null,
  content jsonb not null default '{}'::jsonb,
  sort_order integer not null default 0,
  duration_seconds integer check (duration_seconds is null or duration_seconds >= 0),
  is_public_preview boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (module_id, sort_order)
);

create table public.lesson_resources (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(id) on delete restrict,
  object_key text not null unique,
  display_name text not null,
  mime_type text,
  file_size_bytes bigint check (file_size_bytes is null or file_size_bytes >= 0),
  is_public_preview boolean not null default false,
  created_by uuid not null references public.user_profiles(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.lesson_progress (
  profile_id uuid not null references public.user_profiles(id) on delete restrict,
  lesson_id uuid not null references public.lessons(id) on delete restrict,
  completed_at timestamptz,
  last_position_seconds integer not null default 0 check (last_position_seconds >= 0),
  updated_at timestamptz not null default now(),
  primary key (profile_id, lesson_id)
);

create table public.admission_applications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.user_profiles(id) on delete restrict,
  requested_class_id uuid references public.classes(id) on delete restrict,
  status text not null default 'submitted'
    check (status in ('submitted', 'under_review', 'approved', 'rejected', 'withdrawn')),
  student_note text,
  reviewer_note text,
  reviewed_by uuid references public.user_profiles(id) on delete restrict,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index admission_applications_status_idx
  on public.admission_applications(status, submitted_at desc);

create table public.admissions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.user_profiles(id) on delete restrict,
  application_id uuid unique references public.admission_applications(id) on delete restrict,
  status text not null default 'pending'
    check (status in ('pending', 'active', 'suspended', 'revoked')),
  admitted_by uuid references public.user_profiles(id) on delete restrict,
  admitted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (profile_id)
);
create index admissions_status_idx on public.admissions(status, profile_id);

create table public.enrollments (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.user_profiles(id) on delete restrict,
  course_id uuid not null references public.courses(id) on delete restrict,
  status text not null default 'pending'
    check (status in ('pending', 'active', 'suspended', 'cancelled', 'completed')),
  enrolled_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (profile_id, course_id)
);
create index enrollments_course_status_idx on public.enrollments(course_id, status);
create index enrollments_profile_status_idx on public.enrollments(profile_id, status);

create table public.enrollment_events (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null references public.enrollments(id) on delete restrict,
  old_status text,
  new_status text not null,
  changed_by uuid references public.user_profiles(id) on delete restrict,
  reason text,
  created_at timestamptz not null default now()
);

create table public.fee_policies (
  id uuid primary key default gen_random_uuid(),
  fee_type text not null
    check (fee_type in ('admission', 'course_enrollment', 'monthly_tuition')),
  course_id uuid references public.courses(id) on delete restrict,
  amount_poisha integer not null check (amount_poisha >= 0),
  currency text not null default 'BDT' check (currency = 'BDT'),
  is_active boolean not null default true,
  valid_from timestamptz not null default now(),
  valid_until timestamptz,
  created_by uuid not null references public.user_profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  check (valid_until is null or valid_until > valid_from)
);
create index fee_policies_lookup_idx
  on public.fee_policies(fee_type, course_id, is_active, valid_from desc);

create table public.billing_plans (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete restrict,
  name text not null,
  monthly_amount_poisha integer not null check (monthly_amount_poisha >= 0),
  is_active boolean not null default true,
  created_by uuid not null references public.user_profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (course_id, name)
);

create table public.invoices (
  id uuid primary key default gen_random_uuid(),
  invoice_number text not null unique,
  profile_id uuid not null references public.user_profiles(id) on delete restrict,
  invoice_type text not null
    check (invoice_type in ('admission_fee', 'course_enrollment', 'monthly_tuition', 'adjustment')),
  application_id uuid references public.admission_applications(id) on delete restrict,
  enrollment_id uuid references public.enrollments(id) on delete restrict,
  course_id uuid references public.courses(id) on delete restrict,
  billing_period date,
  amount_due_poisha integer not null check (amount_due_poisha >= 0),
  amount_paid_poisha integer not null default 0 check (amount_paid_poisha >= 0),
  currency text not null default 'BDT' check (currency = 'BDT'),
  status text not null default 'open'
    check (status in ('draft', 'open', 'partially_paid', 'paid', 'overdue', 'void')),
  issued_at timestamptz not null default now(),
  due_at timestamptz,
  paid_at timestamptz,
  created_by uuid references public.user_profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (amount_paid_poisha <= amount_due_poisha),
  check (
    (invoice_type = 'admission_fee' and application_id is not null)
    or invoice_type <> 'admission_fee'
  ),
  check (
    (invoice_type = 'course_enrollment' and enrollment_id is not null)
    or invoice_type <> 'course_enrollment'
  ),
  check (
    (invoice_type = 'monthly_tuition' and enrollment_id is not null and billing_period is not null)
    or invoice_type <> 'monthly_tuition'
  )
);
create index invoices_profile_status_due_idx
  on public.invoices(profile_id, status, due_at);
create unique index invoices_monthly_period_uidx
  on public.invoices(profile_id, enrollment_id, billing_period)
  where invoice_type = 'monthly_tuition';

create table public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete restrict,
  description text not null,
  quantity integer not null default 1 check (quantity > 0),
  unit_amount_poisha integer not null check (unit_amount_poisha >= 0),
  total_amount_poisha integer not null check (total_amount_poisha >= 0),
  created_at timestamptz not null default now(),
  check (total_amount_poisha = quantity * unit_amount_poisha)
);
create index invoice_items_invoice_idx on public.invoice_items(invoice_id);

create table public.payment_attempts (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete restrict,
  provider text not null default 'uddoktapay' check (provider = 'uddoktapay'),
  external_invoice_id text,
  provider_transaction_id text,
  amount_poisha integer not null check (amount_poisha > 0),
  status text not null default 'created'
    check (status in ('created', 'pending', 'completed', 'failed', 'cancelled', 'refunded')),
  checkout_url text,
  verified_at timestamptz,
  failure_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, external_invoice_id)
);
create index payment_attempts_invoice_idx
  on public.payment_attempts(invoice_id, created_at desc);
create index payment_attempts_status_idx
  on public.payment_attempts(status, created_at);

create table public.payment_events (
  id uuid primary key default gen_random_uuid(),
  provider text not null default 'uddoktapay' check (provider = 'uddoktapay'),
  provider_event_id text not null,
  payment_attempt_id uuid references public.payment_attempts(id) on delete restrict,
  event_type text not null,
  verified boolean not null default false,
  payload_digest text,
  received_at timestamptz not null default now(),
  processed_at timestamptz,
  unique (provider, provider_event_id)
);
create index payment_events_attempt_idx on public.payment_events(payment_attempt_id, received_at);

create table public.payment_reconciliation (
  id uuid primary key default gen_random_uuid(),
  payment_attempt_id uuid not null references public.payment_attempts(id) on delete restrict,
  result text not null check (result in ('matched', 'mismatch', 'missing', 'reviewed')),
  expected_amount_poisha integer not null check (expected_amount_poisha >= 0),
  provider_amount_poisha integer check (provider_amount_poisha is null or provider_amount_poisha >= 0),
  reviewed_by uuid references public.user_profiles(id) on delete restrict,
  note text,
  created_at timestamptz not null default now()
);

create table public.refunds (
  id uuid primary key default gen_random_uuid(),
  payment_attempt_id uuid not null references public.payment_attempts(id) on delete restrict,
  amount_poisha integer not null check (amount_poisha > 0),
  status text not null default 'requested'
    check (status in ('requested', 'approved', 'rejected', 'processing', 'completed', 'failed')),
  reason text not null,
  requested_by uuid not null references public.user_profiles(id) on delete restrict,
  reviewed_by uuid references public.user_profiles(id) on delete restrict,
  provider_refund_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.manual_payment_adjustments (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete restrict,
  amount_poisha integer not null,
  reason text not null,
  created_by uuid not null references public.user_profiles(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.live_sessions (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete restrict,
  title text not null,
  description text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  join_url text,
  status text not null default 'scheduled'
    check (status in ('scheduled', 'live', 'completed', 'cancelled')),
  created_by uuid not null references public.user_profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at > starts_at)
);
create index live_sessions_course_start_idx on public.live_sessions(course_id, starts_at);

create table public.question_bank (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references public.courses(id) on delete restrict,
  created_by uuid not null references public.user_profiles(id) on delete restrict,
  question_type text not null
    check (question_type in ('multiple_choice', 'true_false', 'short_answer', 'long_answer')),
  prompt jsonb not null,
  explanation jsonb,
  difficulty text check (difficulty is null or difficulty in ('easy', 'medium', 'hard')),
  status text not null default 'draft' check (status in ('draft', 'active', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index question_bank_course_status_idx on public.question_bank(course_id, status, question_type);

create table public.question_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.question_bank(id) on delete restrict,
  option_content jsonb not null,
  sort_order integer not null default 0,
  is_correct boolean not null default false,
  created_at timestamptz not null default now(),
  unique (question_id, sort_order)
);

create table public.exams (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete restrict,
  title text not null,
  description text,
  status text not null default 'draft'
    check (status in ('draft', 'scheduled', 'published', 'closed', 'archived')),
  starts_at timestamptz,
  ends_at timestamptz,
  duration_minutes integer check (duration_minutes is null or duration_minutes > 0),
  attempt_limit integer not null default 1 check (attempt_limit > 0),
  shuffle_questions boolean not null default false,
  shuffle_options boolean not null default false,
  show_results text not null default 'after_review'
    check (show_results in ('immediately', 'after_review', 'manual')),
  created_by uuid not null references public.user_profiles(id) on delete restrict,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at is null or starts_at is null or ends_at > starts_at)
);
create index exams_course_status_schedule_idx on public.exams(course_id, status, starts_at);

create table public.exam_questions (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete restrict,
  question_id uuid references public.question_bank(id) on delete set null,
  prompt_snapshot jsonb not null,
  options_snapshot jsonb not null default '[]'::jsonb,
  points integer not null check (points > 0),
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (exam_id, sort_order)
);

create table public.exam_question_keys (
  exam_question_id uuid primary key references public.exam_questions(id) on delete restrict,
  answer_key jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.exam_attempts (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete restrict,
  profile_id uuid not null references public.user_profiles(id) on delete restrict,
  attempt_number integer not null check (attempt_number > 0),
  status text not null default 'in_progress'
    check (status in ('in_progress', 'submitted', 'graded', 'expired', 'void')),
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  graded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (exam_id, profile_id, attempt_number)
);
create index exam_attempts_profile_idx on public.exam_attempts(profile_id, started_at desc);
create index exam_attempts_exam_status_idx on public.exam_attempts(exam_id, status);

create table public.attempt_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.exam_attempts(id) on delete restrict,
  exam_question_id uuid not null references public.exam_questions(id) on delete restrict,
  answer_payload jsonb not null default '{}'::jsonb,
  answered_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (attempt_id, exam_question_id)
);

create table public.manual_grading (
  id uuid primary key default gen_random_uuid(),
  attempt_answer_id uuid not null unique references public.attempt_answers(id) on delete restrict,
  points_awarded integer not null check (points_awarded >= 0),
  feedback text,
  graded_by uuid not null references public.user_profiles(id) on delete restrict,
  graded_at timestamptz not null default now()
);

create table public.exam_results (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null unique references public.exam_attempts(id) on delete restrict,
  earned_points integer not null check (earned_points >= 0),
  total_points integer not null check (total_points > 0),
  percentage numeric(5,2) not null check (percentage >= 0 and percentage <= 100),
  is_published boolean not null default false,
  published_at timestamptz,
  feedback text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (earned_points <= total_points)
);

create table public.site_settings (
  setting_key text primary key,
  value jsonb not null,
  is_public boolean not null default false,
  updated_by uuid references public.user_profiles(id) on delete restrict,
  updated_at timestamptz not null default now()
);

create table public.homepage_sections (
  id uuid primary key default gen_random_uuid(),
  section_key text not null unique,
  content jsonb not null default '{}'::jsonb,
  sort_order integer not null default 0,
  status text not null default 'draft' check (status in ('draft', 'published')),
  updated_by uuid references public.user_profiles(id) on delete restrict,
  updated_at timestamptz not null default now()
);

create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body jsonb not null,
  status text not null default 'draft' check (status in ('draft', 'scheduled', 'published', 'archived')),
  starts_at timestamptz,
  ends_at timestamptz,
  created_by uuid not null references public.user_profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at is null or starts_at is null or ends_at > starts_at)
);
create index announcements_public_schedule_idx
  on public.announcements(status, starts_at, ends_at);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.user_profiles(id) on delete restrict,
  notification_type text not null,
  title text not null,
  body text not null,
  href text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_profile_created_idx
  on public.notifications(profile_id, created_at desc);

create table public.notification_preferences (
  profile_id uuid not null references public.user_profiles(id) on delete restrict,
  notification_type text not null,
  email_enabled boolean not null default true,
  in_app_enabled boolean not null default true,
  updated_at timestamptz not null default now(),
  primary key (profile_id, notification_type)
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_profile_id uuid references public.user_profiles(id) on delete restrict,
  action text not null,
  entity_type text not null,
  entity_id text,
  before_state jsonb,
  after_state jsonb,
  request_id text,
  created_at timestamptz not null default now()
);
create index audit_logs_created_idx on public.audit_logs(created_at desc);
create index audit_logs_entity_idx on public.audit_logs(entity_type, entity_id, created_at desc);

create table public.session_audit_events (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.user_profiles(id) on delete restrict,
  clerk_session_id text,
  event_type text not null check (event_type in ('created', 'revoked', 'expired', 'ended')),
  occurred_at timestamptz not null default now()
);
create index session_audit_profile_idx on public.session_audit_events(profile_id, occurred_at desc);

create or replace function app_private.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public, auth, pg_temp
set row_security = off
as $$
  select p.id
  from public.user_profiles p
  where p.clerk_user_id = (select auth.jwt() ->> 'sub')
    and p.status = 'active'
  limit 1
$$;

create or replace function app_private.has_role(required_role text)
returns boolean
language sql
stable
security definer
set search_path = public, auth, app_private, pg_temp
set row_security = off
as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.profile_id = app_private.current_profile_id()
      and r.slug = required_role
  )
$$;

create or replace function app_private.has_permission(required_permission text)
returns boolean
language sql
stable
security definer
set search_path = public, auth, app_private, pg_temp
set row_security = off
as $$
  select coalesce(
    (
      select up.effect = 'allow'
      from public.user_permissions up
      join public.permissions p on p.id = up.permission_id
      where up.profile_id = app_private.current_profile_id()
        and p.slug = required_permission
      limit 1
    ),
    exists (
      select 1
      from public.user_roles ur
      join public.role_permissions rp on rp.role_id = ur.role_id
      join public.permissions p on p.id = rp.permission_id
      where ur.profile_id = app_private.current_profile_id()
        and p.slug = required_permission
    )
  )
$$;

create or replace function app_private.is_teacher_for_course(target_course_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth, app_private, pg_temp
set row_security = off
as $$
  select exists (
    select 1
    from public.course_teachers ct
    where ct.course_id = target_course_id
      and ct.profile_id = app_private.current_profile_id()
  )
$$;

create or replace function app_private.is_public_teacher(target_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth, app_private, pg_temp
set row_security = off
as $$
  select exists (
    select 1
    from public.teacher_profiles tp
    join public.user_roles ur on ur.profile_id = tp.profile_id
    join public.roles r on r.id = ur.role_id
    join public.user_profiles up on up.id = tp.profile_id
    where tp.profile_id = target_profile_id
      and tp.is_public
      and r.slug = 'teacher'
      and up.status = 'active'
  )
$$;

create or replace function app_private.has_active_course_access(target_course_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth, app_private, pg_temp
set row_security = off
as $$
  select app_private.has_role('admin')
    or app_private.is_teacher_for_course(target_course_id)
    or exists (
      select 1
      from public.enrollments e
      join public.admissions a on a.profile_id = e.profile_id
      where e.profile_id = app_private.current_profile_id()
        and e.course_id = target_course_id
        and e.status = 'active'
        and a.status = 'active'
    )
$$;

grant execute on function app_private.current_profile_id() to authenticated;
grant execute on function app_private.has_role(text) to authenticated;
grant execute on function app_private.has_permission(text) to authenticated;
grant execute on function app_private.is_teacher_for_course(uuid) to authenticated;
grant execute on function app_private.is_public_teacher(uuid) to anon, authenticated;
grant execute on function app_private.has_active_course_access(uuid) to authenticated;

insert into public.roles (slug, name, is_system)
values
  ('admin', 'Administrator', true),
  ('teacher', 'Teacher', true),
  ('student', 'Student', true)
on conflict (slug) do nothing;

insert into public.permissions (slug, name)
values
  ('manage_users', 'Manage users'),
  ('manage_teachers', 'Manage teachers'),
  ('manage_roles', 'Manage roles'),
  ('manage_courses', 'Manage courses'),
  ('manage_course_content', 'Manage course content'),
  ('manage_course_pricing', 'Manage course pricing'),
  ('manage_categories', 'Manage categories'),
  ('manage_admissions', 'Manage admissions'),
  ('manage_billing', 'Manage billing'),
  ('manage_refunds', 'Manage refunds'),
  ('manage_exams', 'Manage exams'),
  ('manage_exam_results', 'Manage exam results'),
  ('manage_site_branding', 'Manage site branding'),
  ('manage_site_settings', 'Manage site settings'),
  ('manage_notifications', 'Manage notifications'),
  ('view_reports', 'View reports'),
  ('view_audit_logs', 'View audit logs')
on conflict (slug) do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
cross join public.permissions p
where r.slug = 'admin'
on conflict do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p
  on p.slug in ('manage_course_content', 'manage_exams', 'manage_exam_results')
where r.slug = 'teacher'
on conflict do nothing;

insert into public.site_settings (setting_key, value, is_public)
values
  ('brand', '{"name":"Chemistry Tutul","preferredLanguage":"bn"}'::jsonb, true),
  ('homepage', '{"tagline":"Learn with clarity. Grow with confidence.","introduction":"Structured learning for students and families across Bangladesh."}'::jsonb, true)
on conflict (setting_key) do nothing;
