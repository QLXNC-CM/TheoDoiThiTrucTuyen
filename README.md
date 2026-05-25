FILE: README.md

# Theo doi ket qua thi truc tuyen - L1

L1 tao nen mong ky thuat cho he thong theo doi, bao cao, phe duyet va tong hop ket qua thi truc tuyen noi bo. L1 chi bao gom Supabase schema, RLS/RPC, Storage policies, seed dev/test va tai lieu ky thuat. L1 khong tao React app, khong tao UI, khong tao frontend.

## Cau truc output L1

```text
docs/ARCHITECTURE_L1.md
docs/ASSUMPTIONS.md
docs/SECURITY_NOTES.md
docs/FREE_TIER_NOTES.md
docs/NEXT_STEPS.md
docs/BAN_CHOT_L1.md
docs/BIEN_BAN_BAN_GIAO_L1.md
supabase/migrations/0001_schema.sql
supabase/migrations/0002_rls.sql
supabase/migrations/0003_storage.sql
supabase/seed/seed_dev.sql
README.md
```

## Thu tu chay SQL tu Supabase project moi

Chay dung thu tu sau trong Supabase SQL Editor hoac Supabase CLI:

1. `supabase/migrations/0001_schema.sql`
2. `supabase/migrations/0002_rls.sql`
3. `supabase/migrations/0003_storage.sql`
4. `supabase/seed/seed_dev.sql` cho moi truong dev/test

Migration da duoc viet theo huong idempotent de co the chay lai khi Supabase bao object/policy da ton tai. `0003_storage.sql` se tao/cap nhat bucket truoc; neu role hien tai khong co quyen owner tren `storage.objects`, file se hien `NOTICE` va bo qua phan tao Storage policy thay vi lam rollback bucket. Khi gap `NOTICE` nay, tao cac Storage policies bang Supabase Storage Policies UI hoac chay lai block policy trong `0003_storage.sql` bang role owner cua `storage.objects`.

Khong chay seed dev/test tren production neu chua ra soat lai du lieu mau.

## Cau truc L1 cuoi cung can dong bo

Bang `contests` dung cac cot cau hinh nop lai/upload sau:

```text
allow_edit_while_pending boolean default true
allow_resubmit_after_reject boolean default true
resubmit_mode text default 'restart_from_step_1' check in ('restart_from_step_1','restart_from_rejected_step')
keep_old_files boolean default false
max_upload_size_kb int default 1024 check (max_upload_size_kb > 0)
allow_pdf_upload boolean default false
```

Bang `user_scopes` dung `scope_kind` de phan biet pham vi, khong suy luan `unit_id is null` la toan don vi:

```text
scope_type text not null check in ('view','approve','export','manage')
scope_kind text not null check in ('all','unit','user')
unit_id uuid null references units(id)
contest_id uuid null references contests(id)
target_user_id uuid null references profiles(id)
```

Rang buoc `scope_kind`:

- `all`: `unit_id is null` va `target_user_id is null`.
- `unit`: `unit_id is not null` va `target_user_id is null`.
- `user`: `target_user_id is not null` va `unit_id is null`.

## Cau hinh Supabase Auth

1. Tao Supabase project moi.
2. Vao Authentication settings va tat public signups neu he thong chi dung tai khoan noi bo.
3. Tat email confirmation cho tai khoan noi bo, hoac khi tao user bang Admin API phai dung `email_confirm: true`.
4. Khong dua `service_role` key vao frontend.
5. Tai khoan chi tao bang mot trong cac cach:
   - Supabase Dashboard.
   - Script provisioning local/CI dung `service_role`, khong commit secret.
   - Supabase Edge Function co `service_role` trong secret va co co che bao ve rieng.

## Tao Super Admin dau tien

Cach 1: Supabase Dashboard.

1. Tao Auth user trong Dashboard.
2. Ghi lai UUID cua Auth user.
3. Chay SQL mau sau, thay placeholder bang gia tri that:

```sql
insert into public.profiles (
  id,
  citizen_id_hash,
  citizen_id_last4,
  full_name,
  auth_email,
  force_password_change,
  is_active
)
values (
  '<AUTH_USER_UUID>',
  '<HASHED_NORMALIZED_CITIZEN_ID>',
  '<LAST4>',
  '<FULL_NAME>',
  '<INTERNAL_EMAIL>',
  true,
  true
);

insert into public.user_roles (user_id, role_id)
select '<AUTH_USER_UUID>', id
from public.roles
where code = 'SUPER_ADMIN';
```

Cach 2: Script provisioning local/CI.

- Dung `SUPABASE_SERVICE_ROLE_KEY` chi trong moi truong admin.
- Mat khau ban dau lay tu bien moi truong `INITIAL_PASSWORD`.
- Khong commit `INITIAL_PASSWORD` hoac service key.

Cach 3: Edge Function.

- Luu `service_role` trong Supabase secret.
- Bao ve function bang secret/admin check.
- Khong goi truc tiep tu public frontend neu chua co co che xac thuc/phan quyen rieng.

