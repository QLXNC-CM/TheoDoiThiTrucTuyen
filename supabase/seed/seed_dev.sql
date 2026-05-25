-- FILE: supabase/seed/seed_dev.sql

begin;

insert into public.roles (id, code, name, description)
values
  ('00000000-0000-0000-0000-000000000101', 'SUPER_ADMIN', 'Super Admin', 'Toan quyen quan tri he thong.'),
  ('00000000-0000-0000-0000-000000000102', 'IT_ADMIN', 'IT Admin', 'Ho tro ky thuat theo scope duoc cap.'),
  ('00000000-0000-0000-0000-000000000103', 'DEPARTMENT_COMMAND', 'Chi huy phong/ban', 'Phe duyet va xem bao cao trong pham vi phong/ban.'),
  ('00000000-0000-0000-0000-000000000104', 'TEAM_COMMAND', 'Chi huy doi/to', 'Phe duyet va xem bao cao trong pham vi doi/to.'),
  ('00000000-0000-0000-0000-000000000105', 'USER', 'Nguoi dung', 'Can bo/nguoi dung nop ket qua thi.')
on conflict (code) do update
set name = excluded.name,
    description = excluded.description;

insert into public.participant_groups (id, code, name, description, sort_order)
values
  ('00000000-0000-0000-0000-000000000201', 'CAN_BO', 'Can bo', 'Nhom can bo.', 10),
  ('00000000-0000-0000-0000-000000000202', 'CHI_HUY', 'Chi huy', 'Nhom chi huy.', 20),
  ('00000000-0000-0000-0000-000000000203', 'DOAN_VIEN', 'Doan vien', 'Nhom doan vien.', 30),
  ('00000000-0000-0000-0000-000000000204', 'CHIEN_SI', 'Chien si', 'Nhom chien si.', 40),
  ('00000000-0000-0000-0000-000000000205', 'KHAC', 'Khac', 'Nhom khac.', 50)
on conflict (code) do update
set name = excluded.name,
    description = excluded.description,
    sort_order = excluded.sort_order,
    is_active = true;

insert into public.units (id, name, type, parent_id, sort_order)
values
  ('00000000-0000-0000-0000-000000000301', 'Phong Tham muu', 'department', null, 10),
  ('00000000-0000-0000-0000-000000000302', 'Phong Chinh tri', 'department', null, 20),
  ('00000000-0000-0000-0000-000000000303', 'Phong Hau can - Ky thuat', 'department', null, 30)
on conflict (id) do update
set name = excluded.name,
    type = excluded.type,
    parent_id = excluded.parent_id,
    sort_order = excluded.sort_order,
    is_active = true;

insert into public.units (id, name, type, parent_id, sort_order)
values
  ('00000000-0000-0000-0000-000000000311', 'Doi Tong hop', 'team', '00000000-0000-0000-0000-000000000301', 10),
  ('00000000-0000-0000-0000-000000000312', 'Doi Nghiep vu', 'team', '00000000-0000-0000-0000-000000000301', 20),
  ('00000000-0000-0000-0000-000000000321', 'Doi Tuyen truyen', 'team', '00000000-0000-0000-0000-000000000302', 10),
  ('00000000-0000-0000-0000-000000000322', 'Doi To chuc', 'team', '00000000-0000-0000-0000-000000000302', 20),
  ('00000000-0000-0000-0000-000000000331', 'Doi Hau can', 'team', '00000000-0000-0000-0000-000000000303', 10),
  ('00000000-0000-0000-0000-000000000332', 'Doi Ky thuat', 'team', '00000000-0000-0000-0000-000000000303', 20)
on conflict (id) do update
set name = excluded.name,
    type = excluded.type,
    parent_id = excluded.parent_id,
    sort_order = excluded.sort_order,
    is_active = true;

insert into public.app_settings (key, value, description, is_public)
values
  ('max_upload_size_kb', '1024'::jsonb, 'Dung luong file minh chung toi da mac dinh.', true),
  ('allowed_evidence_file_types', '["jpg", "jpeg", "png", "webp"]'::jsonb, 'File type mac dinh cho evidence. PDF chua bat.', true),
  ('allow_pdf_upload_default', 'false'::jsonb, 'PDF evidence mac dinh tat.', true),
  ('keep_old_files_default', 'false'::jsonb, 'Mac dinh khong giu file cu khi gui lai.', false),
  ('display_timezone', '"Asia/Ho_Chi_Minh"'::jsonb, 'Mui gio hien thi cho UI/bao cao.', true)
on conflict (key) do update
set value = excluded.value,
    description = excluded.description,
    is_public = excluded.is_public;

