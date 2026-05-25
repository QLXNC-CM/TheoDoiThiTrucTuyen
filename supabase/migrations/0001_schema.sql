-- FILE: supabase/migrations/0001_schema.sql

begin;

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.units (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text not null check (type in ('department', 'team', 'group', 'other')),
  parent_id uuid null references public.units(id) on delete restrict,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint units_parent_not_self check (parent_id is null or parent_id <> id)
);

create table if not exists public.participant_groups (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint participant_groups_code_not_blank check (btrim(code) <> '')
);

create table if not exists public.roles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text null,
  constraint roles_code_not_blank check (btrim(code) <> '')
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  citizen_id_hash text not null unique,
  citizen_id_last4 text not null,
  citizen_id_encrypted text null,
  full_name text not null,
  phone text null,
  auth_email text null unique,
  primary_unit_id uuid null references public.units(id) on delete set null,
  position_title text null,
  participant_group_id uuid null references public.participant_groups(id) on delete set null,
  force_password_change boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_citizen_hash_not_blank check (btrim(citizen_id_hash) <> ''),
  constraint profiles_citizen_last4_format check (citizen_id_last4 ~ '^[0-9]{4}$'),
  constraint profiles_full_name_not_blank check (btrim(full_name) <> '')
);

create table if not exists public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_id uuid not null references public.roles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, role_id)
);

create table if not exists public.app_settings (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  value jsonb not null default '{}'::jsonb,
  description text null,
  is_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint app_settings_key_not_blank check (btrim(key) <> '')
);

create table if not exists public.contests (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text not null unique,
  description text null,
  status text not null default 'draft' check (status in ('draft', 'active', 'closed', 'archived')),
  start_at timestamptz not null default now(),
  deadline timestamptz not null,
  allow_edit_while_pending boolean not null default true,
  allow_resubmit_after_reject boolean not null default true,
  resubmit_mode text not null default 'restart_from_step_1',
  allow_late_submission boolean not null default false,
  keep_old_files boolean not null default false,
  max_upload_size_kb integer not null default 1024,
  allow_pdf_upload boolean not null default false,
  created_by uuid null references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint contests_title_not_blank check (btrim(title) <> ''),
  constraint contests_slug_not_blank check (btrim(slug) <> ''),
  constraint contests_deadline_after_start check (deadline > start_at),
  constraint contests_resubmit_mode_check check (resubmit_mode in ('restart_from_step_1', 'restart_from_rejected_step')),
  constraint contests_max_upload_size_kb_positive check (max_upload_size_kb > 0)
);

create table if not exists public.contest_participants (
  id uuid primary key default gen_random_uuid(),
  contest_id uuid not null references public.contests(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  participant_group_id uuid null references public.participant_groups(id) on delete set null,
  assigned_unit_id uuid null references public.units(id) on delete set null,
  is_required boolean not null default true,
  assigned_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (contest_id, user_id)
);

create table if not exists public.user_scopes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  scope_type text not null check (scope_type in ('view', 'approve', 'export', 'manage')),
  scope_kind text not null constraint user_scopes_scope_kind_check check (scope_kind in ('all', 'unit', 'user')),
  unit_id uuid null references public.units(id) on delete cascade,
  contest_id uuid null references public.contests(id) on delete cascade,
  target_user_id uuid null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint user_scopes_scope_kind_target_check check (
    (scope_kind = 'all' and unit_id is null and target_user_id is null)
    or (scope_kind = 'unit' and unit_id is not null and target_user_id is null)
    or (scope_kind = 'user' and target_user_id is not null and unit_id is null)
  )
);

alter table public.contests
  add column if not exists allow_edit_while_pending boolean,
  add column if not exists allow_resubmit_after_reject boolean,
  add column if not exists resubmit_mode text,
  add column if not exists max_upload_size_kb integer,
  add column if not exists allow_pdf_upload boolean;

