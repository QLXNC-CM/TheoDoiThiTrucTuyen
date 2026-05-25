-- FILE: supabase/migrations/0002_rls.sql

begin;

alter table public.profiles enable row level security;
alter table public.roles enable row level security;
alter table public.user_roles enable row level security;
alter table public.units enable row level security;
alter table public.user_scopes enable row level security;
alter table public.participant_groups enable row level security;
alter table public.app_settings enable row level security;
alter table public.contests enable row level security;
alter table public.contest_participants enable row level security;
alter table public.approval_flows enable row level security;
alter table public.approval_steps enable row level security;
alter table public.approval_step_roles enable row level security;
alter table public.approval_step_assignees enable row level security;
alter table public.submissions enable row level security;
alter table public.submission_files enable row level security;
alter table public.submission_approval_steps enable row level security;
alter table public.submission_step_approvers enable row level security;
alter table public.approval_actions enable row level security;
alter table public.submission_events enable row level security;
alter table public.audit_logs enable row level security;
alter table public.report_exports enable row level security;

drop policy if exists profiles_select_scoped on public.profiles;
drop policy if exists profiles_admin_insert on public.profiles;
drop policy if exists profiles_admin_update on public.profiles;
drop policy if exists roles_select_authenticated on public.roles;
drop policy if exists roles_super_admin_all on public.roles;
drop policy if exists user_roles_select_own_or_admin on public.user_roles;
drop policy if exists user_roles_super_admin_all on public.user_roles;
drop policy if exists units_select_authenticated on public.units;
drop policy if exists units_manage on public.units;
drop policy if exists user_scopes_select_own_or_admin on public.user_scopes;
drop policy if exists user_scopes_super_admin_all on public.user_scopes;
drop policy if exists participant_groups_select_authenticated on public.participant_groups;
drop policy if exists participant_groups_manage on public.participant_groups;
drop policy if exists app_settings_select_authenticated on public.app_settings;
drop policy if exists app_settings_manage on public.app_settings;
drop policy if exists contests_select_authenticated on public.contests;
drop policy if exists contests_manage on public.contests;
drop policy if exists contest_participants_select_scoped on public.contest_participants;
drop policy if exists contest_participants_manage on public.contest_participants;
drop policy if exists approval_flows_select_authenticated on public.approval_flows;
drop policy if exists approval_steps_select_authenticated on public.approval_steps;
drop policy if exists approval_step_roles_select_authenticated on public.approval_step_roles;
drop policy if exists approval_step_assignees_select_authenticated on public.approval_step_assignees;
drop policy if exists approval_flows_manage on public.approval_flows;
drop policy if exists approval_steps_manage on public.approval_steps;
drop policy if exists approval_step_roles_manage on public.approval_step_roles;
drop policy if exists approval_step_assignees_manage on public.approval_step_assignees;
drop policy if exists submissions_select_scoped on public.submissions;
drop policy if exists submissions_super_admin_all on public.submissions;
drop policy if exists submission_files_select_scoped on public.submission_files;
drop policy if exists submission_files_super_admin_all on public.submission_files;
drop policy if exists submission_approval_steps_select_scoped on public.submission_approval_steps;
drop policy if exists submission_approval_steps_super_admin_all on public.submission_approval_steps;
drop policy if exists submission_step_approvers_select_scoped on public.submission_step_approvers;
drop policy if exists submission_step_approvers_super_admin_all on public.submission_step_approvers;
drop policy if exists approval_actions_select_scoped on public.approval_actions;
drop policy if exists approval_actions_super_admin_all on public.approval_actions;
drop policy if exists submission_events_select_scoped on public.submission_events;
drop policy if exists submission_events_super_admin_all on public.submission_events;
drop policy if exists audit_logs_select_admin on public.audit_logs;
drop policy if exists audit_logs_super_admin_all on public.audit_logs;
drop policy if exists report_exports_select_scoped on public.report_exports;
drop policy if exists report_exports_insert_exporters on public.report_exports;
drop policy if exists report_exports_super_admin_all on public.report_exports;

create or replace function public.evidence_file_type_matches_path(
  p_path text,
  p_file_type text
)
returns boolean
language plpgsql
immutable
set search_path = public, pg_temp
as $$
declare
  v_ext text;
  v_type text;
begin
  if p_path is null or p_file_type is null or position('.' in p_path) = 0 then
    return false;
  end if;

  v_ext := lower(regexp_replace(p_path, '^.*\.', ''));
  v_type := lower(p_file_type);

  if v_type = 'jpg' then
    return v_ext in ('jpg', 'jpeg');
  elsif v_type = 'jpeg' then
    return v_ext in ('jpg', 'jpeg');
  elsif v_type in ('png', 'webp', 'pdf') then
    return v_ext = v_type;
  end if;

  return false;
end;
$$;

create or replace function public.is_super_admin(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.user_id = p_user_id
      and r.code = 'SUPER_ADMIN'
  ), false);
$$;

create or replace function public.has_role(
  p_user_id uuid,
  p_role_code text
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.user_id = p_user_id
      and r.code = p_role_code
  ), false);
$$;