insert into public.contests (
  id,
  title,
  slug,
  description,
  status,
  start_at,
  deadline,
  allow_edit_while_pending,
  allow_resubmit_after_reject,
  resubmit_mode,
  allow_late_submission,
  keep_old_files,
  max_upload_size_kb,
  allow_pdf_upload
)
values
  (
    '00000000-0000-0000-0000-000000000401',
    'Cuoc thi truc tuyen mau',
    'cuoc-thi-truc-tuyen-mau',
    'Cuoc thi mau dung de test nhanh nhanh restart_from_step_1.',
    'active',
    now() - interval '1 day',
    now() + interval '14 days',
    true,
    true,
    'restart_from_step_1',
    false,
    false,
    1024,
    false
  ),
  (
    '00000000-0000-0000-0000-000000000402',
    'Cuoc thi test nop lai tu buoc bi tu choi',
    'cuoc-thi-test-restart-from-rejected-step',
    'Cuoc thi mau dung de test nhanh restart_from_rejected_step.',
    'active',
    now() - interval '1 day',
    now() + interval '21 days',
    true,
    true,
    'restart_from_rejected_step',
    false,
    false,
    1024,
    false
  )
on conflict (id) do update
set title = excluded.title,
    slug = excluded.slug,
    description = excluded.description,
    status = excluded.status,
    start_at = excluded.start_at,
    deadline = excluded.deadline,
    allow_edit_while_pending = excluded.allow_edit_while_pending,
    allow_resubmit_after_reject = excluded.allow_resubmit_after_reject,
    resubmit_mode = excluded.resubmit_mode,
    allow_late_submission = excluded.allow_late_submission,
    keep_old_files = excluded.keep_old_files,
    max_upload_size_kb = excluded.max_upload_size_kb,
    allow_pdf_upload = excluded.allow_pdf_upload;

insert into public.approval_flows (
  id,
  contest_id,
  version,
  name,
  is_active,
  activated_at
)
values
  (
    '00000000-0000-0000-0000-000000000501',
    '00000000-0000-0000-0000-000000000401',
    1,
    'Quy trinh duyet 2 cap mau',
    true,
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000502',
    '00000000-0000-0000-0000-000000000402',
    1,
    'Quy trinh duyet 2 cap mau - restart tu buoc bi tu choi',
    true,
    now()
  )
on conflict (id) do update
set contest_id = excluded.contest_id,
    version = excluded.version,
    name = excluded.name,
    is_active = excluded.is_active,
    activated_at = excluded.activated_at;

insert into public.approval_steps (
  id,
  flow_id,
  step_order,
  step_name,
  scope_type,
  approval_rule,
  can_reject,
  require_note_on_approve,
  require_reason_on_reject
)
values
  (
    '00000000-0000-0000-0000-000000000511',
    '00000000-0000-0000-0000-000000000501',
    1,
    'Chi huy doi/to duyet',
    'team',
    'ANY_ONE',
    true,
    false,
    true
  ),
  (
    '00000000-0000-0000-0000-000000000512',
    '00000000-0000-0000-0000-000000000501',
    2,
    'Ban chi huy phong/ban duyet',
    'department',
    'ANY_ONE',
    true,
    false,
    true
  ),
  (
    '00000000-0000-0000-0000-000000000521',
    '00000000-0000-0000-0000-000000000502',
    1,
    'Chi huy doi/to duyet',
    'team',
    'ANY_ONE',
    true,
    false,
    true
  ),
  (
    '00000000-0000-0000-0000-000000000522',
    '00000000-0000-0000-0000-000000000502',
    2,
    'Ban chi huy phong/ban duyet',
    'department',
    'ANY_ONE',
    true,
    false,
    true
  )
on conflict (id) do update
set flow_id = excluded.flow_id,
    step_order = excluded.step_order,
    step_name = excluded.step_name,
    scope_type = excluded.scope_type,
    approval_rule = excluded.approval_rule,
    can_reject = excluded.can_reject,
    require_note_on_approve = excluded.require_note_on_approve,
    require_reason_on_reject = excluded.require_reason_on_reject;

insert into public.approval_step_roles (step_id, role_id)
values
  ('00000000-0000-0000-0000-000000000511', '00000000-0000-0000-0000-000000000104'),
  ('00000000-0000-0000-0000-000000000512', '00000000-0000-0000-0000-000000000103'),
  ('00000000-0000-0000-0000-000000000521', '00000000-0000-0000-0000-000000000104'),
  ('00000000-0000-0000-0000-000000000522', '00000000-0000-0000-0000-000000000103')
on conflict (step_id, role_id) do nothing;

insert into public.rejection_reason_templates (id, reason_text, sort_order)
values
  ('00000000-0000-0000-0000-000000000701', 'Ma QR khong dung thong tin.', 10),
  ('00000000-0000-0000-0000-000000000702', 'Hinh anh mo, khong du co so xac nhan.', 20),
  ('00000000-0000-0000-0000-000000000703', 'Anh khong the hien ro ket qua hoan thanh.', 30),
  ('00000000-0000-0000-0000-000000000704', 'Thong tin tren minh chung khong khop voi tai khoan.', 40),
  ('00000000-0000-0000-0000-000000000705', 'Khong du co so xac nhan.', 50)
on conflict (id) do update
set reason_text = excluded.reason_text,
    sort_order = excluded.sort_order,
    is_active = true;

/*
  Seed nay khong tao auth.users/profiles vi Supabase Auth users phai duoc tao
  bang Dashboard, script admin local/CI dung service_role, hoac Edge Function.
  Neu provisioning user dev, mat khau ban dau chi duoc lay tu [INITIAL_PASSWORD]
  hoac bien moi truong, khong commit gia tri plaintext vao repository.
*/

commit;