## Cau hinh Storage

Migration `0003_storage.sql` tao 2 bucket:

1. `evidence-files`: private, file minh chung, khong public URL.
2. `app-assets`: public, logo/tai san khong nhay cam.

Neu Supabase SQL Editor bao `must be owner of relation objects`, ban dang khong chay bang role owner cua `storage.objects`. Ban van giu nguyen pham vi L1: tao bucket bang migration, sau do tao policy tu Supabase Storage Policies UI theo dung logic trong `0003_storage.sql`, hoac chay lai phan policy bang role co quyen owner.

Path evidence de xuat:

```text
contest_id/user_id/submission_id/version.ext
```

Khi upload evidence o L2:

- Lan nop dau can tao UUID cho `submission_id` truoc khi upload Storage va truyen UUID nay vao RPC `submit_evidence`; lan nop lai dung lai `submission_id` hien co.
- `user_id` trong path phai bang `auth.uid()`.
- `version.ext` nen la so tang dan, vi policy yeu cau filename dang `1.jpg`, `2.png`, ...
- Metadata upload phai co `file_type` khop extension path, vi Storage policy validate `metadata.file_type`.
- Mac dinh chi cho `jpg`, `jpeg`, `png`, `webp`.
- PDF dang duoc de san trong schema nhung Storage policy mac dinh chua cho upload PDF.
- Kiem MIME that cua file se xu ly them o L2 bang browser API va/hoac Edge Function L2/L3; L1 chi validate extension/path va declared `file_type`.

Luu y quan trong: upload Storage xay ra truoc khi goi RPC `submit_evidence`. Neu upload thanh cong nhung `submit_evidence` loi, co the phat sinh object mo coi trong bucket. L2 can thu xoa object vua upload neu chua duoc ghi vao `submission_files`; neu khong xoa duoc thi nguoi van hanh cleanup thu cong hoac L2/L3 bo sung Edge Function cleanup.

## Bien moi truong du kien cho L2/provisioning

Frontend L2:

```text
VITE_SUPABASE_URL=<project-url>
VITE_SUPABASE_ANON_KEY=<anon-key>
VITE_LOGIN_HASH_SALT=<salt-neu-dung-hash-internal-email>
```

Provisioning/admin only:

```text
SUPABASE_SERVICE_ROLE_KEY=<service-role-key-khong-dua-vao-frontend>
INITIAL_PASSWORD=<mat-khau-ban-dau-khong-commit>
```

## Cach test nhanh RLS

SQL Editor chay bang owner co the bypass RLS, nen nen test them qua Supabase client/API voi anon key va user dang nhap. Neu can test trong SQL Editor, co the mo transaction va gia lap role/JWT:

```sql
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', '<AUTH_USER_UUID>', true);

select * from public.profiles;
select * from public.submissions;
select * from public.get_admin_dashboard('00000000-0000-0000-0000-000000000401');

rollback;
```

Test public aggregate:

```sql
select * from public.get_public_dashboard(null);
```

Ky vong:

- Anonymous/authenticated khong select truc tiep duoc bang chi tiet ngoai policy.
- User thuong chi xem profile/submission/file/event cua minh.
- Nguoi duyet chi xem submission/file trong scope va step hop le.
- Client khong update truc tiep status, approval step, approval action hoac audit log.

## RPC chinh

- `get_public_dashboard(contest_id uuid)`: aggregate an danh cho public.
- `get_admin_dashboard(contest_id uuid)`: aggregate theo scope cua `auth.uid()`.
- `submit_evidence(contest_id, storage_path, file_type, file_size_kb, submission_id, note)`: tao/cap nhat submission va file hien hanh.
- `approve_submission(submission_id, note)`: phe duyet step hien tai.
- `reject_submission(submission_id, reason, note)`: tu choi step hien tai.

Trong `submit_evidence`, migration da thuc hien dung thu tu:

1. Kiem tra user, contest, participant, file type/path, file size.
2. Tao/cap nhat submission.
3. Xoa snapshot duyet cu neu gui lai.
4. Tinh `version_number` moi.
5. Update file cu `is_current = false`.
6. Insert file moi `is_current = true`.
7. Snapshot approval flow/step/approver.
8. Ghi `submission_events` va `audit_logs`.

Thu tu update file cu truoc roi insert file moi giup khong vi pham unique partial index `(submission_id) where is_current = true`.

## Backup/export thu cong

Free tier co the khong co backup tu dong phu hop. Truoc khi van hanh that:

1. Kiem tra lai pricing/limits hien hanh cua Supabase, Cloudflare Pages hoac Netlify.
2. Lap lich export database thu cong qua Dashboard hoac `pg_dump`.
3. Export bao cao sau moi dot thi.
4. Kiem tra dung luong Storage va co quy trinh archive/cleanup file cu.

## Ghi chu thoi gian

Database luu thoi gian bang `timestamptz`. UI va bao cao L2/L3 can hien thi theo `Asia/Ho_Chi_Minh`.