create or replace function public.unit_is_descendant(
  p_child_unit_id uuid,
  p_parent_unit_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with recursive ancestors as (
    select u.id, u.parent_id, array[u.id] as visited
    from public.units u
    where u.id = p_child_unit_id

    union all

    select parent.id, parent.parent_id, a.visited || parent.id
    from public.units parent
    join ancestors a on parent.id = a.parent_id
    where not parent.id = any(a.visited)
  )
  select coalesce(exists (
    select 1
    from ancestors
    where id = p_parent_unit_id
  ), false);
$$;

create or replace function public.user_has_scope(
  p_user_id uuid,
  p_scope_type text,
  p_unit_id uuid,
  p_contest_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    case
      when p_user_id is null then false
      when public.is_super_admin(p_user_id) then true
      else coalesce(exists (
        select 1
        from public.user_scopes us
        where us.user_id = p_user_id
          and us.scope_type in (p_scope_type, 'manage')
          and (us.contest_id is null or us.contest_id = p_contest_id)
          and (
            us.scope_kind = 'all'
            or (
              us.scope_kind = 'unit'
              and p_unit_id is not null
              and public.unit_is_descendant(p_unit_id, us.unit_id)
            )
          )
      ), false)
    end;
$$;

create or replace function public.can_view_profile(
  p_actor_user_id uuid,
  p_target_user_id uuid,
  p_contest_id uuid default null
)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_target_unit_id uuid;
begin
  if p_actor_user_id is null or p_target_user_id is null then
    return false;
  end if;

  if p_actor_user_id = p_target_user_id or public.is_super_admin(p_actor_user_id) then
    return true;
  end if;

  select primary_unit_id
  into v_target_unit_id
  from public.profiles
  where id = p_target_user_id
    and is_active;

  return coalesce(exists (
    select 1
    from public.user_scopes us
    where us.user_id = p_actor_user_id
      and us.scope_type in ('view', 'approve', 'export', 'manage')
      and (us.contest_id is null or us.contest_id = p_contest_id)
      and (
        (us.scope_kind = 'all')
        or (
          us.scope_kind = 'user'
          and us.target_user_id = p_target_user_id
        )
        or (
          us.scope_kind = 'unit'
          and v_target_unit_id is not null
          and public.unit_is_descendant(v_target_unit_id, us.unit_id)
        )
      )
  ), false);
end;
$$;

create or replace function public.can_view_submission(
  p_actor_user_id uuid,
  p_submission_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_submission_user_id uuid;
  v_contest_id uuid;
  v_unit_id uuid;
begin
  if p_actor_user_id is null or p_submission_id is null then
    return false;
  end if;

  select s.user_id, s.contest_id, coalesce(cp.assigned_unit_id, p.primary_unit_id)
  into v_submission_user_id, v_contest_id, v_unit_id
  from public.submissions s
  join public.profiles p on p.id = s.user_id
  left join public.contest_participants cp
    on cp.contest_id = s.contest_id
   and cp.user_id = s.user_id
  where s.id = p_submission_id;

  if v_submission_user_id is null then
    return false;
  end if;

  if p_actor_user_id = v_submission_user_id or public.is_super_admin(p_actor_user_id) then
    return true;
  end if;

  return public.can_view_profile(p_actor_user_id, v_submission_user_id, v_contest_id)
    or public.user_has_scope(p_actor_user_id, 'view', v_unit_id, v_contest_id)
    or public.user_has_scope(p_actor_user_id, 'approve', v_unit_id, v_contest_id)
    or public.user_has_scope(p_actor_user_id, 'export', v_unit_id, v_contest_id);
end;
$$;

create or replace function public.can_approve_submission(
  p_actor_user_id uuid,
  p_submission_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_contest_id uuid;
  v_unit_id uuid;
  v_step_id uuid;
  v_step_snapshot_id uuid;
  v_has_step_approvers boolean;
  v_role_ok boolean;
begin
  if p_actor_user_id is null or p_submission_id is null then
    return false;
  end if;

  if public.is_super_admin(p_actor_user_id) then
    return true;
  end if;

  select s.contest_id,
         coalesce(cp.assigned_unit_id, p.primary_unit_id),
         sas.step_id,
         sas.id
  into v_contest_id, v_unit_id, v_step_id, v_step_snapshot_id
  from public.submissions s
  join public.profiles p on p.id = s.user_id
  left join public.contest_participants cp
    on cp.contest_id = s.contest_id
   and cp.user_id = s.user_id
  join public.submission_approval_steps sas
    on sas.submission_id = s.id
   and sas.step_order = s.current_step_order
  where s.id = p_submission_id
    and s.current_status = 'PENDING_APPROVAL'
    and sas.status = 'PENDING';

  if v_step_snapshot_id is null then
    return false;
  end if;

  if not public.user_has_scope(p_actor_user_id, 'approve', v_unit_id, v_contest_id) then
    return false;
  end if;

  select exists (
    select 1
    from public.approval_step_roles asr
    join public.user_roles ur on ur.role_id = asr.role_id
    where asr.step_id = v_step_id
      and ur.user_id = p_actor_user_id
  )
  into v_role_ok;

  if not v_role_ok then
    return false;
  end if;

  select exists (
    select 1
    from public.submission_step_approvers ssa
    where ssa.submission_approval_step_id = v_step_snapshot_id
  )
  into v_has_step_approvers;

  if v_has_step_approvers then
    return exists (
      select 1
      from public.submission_step_approvers ssa
      where ssa.submission_approval_step_id = v_step_snapshot_id
        and ssa.approver_user_id = p_actor_user_id
        and ssa.status = 'PENDING'
    );
  end if;

  return true;
end;
$$;

create or replace function public.log_audit(
  p_action text,
  p_entity_type text,
  p_entity_id uuid default null,
  p_old_value jsonb default null,
  p_new_value jsonb default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_audit_id uuid;
begin
  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    old_value,
    new_value
  )
  values (
    auth.uid(),
    p_action,
    p_entity_type,
    p_entity_id,
    p_old_value,
    p_new_value
  )
  returning id into v_audit_id;

  return v_audit_id;
end;
$$;

create or replace function public.get_public_dashboard(p_contest_id uuid default null)
returns table (
  contest_id uuid,
  contest_title text,
  deadline timestamptz,
  total_assigned bigint,
  total_submitted bigint,
  total_approved bigint,
  total_rejected bigint,
  total_pending bigint,
  total_not_submitted bigint,
  expired_not_submitted bigint,
  expired_pending bigint
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with chosen_contest as (
    select c.*
    from public.contests c
    where (
        p_contest_id is not null
        and c.id = p_contest_id
        and c.status in ('active', 'closed', 'archived')
      )
      or (
        p_contest_id is null
        and c.status = 'active'
      )
    order by c.deadline asc
    limit 1
  )
  select
    c.id,
    c.title,
    c.deadline,
    count(cp.id) filter (where cp.is_required) as total_assigned,
    count(s.id) filter (where cp.is_required and s.id is not null) as total_submitted,
    count(s.id) filter (where cp.is_required and s.current_status = 'APPROVED') as total_approved,
    count(s.id) filter (where cp.is_required and s.current_status = 'REJECTED') as total_rejected,
    count(s.id) filter (
      where cp.is_required
        and s.current_status in ('SUBMITTED', 'RESUBMITTED', 'PENDING_APPROVAL')
    ) as total_pending,
    count(cp.id) filter (where cp.is_required and s.id is null) as total_not_submitted,
    count(cp.id) filter (where cp.is_required and s.id is null and now() > c.deadline) as expired_not_submitted,
    count(s.id) filter (
      where cp.is_required
        and s.current_status in ('SUBMITTED', 'RESUBMITTED', 'PENDING_APPROVAL')
        and now() > c.deadline
    ) as expired_pending
  from chosen_contest c
  left join public.contest_participants cp on cp.contest_id = c.id
  left join public.submissions s
    on s.contest_id = cp.contest_id
   and s.user_id = cp.user_id
  group by c.id, c.title, c.deadline;
$$;

create or replace function public.get_admin_dashboard(p_contest_id uuid default null)
returns table (
  contest_id uuid,
  contest_title text,
  deadline timestamptz,
  total_assigned bigint,
  total_submitted bigint,
  total_approved bigint,
  total_rejected bigint,
  total_pending bigint,
  total_not_submitted bigint,
  expired_not_submitted bigint,
  expired_pending bigint
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null then
    raise exception 'Authentication required';
  end if;

  return query
  with chosen_contest as (
    select c.*
    from public.contests c
    where (
        p_contest_id is not null
        and c.id = p_contest_id
      )
      or (
        p_contest_id is null
        and c.status = 'active'
      )
    order by c.deadline asc
    limit 1
  ),
  scoped_participants as (
    select cp.*
    from public.contest_participants cp
    join chosen_contest c on c.id = cp.contest_id
    where public.can_view_profile(v_actor, cp.user_id, cp.contest_id)
  )
  select
    c.id,
    c.title,
    c.deadline,
    count(cp.id) filter (where cp.is_required) as total_assigned,
    count(s.id) filter (where cp.is_required and s.id is not null) as total_submitted,
    count(s.id) filter (where cp.is_required and s.current_status = 'APPROVED') as total_approved,
    count(s.id) filter (where cp.is_required and s.current_status = 'REJECTED') as total_rejected,
    count(s.id) filter (
      where cp.is_required
        and s.current_status in ('SUBMITTED', 'RESUBMITTED', 'PENDING_APPROVAL')
    ) as total_pending,
    count(cp.id) filter (where cp.is_required and s.id is null) as total_not_submitted,
    count(cp.id) filter (where cp.is_required and s.id is null and now() > c.deadline) as expired_not_submitted,
    count(s.id) filter (
      where cp.is_required
        and s.current_status in ('SUBMITTED', 'RESUBMITTED', 'PENDING_APPROVAL')
        and now() > c.deadline
    ) as expired_pending
  from chosen_contest c
  left join scoped_participants cp on cp.contest_id = c.id
  left join public.submissions s
    on s.contest_id = cp.contest_id
   and s.user_id = cp.user_id
  group by c.id, c.title, c.deadline;
end;
$$;

create or replace function public.submit_evidence(
  p_contest_id uuid,
  p_storage_path text,
  p_file_type text,
  p_file_size_kb integer,
  p_submission_id uuid default null,
  p_note text default null
)
returns public.submissions
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_contest public.contests%rowtype;
  v_existing_submission public.submissions%rowtype;
  v_submission public.submissions%rowtype;
  v_submission_id uuid;
  v_from_status text;
  v_flow public.approval_flows%rowtype;
  v_step record;
  v_step_snapshot_id uuid;
  v_first_step_order integer;
  v_next_version integer;
  v_expected_prefix text;
  v_to_status text;
  v_restart_step_order integer;
begin
  if v_actor is null then
    raise exception 'Authentication required';
  end if;

  select *
  into v_contest
  from public.contests
  where id = p_contest_id
    and status = 'active'
  for update;

  if not found then
    raise exception 'Contest is not active or does not exist';
  end if;

  if now() > v_contest.deadline and not v_contest.allow_late_submission then
    raise exception 'Contest deadline has passed';
  end if;

  if p_file_size_kb is null or p_file_size_kb <= 0 or p_file_size_kb > v_contest.max_upload_size_kb then
    raise exception 'Invalid file size';
  end if;

  if lower(p_file_type) = 'pdf' and not v_contest.allow_pdf_upload then
    raise exception 'PDF evidence is disabled for this contest';
  end if;

  if not public.evidence_file_type_matches_path(p_storage_path, p_file_type) then
    raise exception 'Storage path extension does not match file_type';
  end if;

  if not exists (
    select 1
    from public.contest_participants cp
    where cp.contest_id = p_contest_id
      and cp.user_id = v_actor
      and cp.is_required
  ) then
    raise exception 'User is not assigned to this contest';
  end if;

  select *
  into v_existing_submission
  from public.submissions
  where contest_id = p_contest_id
    and user_id = v_actor
  for update;

  if v_existing_submission.id is not null then
    if v_existing_submission.current_status in ('SUBMITTED', 'RESUBMITTED', 'PENDING_APPROVAL')
       and not v_contest.allow_edit_while_pending then
      raise exception 'Editing while pending is disabled for this contest';
    end if;

    if v_existing_submission.current_status = 'REJECTED'
       and not v_contest.allow_resubmit_after_reject then
      raise exception 'Resubmission after reject is disabled for this contest';
    end if;

    if v_existing_submission.current_status = 'APPROVED' then
      raise exception 'Approved submissions cannot be resubmitted in L1';
    end if;

    if v_existing_submission.current_status = 'REJECTED'
       and v_contest.resubmit_mode = 'restart_from_rejected_step' then
      select min(step_order)
      into v_restart_step_order
      from public.submission_approval_steps
      where submission_id = v_existing_submission.id
        and status = 'REJECTED';
    end if;
  end if;

  v_submission_id := coalesce(v_existing_submission.id, p_submission_id, gen_random_uuid());
  v_expected_prefix := p_contest_id::text || '/' || v_actor::text || '/' || v_submission_id::text || '/';

  if left(p_storage_path, length(v_expected_prefix)) <> v_expected_prefix then
    raise exception 'Storage path must start with contest_id/user_id/submission_id/';
  end if;

  select *
  into v_flow
  from public.approval_flows af
  where af.contest_id = p_contest_id
    and af.is_active
  order by af.version desc
  limit 1;

  if v_existing_submission.id is null then
    insert into public.submissions (
      id,
      contest_id,
      user_id,
      current_status,
      flow_id,
      flow_version,
      submitted_at
    )
    values (
      v_submission_id,
      p_contest_id,
      v_actor,
      'SUBMITTED',
      v_flow.id,
      v_flow.version,
      now()
    )
    returning * into v_submission;
    v_from_status := null;
  else
    v_from_status := v_existing_submission.current_status;

    update public.submissions
    set current_status = 'RESUBMITTED',
        current_step_order = null,
        flow_id = v_flow.id,
        flow_version = v_flow.version,
        last_resubmitted_at = now(),
        final_approved_at = null,
        final_rejected_at = null
    where id = v_existing_submission.id
    returning * into v_submission;
  end if;

  delete from public.submission_step_approvers ssa
  using public.submission_approval_steps sas
  where ssa.submission_approval_step_id = sas.id
    and sas.submission_id = v_submission.id;

  delete from public.submission_approval_steps
  where submission_id = v_submission.id;

  select coalesce(max(version_number), 0) + 1
  into v_next_version
  from public.submission_files
  where submission_id = v_submission.id;

  update public.submission_files
  set is_current = false
  where submission_id = v_submission.id
    and is_current = true;

  insert into public.submission_files (
    submission_id,
    storage_path,
    file_type,
    file_size_kb,
    uploaded_by,
    version_number,
    is_current
  )
  values (
    v_submission.id,
    p_storage_path,
    lower(p_file_type),
    p_file_size_kb,
    v_actor,
    v_next_version,
    true
  );

  if v_flow.id is not null then
    for v_step in
      select aps.*
      from public.approval_steps aps
      where aps.flow_id = v_flow.id
      order by aps.step_order
    loop
      if v_step.approval_rule = 'ALL_REQUIRED'
         and not exists (
           select 1
           from public.approval_step_assignees asa
           where asa.step_id = v_step.id
             and asa.is_required
         ) then
        raise exception 'ALL_REQUIRED step % requires concrete assignees', v_step.step_order;
      end if;

      insert into public.submission_approval_steps (
        submission_id,
        step_id,
        step_order,
        step_name,
        approval_rule,
        status,
        opened_at
      )
      values (
        v_submission.id,
        v_step.id,
        v_step.step_order,
        v_step.step_name,
        v_step.approval_rule,
        'PENDING',
        null
      )
      returning id into v_step_snapshot_id;

      insert into public.submission_step_approvers (
        submission_approval_step_id,
        approver_user_id,
        status
      )
      select
        v_step_snapshot_id,
        asa.user_id,
        'PENDING'
      from public.approval_step_assignees asa
      where asa.step_id = v_step.id
        and asa.is_required;
    end loop;
  end if;

  select min(step_order)
  into v_first_step_order
  from public.submission_approval_steps
  where submission_id = v_submission.id;

  if v_restart_step_order is not null and exists (
    select 1
    from public.submission_approval_steps
    where submission_id = v_submission.id
      and step_order = v_restart_step_order
  ) then
    v_first_step_order := v_restart_step_order;
  end if;

  if v_first_step_order is null then
    v_to_status := 'APPROVED';
    update public.submissions
    set current_status = 'APPROVED',
        current_step_order = null,
        final_approved_at = now()
    where id = v_submission.id
    returning * into v_submission;
  else
    v_to_status := 'PENDING_APPROVAL';

    update public.submission_approval_steps
    set status = 'SKIPPED',
        completed_at = now()
    where submission_id = v_submission.id
      and step_order < v_first_step_order;

    update public.submission_approval_steps
    set opened_at = now()
    where submission_id = v_submission.id
      and step_order = v_first_step_order;

    update public.submissions
    set current_status = 'PENDING_APPROVAL',
        current_step_order = v_first_step_order
    where id = v_submission.id
    returning * into v_submission;
  end if;

  insert into public.submission_events (
    submission_id,
    event_type,
    from_status,
    to_status,
    actor_user_id,
    note,
    metadata
  )
  values (
    v_submission.id,
    case when v_from_status is null then 'SUBMITTED' else 'RESUBMITTED' end,
    v_from_status,
    v_to_status,
    v_actor,
    p_note,
    jsonb_build_object(
      'storage_path', p_storage_path,
      'file_type', lower(p_file_type),
      'file_size_kb', p_file_size_kb,
      'version_number', v_next_version,
      'resubmit_mode', v_contest.resubmit_mode,
      'restart_step_order', v_restart_step_order
    )
  );

  perform public.log_audit(
    case when v_from_status is null then 'SUBMIT_EVIDENCE' else 'RESUBMIT_EVIDENCE' end,
    'submission',
    v_submission.id,
    null,
    jsonb_build_object('status', v_to_status, 'storage_path', p_storage_path)
  );

  return v_submission;
end;
$$;

create or replace function public.approve_submission(
  p_submission_id uuid,
  p_note text default null
)
returns public.submissions
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_submission public.submissions%rowtype;
  v_step public.submission_approval_steps%rowtype;
  v_action_id uuid;
  v_actor_role_code text;
  v_next_step_order integer;
  v_step_complete boolean;
  v_from_status text;
begin
  if v_actor is null then
    raise exception 'Authentication required';
  end if;

  if not public.can_approve_submission(v_actor, p_submission_id) then
    raise exception 'Permission denied';
  end if;

  select *
  into v_submission
  from public.submissions
  where id = p_submission_id
  for update;

  if v_submission.current_status <> 'PENDING_APPROVAL' then
    raise exception 'Submission is not pending approval';
  end if;

  select *
  into v_step
  from public.submission_approval_steps
  where submission_id = p_submission_id
    and step_order = v_submission.current_step_order
  for update;

  if not found or v_step.status <> 'PENDING' then
    raise exception 'Current approval step is not pending';
  end if;

  if exists (
    select 1
    from public.approval_steps aps
    where aps.id = v_step.step_id
      and aps.require_note_on_approve
  ) and btrim(coalesce(p_note, '')) = '' then
    raise exception 'Approval note is required';
  end if;

  select r.code
  into v_actor_role_code
  from public.roles r
  join public.user_roles ur on ur.role_id = r.id
  join public.approval_step_roles asr on asr.role_id = r.id
  where ur.user_id = v_actor
    and asr.step_id = v_step.step_id
  order by r.code
  limit 1;

  if v_actor_role_code is null and public.is_super_admin(v_actor) then
    v_actor_role_code := 'SUPER_ADMIN';
  end if;

  insert into public.approval_actions (
    submission_id,
    contest_id,
    flow_id,
    flow_version,
    step_order,
    step_name,
    action,
    actor_user_id,
    actor_role_code,
    note
  )
  values (
    v_submission.id,
    v_submission.contest_id,
    v_submission.flow_id,
    v_submission.flow_version,
    v_step.step_order,
    v_step.step_name,
    'APPROVED',
    v_actor,
    v_actor_role_code,
    p_note
  )
  returning id into v_action_id;

  update public.submission_step_approvers
  set status = 'APPROVED',
      approval_action_id = v_action_id
  where submission_approval_step_id = v_step.id
    and approver_user_id = v_actor
    and status = 'PENDING';

  if v_step.approval_rule = 'ANY_ONE' then
    v_step_complete := true;
  else
    select exists (
             select 1
             from public.submission_step_approvers ssa
             where ssa.submission_approval_step_id = v_step.id
           )
           and not exists (
             select 1
             from public.submission_step_approvers ssa
             where ssa.submission_approval_step_id = v_step.id
               and ssa.status <> 'APPROVED'
           )
    into v_step_complete;
  end if;

  if v_step_complete then
    update public.submission_approval_steps
    set status = 'APPROVED',
        completed_at = now()
    where id = v_step.id;

    select min(step_order)
    into v_next_step_order
    from public.submission_approval_steps
    where submission_id = v_submission.id
      and step_order > v_step.step_order;

    if v_next_step_order is null then
      v_from_status := v_submission.current_status;
      update public.submissions
      set current_status = 'APPROVED',
          current_step_order = null,
          final_approved_at = now()
      where id = v_submission.id
      returning * into v_submission;
    else
      update public.submission_approval_steps
      set opened_at = now()
      where submission_id = v_submission.id
        and step_order = v_next_step_order;

      update public.submissions
      set current_step_order = v_next_step_order
      where id = v_submission.id
      returning * into v_submission;
    end if;
  end if;

  insert into public.submission_events (
    submission_id,
    event_type,
    from_status,
    to_status,
    actor_user_id,
    note,
    metadata
  )
  values (
    v_submission.id,
    'APPROVED_STEP',
    coalesce(v_from_status, 'PENDING_APPROVAL'),
    v_submission.current_status,
    v_actor,
    p_note,
    jsonb_build_object(
      'step_order', v_step.step_order,
      'step_name', v_step.step_name,
      'action_id', v_action_id
    )
  );

  perform public.log_audit(
    'APPROVE_SUBMISSION',
    'submission',
    v_submission.id,
    jsonb_build_object('step_order', v_step.step_order),
    jsonb_build_object('status', v_submission.current_status, 'action_id', v_action_id)
  );

  return v_submission;
end;
$$;

create or replace function public.reject_submission(
  p_submission_id uuid,
  p_reason text,
  p_note text default null
)
returns public.submissions
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_submission public.submissions%rowtype;
  v_step public.submission_approval_steps%rowtype;
  v_action_id uuid;
  v_actor_role_code text;
  v_from_status text;
begin
  if v_actor is null then
    raise exception 'Authentication required';
  end if;

  if btrim(coalesce(p_reason, '')) = '' then
    raise exception 'Reject reason is required';
  end if;

  if not public.can_approve_submission(v_actor, p_submission_id) then
    raise exception 'Permission denied';
  end if;

  select *
  into v_submission
  from public.submissions
  where id = p_submission_id
  for update;

  if v_submission.current_status <> 'PENDING_APPROVAL' then
    raise exception 'Submission is not pending approval';
  end if;

  select *
  into v_step
  from public.submission_approval_steps
  where submission_id = p_submission_id
    and step_order = v_submission.current_step_order
  for update;

  if not found or v_step.status <> 'PENDING' then
    raise exception 'Current approval step is not pending';
  end if;

  if exists (
    select 1
    from public.approval_steps aps
    where aps.id = v_step.step_id
      and not aps.can_reject
  ) then
    raise exception 'This approval step cannot reject';
  end if;

  select r.code
  into v_actor_role_code
  from public.roles r
  join public.user_roles ur on ur.role_id = r.id
  join public.approval_step_roles asr on asr.role_id = r.id
  where ur.user_id = v_actor
    and asr.step_id = v_step.step_id
  order by r.code
  limit 1;

  if v_actor_role_code is null and public.is_super_admin(v_actor) then
    v_actor_role_code := 'SUPER_ADMIN';
  end if;

  insert into public.approval_actions (
    submission_id,
    contest_id,
    flow_id,
    flow_version,
    step_order,
    step_name,
    action,
    actor_user_id,
    actor_role_code,
    note,
    reject_reason
  )
  values (
    v_submission.id,
    v_submission.contest_id,
    v_submission.flow_id,
    v_submission.flow_version,
    v_step.step_order,
    v_step.step_name,
    'REJECTED',
    v_actor,
    v_actor_role_code,
    p_note,
    p_reason
  )
  returning id into v_action_id;

  update public.submission_step_approvers
  set status = 'REJECTED',
      approval_action_id = v_action_id
  where submission_approval_step_id = v_step.id
    and approver_user_id = v_actor
    and status = 'PENDING';

  update public.submission_approval_steps
  set status = 'REJECTED',
      completed_at = now()
  where id = v_step.id;

  v_from_status := v_submission.current_status;

  update public.submissions
  set current_status = 'REJECTED',
      current_step_order = null,
      final_rejected_at = now()
  where id = v_submission.id
  returning * into v_submission;

  insert into public.submission_events (
    submission_id,
    event_type,
    from_status,
    to_status,
    actor_user_id,
    note,
    metadata
  )
  values (
    v_submission.id,
    'REJECTED_STEP',
    v_from_status,
    v_submission.current_status,
    v_actor,
    p_note,
    jsonb_build_object(
      'step_order', v_step.step_order,
      'step_name', v_step.step_name,
      'reason', p_reason,
      'action_id', v_action_id
    )
  );

  perform public.log_audit(
    'REJECT_SUBMISSION',
    'submission',
    v_submission.id,
    jsonb_build_object('step_order', v_step.step_order),
    jsonb_build_object('status', v_submission.current_status, 'reason', p_reason, 'action_id', v_action_id)
  );

  return v_submission;
end;
$$;

create policy profiles_select_scoped
on public.profiles
for select
to authenticated
using (
  id = auth.uid()
  or public.can_view_profile(auth.uid(), id, null)
);

create policy profiles_admin_insert
on public.profiles
for insert
to authenticated
with check (
  public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', primary_unit_id, null)
);

create policy profiles_admin_update
on public.profiles
for update
to authenticated
using (
  public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', primary_unit_id, null)
)
with check (
  public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', primary_unit_id, null)
);

create policy roles_select_authenticated
on public.roles
for select
to authenticated
using (true);

create policy roles_super_admin_all
on public.roles
for all
to authenticated
using (public.is_super_admin(auth.uid()))
with check (public.is_super_admin(auth.uid()));

create policy user_roles_select_own_or_admin
on public.user_roles
for select
to authenticated
using (
  user_id = auth.uid()
  or public.is_super_admin(auth.uid())
);

create policy user_roles_super_admin_all
on public.user_roles
for all
to authenticated
using (public.is_super_admin(auth.uid()))
with check (public.is_super_admin(auth.uid()));

create policy units_select_authenticated
on public.units
for select
to authenticated
using (true);

create policy units_manage
on public.units
for all
to authenticated
using (
  public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', id, null)
)
with check (
  public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', id, null)
);

create policy user_scopes_select_own_or_admin
on public.user_scopes
for select
to authenticated
using (
  user_id = auth.uid()
  or public.is_super_admin(auth.uid())
);

create policy user_scopes_super_admin_all
on public.user_scopes
for all
to authenticated
using (public.is_super_admin(auth.uid()))
with check (public.is_super_admin(auth.uid()));

create policy participant_groups_select_authenticated
on public.participant_groups
for select
to authenticated
using (true);

create policy participant_groups_manage
on public.participant_groups
for all
to authenticated
using (
  public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', null, null)
)
with check (
  public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', null, null)
);

create policy app_settings_select_authenticated
on public.app_settings
for select
to authenticated
using (
  is_public
  or public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', null, null)
);

create policy app_settings_manage
on public.app_settings
for all
to authenticated
using (
  public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', null, null)
)
with check (
  public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', null, null)
);

create policy contests_select_authenticated
on public.contests
for select
to authenticated
using (
  status in ('active', 'closed', 'archived')
  or public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'view', null, id)
  or public.user_has_scope(auth.uid(), 'manage', null, id)
  or exists (
    select 1
    from public.contest_participants cp
    where cp.contest_id = contests.id
      and cp.user_id = auth.uid()
  )
);

create policy contests_manage
on public.contests
for all
to authenticated
using (
  public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', null, id)
)
with check (
  public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', null, id)
);

create policy contest_participants_select_scoped
on public.contest_participants
for select
to authenticated
using (
  user_id = auth.uid()
  or public.can_view_profile(auth.uid(), user_id, contest_id)
);

create policy contest_participants_manage
on public.contest_participants
for all
to authenticated
using (
  public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', assigned_unit_id, contest_id)
)
with check (
  public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', assigned_unit_id, contest_id)
);

create policy approval_flows_select_authenticated
on public.approval_flows
for select
to authenticated
using (true);

create policy approval_steps_select_authenticated
on public.approval_steps
for select
to authenticated
using (true);

create policy approval_step_roles_select_authenticated
on public.approval_step_roles
for select
to authenticated
using (true);

create policy approval_step_assignees_select_authenticated
on public.approval_step_assignees
for select
to authenticated
using (true);

create policy approval_flows_manage
on public.approval_flows
for all
to authenticated
using (
  public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', null, contest_id)
)
with check (
  public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'manage', null, contest_id)
);

create policy approval_steps_manage
on public.approval_steps
for all
to authenticated
using (
  public.is_super_admin(auth.uid())
  or exists (
    select 1
    from public.approval_flows af
    where af.id = approval_steps.flow_id
      and public.user_has_scope(auth.uid(), 'manage', null, af.contest_id)
  )
)
with check (
  public.is_super_admin(auth.uid())
  or exists (
    select 1
    from public.approval_flows af
    where af.id = approval_steps.flow_id
      and public.user_has_scope(auth.uid(), 'manage', null, af.contest_id)
  )
);

create policy approval_step_roles_manage
on public.approval_step_roles
for all
to authenticated
using (
  public.is_super_admin(auth.uid())
)
with check (
  public.is_super_admin(auth.uid())
);

create policy approval_step_assignees_manage
on public.approval_step_assignees
for all
to authenticated
using (
  public.is_super_admin(auth.uid())
)
with check (
  public.is_super_admin(auth.uid())
);

create policy submissions_select_scoped
on public.submissions
for select
to authenticated
using (
  user_id = auth.uid()
  or public.can_view_submission(auth.uid(), id)
);

create policy submissions_super_admin_all
on public.submissions
for all
to authenticated
using (public.is_super_admin(auth.uid()))
with check (public.is_super_admin(auth.uid()));

create policy submission_files_select_scoped
on public.submission_files
for select
to authenticated
using (
  uploaded_by = auth.uid()
  or public.can_view_submission(auth.uid(), submission_id)
);

create policy submission_files_super_admin_all
on public.submission_files
for all
to authenticated
using (public.is_super_admin(auth.uid()))
with check (public.is_super_admin(auth.uid()));

create policy submission_approval_steps_select_scoped
on public.submission_approval_steps
for select
to authenticated
using (public.can_view_submission(auth.uid(), submission_id));

create policy submission_approval_steps_super_admin_all
on public.submission_approval_steps
for all
to authenticated
using (public.is_super_admin(auth.uid()))
with check (public.is_super_admin(auth.uid()));

create policy submission_step_approvers_select_scoped
on public.submission_step_approvers
for select
to authenticated
using (
  approver_user_id = auth.uid()
  or exists (
    select 1
    from public.submission_approval_steps sas
    where sas.id = submission_step_approvers.submission_approval_step_id
      and public.can_view_submission(auth.uid(), sas.submission_id)
  )
);

create policy submission_step_approvers_super_admin_all
on public.submission_step_approvers
for all
to authenticated
using (public.is_super_admin(auth.uid()))
with check (public.is_super_admin(auth.uid()));

create policy approval_actions_select_scoped
on public.approval_actions
for select
to authenticated
using (
  actor_user_id = auth.uid()
  or public.can_view_submission(auth.uid(), submission_id)
);

create policy approval_actions_super_admin_all
on public.approval_actions
for all
to authenticated
using (public.is_super_admin(auth.uid()))
with check (public.is_super_admin(auth.uid()));

create policy submission_events_select_scoped
on public.submission_events
for select
to authenticated
using (public.can_view_submission(auth.uid(), submission_id));

create policy submission_events_super_admin_all
on public.submission_events
for all
to authenticated
using (public.is_super_admin(auth.uid()))
with check (public.is_super_admin(auth.uid()));

create policy audit_logs_select_admin
on public.audit_logs
for select
to authenticated
using (
  public.is_super_admin(auth.uid())
  or public.has_role(auth.uid(), 'IT_ADMIN')
);

create policy audit_logs_super_admin_all
on public.audit_logs
for all
to authenticated
using (public.is_super_admin(auth.uid()))
with check (public.is_super_admin(auth.uid()));

create policy report_exports_select_scoped
on public.report_exports
for select
to authenticated
using (
  exported_by = auth.uid()
  or public.is_super_admin(auth.uid())
  or public.user_has_scope(auth.uid(), 'export', null, contest_id)
);

create policy report_exports_insert_exporters
on public.report_exports
for insert
to authenticated
with check (
  exported_by = auth.uid()
  and (
    public.is_super_admin(auth.uid())
    or public.user_has_scope(auth.uid(), 'export', null, contest_id)
  )
);

create policy report_exports_super_admin_all
on public.report_exports
for all
to authenticated
using (public.is_super_admin(auth.uid()))
with check (public.is_super_admin(auth.uid()));

revoke all on function public.evidence_file_type_matches_path(text, text) from public;
revoke all on function public.is_super_admin(uuid) from public;
revoke all on function public.has_role(uuid, text) from public;
revoke all on function public.unit_is_descendant(uuid, uuid) from public;
revoke all on function public.user_has_scope(uuid, text, uuid, uuid) from public;
revoke all on function public.can_view_profile(uuid, uuid, uuid) from public;
revoke all on function public.can_view_submission(uuid, uuid) from public;
revoke all on function public.can_approve_submission(uuid, uuid) from public;
revoke all on function public.log_audit(text, text, uuid, jsonb, jsonb) from public;
revoke all on function public.get_public_dashboard(uuid) from public;
revoke all on function public.get_admin_dashboard(uuid) from public;
revoke all on function public.submit_evidence(uuid, text, text, integer, uuid, text) from public;
revoke all on function public.approve_submission(uuid, text) from public;
revoke all on function public.reject_submission(uuid, text, text) from public;

grant execute on function public.evidence_file_type_matches_path(text, text) to authenticated;
grant execute on function public.is_super_admin(uuid) to authenticated;
grant execute on function public.has_role(uuid, text) to authenticated;
grant execute on function public.unit_is_descendant(uuid, uuid) to authenticated;
grant execute on function public.user_has_scope(uuid, text, uuid, uuid) to authenticated;
grant execute on function public.can_view_profile(uuid, uuid, uuid) to authenticated;
grant execute on function public.can_view_submission(uuid, uuid) to authenticated;
grant execute on function public.can_approve_submission(uuid, uuid) to authenticated;
grant execute on function public.get_public_dashboard(uuid) to anon, authenticated;
grant execute on function public.get_admin_dashboard(uuid) to authenticated;
grant execute on function public.submit_evidence(uuid, text, text, integer, uuid, text) to authenticated;
grant execute on function public.approve_submission(uuid, text) to authenticated;
grant execute on function public.reject_submission(uuid, text, text) to authenticated;

comment on function public.submit_evidence(uuid, text, text, integer, uuid, text) is
'Uploads are expected to happen in Storage first. This RPC then updates old submission_files.is_current=false before inserting the new current file to satisfy the partial unique index.';

commit;
