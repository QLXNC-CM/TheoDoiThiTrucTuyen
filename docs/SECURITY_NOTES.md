FILE: docs/SECURITY_NOTES.md

# Security Notes L1

## CCCD va du lieu nhay cam

- Khong luu CCCD plaintext trong bang public schema theo mac dinh.
- `profiles.citizen_id_hash` dung de doi chieu duy nhat.
- `profiles.citizen_id_last4` dung de hien thi rut gon.
- `profiles.citizen_id_encrypted` de san nhung nullable; chi dung khi co phuong an ma hoa, quan ly khoa va RPC doc dac biet duoc phe duyet.
- Bao cao mac dinh chi hien thi CCCD che bot, khong tra CCCD day du qua select thong thuong.
- Internal email nen duoc tao tu hash dinh danh, vi dung `citizen_id@internal.local` se lam CCCD xuat hien trong Supabase Auth email.

## Auth va mat khau

- Supabase Auth quan ly mat khau; bang ung dung khong luu mat khau.
- Public signup phai tat trong Supabase Dashboard.
- Tai khoan noi bo tao bang Supabase Dashboard, script provisioning local/CI, hoac Edge Function dung `service_role` trong secret.
- Email confirmation nen tat cho tai khoan noi bo, hoac Admin API tao user voi `email_confirm: true`.
- Neu co mat khau ban dau, chi ghi placeholder `[INITIAL_PASSWORD]` hoac lay tu bien moi truong provisioning.
- Khi submit ket qua o L2, frontend phai xac thuc lai mat khau bang Supabase Auth `signInWithPassword` cua chinh user hien tai; khong so sanh mat khau o client va khong luu mat khau de so sanh.

## Service role

- `service_role` khong duoc dua vao frontend, source public, local storage, browser logs hoac bien moi truong Vite.
- `service_role` chi duoc dung trong script admin chay local/CI rieng hoac Supabase Edge Function secret.
- Frontend chi dung `VITE_SUPABASE_URL` va `VITE_SUPABASE_ANON_KEY`.

## RLS va RPC

- RLS bat cho tat ca bang nhay cam.
- Client khong duoc update truc tiep cac cot/trang thai nhay cam: `submissions.current_status`, `submissions.current_step_order`, `approval_actions`, `submission_approval_steps.status`, `submission_step_approvers.status`, `audit_logs`.
- Cac hanh dong nhay cam di qua RPC `submit_evidence`, `approve_submission`, `reject_submission`.
- RPC dung `security definer` va `set search_path = public, pg_temp`.
- RPC luon kiem tra `auth.uid()`, role, scope, step hien tai va ghi `submission_events`/`audit_logs`.
- Public dashboard chi tra aggregate an danh, khong tra danh sach user/submission.

## Storage private

- Bucket `evidence-files` private, khong public URL.
- Path de xuat: `contest_id/user_id/submission_id/version.ext`.
- Policy upload yeu cau user_id trong path bang `auth.uid()`.
- Policy upload validate extension trong path khop voi `metadata.file_type`.
- Kiem MIME that cua file se xu ly them o frontend L2 va co the them Edge Function L2/L3 vi Storage metadata co the bi client khai sai.
- Nguoi duyet chi xem file neu `can_view_submission(auth.uid(), submission_id)` tra true.
- Co nguy co object mo coi neu upload Storage thanh cong nhung `submit_evidence` loi; README va NEXT_STEPS da ghi can cleanup thu cong hoac Edge Function.

## Audit log

- `submission_events` ghi lich su theo submission cho nguoi dung/nguoi duyet xem trong pham vi.
- `audit_logs` ghi hanh dong nhay cam cap he thong, chi Super Admin hoac IT Admin phu hop duoc xem.
- L1 de cot `ip_address` va `user_agent` nullable. L2/L3 can quyet dinh cach thu thap an toan va hop le.