update public.contests
set allow_edit_while_pending = coalesce(allow_edit_while_pending, true),
    allow_resubmit_after_reject = coalesce(allow_resubmit_after_reject, true),
    resubmit_mode = case
      when resubmit_mode in ('restart_from_step_1', 'restart_from_rejected_step') then resubmit_mode
      else 'restart_from_step_1'
    end,
    keep_old_files = coalesce(keep_old_files, false),
    max_upload_size_kb = case
      when max_upload_size_kb > 0 then max_upload_size_kb
      else 1024
    end,
    allow_pdf_upload = coalesce(allow_pdf_upload, false);

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'contests'
      and column_name = 'allow_resubmission'
  ) then
    execute '
      update public.contests
      set allow_edit_while_pending = false,
          allow_resubmit_after_reject = false
      where allow_resubmission = false
    ';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'contests'
      and column_name = 'max_file_size_kb'
  ) then
    execute '
      update public.contests
      set max_upload_size_kb = max_file_size_kb
      where max_file_size_kb is not null
        and max_upload_size_kb = 1024
    ';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'contests'
      and column_name = 'allow_pdf_evidence'
  ) then
    execute '
      update public.contests
      set allow_pdf_upload = allow_pdf_evidence
      where allow_pdf_evidence is not null
        and allow_pdf_upload = false
    ';
  end if;
end;
$$;

alter table public.contests
  drop column if exists allow_resubmission,
  drop column if exists max_file_size_kb,
  drop column if exists allow_pdf_evidence;

alter table public.contests
  alter column allow_edit_while_pending set default true,
  alter column allow_edit_while_pending set not null,
  alter column allow_resubmit_after_reject set default true,
  alter column allow_resubmit_after_reject set not null,
  alter column resubmit_mode set default 'restart_from_step_1',
  alter column resubmit_mode set not null,
  alter column keep_old_files set default false,
  alter column keep_old_files set not null,
  alter column max_upload_size_kb set default 1024,
  alter column max_upload_size_kb set not null,
  alter column allow_pdf_upload set default false,
  alter column allow_pdf_upload set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'contests_resubmit_mode_check'
      and conrelid = 'public.contests'::regclass
  ) then
    alter table public.contests
      add constraint contests_resubmit_mode_check
      check (resubmit_mode in ('restart_from_step_1', 'restart_from_rejected_step'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'contests_max_upload_size_kb_positive'
      and conrelid = 'public.contests'::regclass
  ) then
    alter table public.contests
      add constraint contests_max_upload_size_kb_positive
      check (max_upload_size_kb > 0);
  end if;
end;
$$;

alter table public.user_scopes
  add column if not exists scope_kind text;

update public.user_scopes
set scope_kind = case
  when target_user_id is not null then 'user'
  when unit_id is not null then 'unit'
  else 'all'
end
where scope_kind is null
   or scope_kind not in ('all', 'unit', 'user')
   or (scope_kind = 'all' and (unit_id is not null or target_user_id is not null))
   or (scope_kind = 'unit' and (unit_id is null or target_user_id is not null))
   or (scope_kind = 'user' and (target_user_id is null or unit_id is not null));

update public.user_scopes
set unit_id = null
where scope_kind = 'user'
  and target_user_id is not null;

update public.user_scopes
set target_user_id = null
where scope_kind = 'unit'
  and unit_id is not null;

update public.user_scopes
set unit_id = null,
    target_user_id = null
where scope_kind = 'all';

alter table public.user_scopes
  alter column scope_kind set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'user_scopes_scope_kind_check'
      and conrelid = 'public.user_scopes'::regclass
  ) then
    alter table public.user_scopes
      add constraint user_scopes_scope_kind_check
      check (scope_kind in ('all', 'unit', 'user'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'user_scopes_scope_kind_target_check'
      and conrelid = 'public.user_scopes'::regclass
  ) then
    alter table public.user_scopes
      add constraint user_scopes_scope_kind_target_check
      check (
        (scope_kind = 'all' and unit_id is null and target_user_id is null)
        or (scope_kind = 'unit' and unit_id is not null and target_user_id is null)
        or (scope_kind = 'user' and target_user_id is not null and unit_id is null)
      );
  end if;
end;
$$;

create table if not exists public.approval_flows (
  id uuid primary key default gen_random_uuid(),
  contest_id uuid not null references public.contests(id) on delete cascade,
  version integer not null,
  name text not null,
  is_active boolean not null default false,
  activated_at timestamptz null,
  created_by uuid null references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (contest_id, version),
  constraint approval_flows_version_positive check (version > 0),
  constraint approval_flows_name_not_blank check (btrim(name) <> '')
);

create table if not exists public.approval_steps (
  id uuid primary key default gen_random_uuid(),
  flow_id uuid not null references public.approval_flows(id) on delete cascade,
  step_order integer not null,
  step_name text not null,
  scope_type text not null check (scope_type in ('team', 'department', 'all', 'custom')),
  approval_rule text not null check (approval_rule in ('ANY_ONE', 'ALL_REQUIRED')),
  can_reject boolean not null default true,
  require_note_on_approve boolean not null default false,
  require_reason_on_reject boolean not null default true,
  created_at timestamptz not null default now(),
  unique (flow_id, step_order),
  constraint approval_steps_step_order_positive check (step_order > 0),
  constraint approval_steps_step_name_not_blank check (btrim(step_name) <> '')
);

create table if not exists public.approval_step_roles (
  id uuid primary key default gen_random_uuid(),
  step_id uuid not null references public.approval_steps(id) on delete cascade,
  role_id uuid not null references public.roles(id) on delete cascade,
  unique (step_id, role_id)
);

create table if not exists public.approval_step_assignees (
  id uuid primary key default gen_random_uuid(),
  step_id uuid not null references public.approval_steps(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  is_required boolean not null default true,
  created_at timestamptz not null default now(),
  unique (step_id, user_id)
);

create table if not exists public.submissions (
  id uuid primary key default gen_random_uuid(),
  contest_id uuid not null references public.contests(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  current_status text not null check (current_status in ('SUBMITTED', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'RESUBMITTED', 'CANCELLED')),
  current_step_order integer null,
  flow_id uuid null references public.approval_flows(id) on delete restrict,
  flow_version integer null,
  submitted_at timestamptz null,
  last_resubmitted_at timestamptz null,
  final_approved_at timestamptz null,
  final_rejected_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (contest_id, user_id),
  constraint submissions_current_step_order_positive check (current_step_order is null or current_step_order > 0),
  constraint submissions_flow_snapshot_consistency check (
    (flow_id is null and flow_version is null) or
    (flow_id is not null and flow_version is not null)
  )
);

create table if not exists public.submission_files (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.submissions(id) on delete cascade,
  storage_path text not null unique,
  file_type text not null check (file_type in ('jpg', 'jpeg', 'png', 'webp', 'pdf')),
  file_size_kb integer not null,
  uploaded_by uuid not null references public.profiles(id) on delete restrict,
  uploaded_at timestamptz not null default now(),
  version_number integer not null,
  is_current boolean not null default true,
  unique (submission_id, version_number),
  constraint submission_files_storage_path_not_blank check (btrim(storage_path) <> ''),
  constraint submission_files_file_size_positive check (file_size_kb > 0),
  constraint submission_files_version_positive check (version_number > 0)
);

create table if not exists public.submission_approval_steps (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.submissions(id) on delete cascade,
  step_id uuid not null references public.approval_steps(id) on delete restrict,
  step_order integer not null,
  step_name text not null,
  approval_rule text not null check (approval_rule in ('ANY_ONE', 'ALL_REQUIRED')),
  status text not null check (status in ('PENDING', 'APPROVED', 'REJECTED', 'SKIPPED')),
  opened_at timestamptz null,
  completed_at timestamptz null,
  created_at timestamptz not null default now(),
  unique (submission_id, step_order),
  constraint submission_approval_steps_order_positive check (step_order > 0)
);

create table if not exists public.submission_step_approvers (
  id uuid primary key default gen_random_uuid(),
  submission_approval_step_id uuid not null references public.submission_approval_steps(id) on delete cascade,
  approver_user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null check (status in ('PENDING', 'APPROVED', 'REJECTED')),
  approval_action_id uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (submission_approval_step_id, approver_user_id)
);

create table if not exists public.approval_actions (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.submissions(id) on delete cascade,
  contest_id uuid not null references public.contests(id) on delete cascade,
  flow_id uuid null references public.approval_flows(id) on delete restrict,
  flow_version integer null,
  step_order integer not null,
  step_name text not null,
  action text not null check (action in ('APPROVED', 'REJECTED')),
  actor_user_id uuid not null references public.profiles(id) on delete restrict,
  actor_role_code text null,
  note text null,
  reject_reason text null,
  created_at timestamptz not null default now(),
  constraint approval_actions_step_order_positive check (step_order > 0),
  constraint approval_actions_reject_reason_required check (action <> 'REJECTED' or btrim(coalesce(reject_reason, '')) <> '')
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'submission_step_approvers_action_fk'
      and conrelid = 'public.submission_step_approvers'::regclass
  ) then
    alter table public.submission_step_approvers
      add constraint submission_step_approvers_action_fk
      foreign key (approval_action_id) references public.approval_actions(id) on delete set null;
  end if;
end;
$$;

create table if not exists public.submission_events (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.submissions(id) on delete cascade,
  event_type text not null,
  from_status text null,
  to_status text null,
  actor_user_id uuid null references public.profiles(id) on delete set null,
  note text null,
  metadata jsonb null,
  created_at timestamptz not null default now(),
  constraint submission_events_event_type_not_blank check (btrim(event_type) <> '')
);

create table if not exists public.rejection_reason_templates (
  id uuid primary key default gen_random_uuid(),
  reason_text text not null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  constraint rejection_reason_templates_text_not_blank check (btrim(reason_text) <> '')
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid null references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid null,
  old_value jsonb null,
  new_value jsonb null,
  ip_address text null,
  user_agent text null,
  created_at timestamptz not null default now(),
  constraint audit_logs_action_not_blank check (btrim(action) <> ''),
  constraint audit_logs_entity_type_not_blank check (btrim(entity_type) <> '')
);

create table if not exists public.report_exports (
  id uuid primary key default gen_random_uuid(),
  contest_id uuid not null references public.contests(id) on delete cascade,
  report_type text not null check (report_type in ('summary', 'detail', 'approver_stats')),
  file_name text null,
  exported_by uuid not null references public.profiles(id) on delete restrict,
  exported_at timestamptz not null default now()
);

create unique index if not exists approval_flows_one_active_per_contest_idx
  on public.approval_flows (contest_id)
  where is_active;

create unique index if not exists submission_files_one_current_idx
  on public.submission_files (submission_id)
  where is_current;

create index if not exists profiles_primary_unit_id_idx on public.profiles (primary_unit_id);
create index if not exists profiles_participant_group_id_idx on public.profiles (participant_group_id);
create index if not exists profiles_citizen_id_hash_idx on public.profiles (citizen_id_hash);
create index if not exists user_roles_user_id_idx on public.user_roles (user_id);
create index if not exists user_roles_role_id_idx on public.user_roles (role_id);
create index if not exists units_parent_id_idx on public.units (parent_id);
create index if not exists units_type_idx on public.units (type);
create index if not exists user_scopes_user_id_idx on public.user_scopes (user_id);
create index if not exists user_scopes_scope_type_idx on public.user_scopes (scope_type);
create index if not exists user_scopes_scope_kind_idx on public.user_scopes (scope_kind);
create index if not exists user_scopes_unit_id_idx on public.user_scopes (unit_id);
create index if not exists user_scopes_contest_id_idx on public.user_scopes (contest_id);
create index if not exists user_scopes_target_user_id_idx on public.user_scopes (target_user_id);
create index if not exists contests_status_deadline_idx on public.contests (status, deadline);
create index if not exists contest_participants_contest_id_idx on public.contest_participants (contest_id);
create index if not exists contest_participants_user_id_idx on public.contest_participants (user_id);
create index if not exists contest_participants_assigned_unit_id_idx on public.contest_participants (assigned_unit_id);
create index if not exists approval_flows_contest_id_idx on public.approval_flows (contest_id);
create index if not exists approval_steps_flow_id_idx on public.approval_steps (flow_id);
create index if not exists approval_step_roles_step_id_idx on public.approval_step_roles (step_id);
create index if not exists approval_step_roles_role_id_idx on public.approval_step_roles (role_id);
create index if not exists approval_step_assignees_step_id_idx on public.approval_step_assignees (step_id);
create index if not exists approval_step_assignees_user_id_idx on public.approval_step_assignees (user_id);
create index if not exists submissions_contest_id_idx on public.submissions (contest_id);
create index if not exists submissions_user_id_idx on public.submissions (user_id);
create index if not exists submissions_current_status_idx on public.submissions (current_status);
create index if not exists submissions_current_step_order_idx on public.submissions (current_step_order);
create index if not exists submissions_created_at_idx on public.submissions (created_at);
create index if not exists submission_files_submission_id_idx on public.submission_files (submission_id);
create index if not exists submission_files_uploaded_by_idx on public.submission_files (uploaded_by);
create index if not exists submission_files_uploaded_at_idx on public.submission_files (uploaded_at);
create index if not exists submission_approval_steps_submission_id_idx on public.submission_approval_steps (submission_id);
create index if not exists submission_approval_steps_step_id_idx on public.submission_approval_steps (step_id);
create index if not exists submission_approval_steps_status_idx on public.submission_approval_steps (status);
create index if not exists submission_step_approvers_step_id_idx on public.submission_step_approvers (submission_approval_step_id);
create index if not exists submission_step_approvers_approver_user_id_idx on public.submission_step_approvers (approver_user_id);
create index if not exists approval_actions_submission_id_idx on public.approval_actions (submission_id);
create index if not exists approval_actions_contest_id_idx on public.approval_actions (contest_id);
create index if not exists approval_actions_actor_user_id_idx on public.approval_actions (actor_user_id);
create index if not exists approval_actions_created_at_idx on public.approval_actions (created_at);
create index if not exists submission_events_submission_id_idx on public.submission_events (submission_id);
create index if not exists submission_events_created_at_idx on public.submission_events (created_at);
create index if not exists audit_logs_actor_user_id_idx on public.audit_logs (actor_user_id);
create index if not exists audit_logs_entity_type_entity_id_idx on public.audit_logs (entity_type, entity_id);
create index if not exists audit_logs_created_at_idx on public.audit_logs (created_at);
create index if not exists report_exports_contest_id_idx on public.report_exports (contest_id);
create index if not exists report_exports_exported_by_idx on public.report_exports (exported_by);

drop trigger if exists units_set_updated_at on public.units;
create trigger units_set_updated_at
before update on public.units
for each row execute function public.set_updated_at();

drop trigger if exists participant_groups_set_updated_at on public.participant_groups;
create trigger participant_groups_set_updated_at
before update on public.participant_groups
for each row execute function public.set_updated_at();

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists app_settings_set_updated_at on public.app_settings;
create trigger app_settings_set_updated_at
before update on public.app_settings
for each row execute function public.set_updated_at();

drop trigger if exists contests_set_updated_at on public.contests;
create trigger contests_set_updated_at
before update on public.contests
for each row execute function public.set_updated_at();

drop trigger if exists approval_flows_set_updated_at on public.approval_flows;
create trigger approval_flows_set_updated_at
before update on public.approval_flows
for each row execute function public.set_updated_at();

drop trigger if exists submissions_set_updated_at on public.submissions;
create trigger submissions_set_updated_at
before update on public.submissions
for each row execute function public.set_updated_at();

drop trigger if exists submission_step_approvers_set_updated_at on public.submission_step_approvers;
create trigger submission_step_approvers_set_updated_at
before update on public.submission_step_approvers
for each row execute function public.set_updated_at();

comment on table public.profiles is 'Application profile keyed by auth.users. CCCD plaintext is not stored by default.';
comment on column public.profiles.citizen_id_hash is 'Unique hash of normalized CCCD for lookup/provisioning.';
comment on column public.profiles.citizen_id_last4 is 'Last four digits for masked display only.';
comment on column public.profiles.primary_unit_id is 'Direct smallest unit of the user; parent units are inferred through units.parent_id.';
comment on table public.approval_flows is 'Versioned approval flow per contest. Existing submissions snapshot flow_id and flow_version.';
comment on table public.submission_approval_steps is 'Per-submission snapshot of approval steps to protect running submissions from flow changes.';
comment on table public.submission_step_approvers is 'Per-submission snapshot of concrete approvers, required for ALL_REQUIRED steps.';
comment on table public.submission_files is 'Evidence file metadata. Only one row per submission may have is_current = true.';
comment on table public.audit_logs is 'System audit log for sensitive actions.';

commit;
