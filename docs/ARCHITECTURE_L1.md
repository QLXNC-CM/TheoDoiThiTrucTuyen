FILE: docs/ARCHITECTURE_L1.md

# Architecture L1

## Muc tieu L1

L1 chi tao nen mong ky thuat cho he thong theo doi ket qua thi truc tuyen noi bo. Pham vi bao gom kien truc tong the, Supabase schema, migration SQL, RLS, RPC, Storage policies, seed data va tai lieu van hanh. L1 khong tao React app, khong tao UI, khong tao frontend, khong tao dashboard va khong tao chuc nang upload tren client.

## Kien truc free-tier first

He thong duoc thiet ke theo huong tinh gon de chay trong free tier voi quy mo mac dinh duoi 200 nguoi dung, khoang 50 tai khoan quan tri/phe duyet va du lieu minh chung chu yeu la anh da nen.

Thanh phan du kien:

1. Supabase Auth: quan ly tai khoan noi bo bang email/password an sau lop dang nhap bang CCCD o L2.
2. Supabase PostgreSQL: luu ho so, don vi, cuoc thi, phan quyen, quy trinh duyet, submission, audit log va cau hinh.
3. Supabase RLS/RPC: chan truy cap truc tiep vao du lieu nhay cam va gom logic nhay cam vao cac function server-side.
4. Supabase Storage: luu file minh chung trong bucket private `evidence-files`; logo/tai san cong khai trong `app-assets`.
5. Frontend L2: React + Vite + TypeScript, deploy Cloudflare Pages Free hoac Netlify Free.
6. Admin/provisioning: tao user ban dau bang Supabase Dashboard, script local/CI dung `service_role`, hoac Edge Function co secret rieng. `service_role` khong bao gio dua vao frontend.

## Ly do chon Supabase va Cloudflare Pages/Netlify

Supabase phu hop L1 vi gom Auth, PostgreSQL, RLS, RPC va Storage trong mot nen tang, giam nhu cau server rieng. PostgreSQL cung cap constraint, trigger, transaction va function de xu ly approval workflow atomic. RLS giup bao ve du lieu theo user, role va scope ngay tai database.

Cloudflare Pages hoac Netlify phu hop cho L2 vi frontend co the la static SPA, khong can server tra phi. Frontend chi su dung anon key va goi Supabase client/RPC theo RLS.

## Luong du lieu tong quat

1. Super Admin tao don vi, nhom doi tuong, tai khoan, role, scope va cuoc thi.
2. Admin cau hinh `approval_flows`, `approval_steps`, `approval_step_roles` va neu can thi gan `approval_step_assignees`.
3. Nguoi dung dang nhap bang CCCD o L2. CCCD duoc chuan hoa de suy ra internal email; mat khau xac thuc qua Supabase Auth.
4. Nguoi dung tai file minh chung len Storage private theo path `contest_id/user_id/submission_id/version.ext`.
5. Frontend goi RPC `submit_evidence`. RPC kiem tra `auth.uid()`, contest participant, file type/path, tao hoac cap nhat submission, snapshot flow/step/approver, cap nhat file hien hanh va ghi event/audit.
6. Nguoi duyet goi RPC `approve_submission` hoac `reject_submission`. RPC kiem tra role + scope + step hien tai, ghi action/event/audit va chuyen buoc duyet trong transaction.
7. Dashboard public chi doc aggregate an danh qua RPC `get_public_dashboard`, khong select truc tiep bang chi tiet.
8. Dashboard admin doc aggregate theo scope qua RPC `get_admin_dashboard`.

## Phan tach L1, L2, L3

L1:

- Database schema, constraints, indexes, trigger `updated_at`.
- RLS policies cho cac bang nhay cam.
- RPC cho phan quyen, dashboard aggregate va hanh dong nhay cam.
- Storage buckets va policies.
- Seed data dev/test toi thieu.
- Tai lieu kien truc, bao mat, free tier va buoc tiep theo.

L2:

- React + Vite + TypeScript app.
- Dang nhap bang CCCD an internal email.
- Doi mat khau lan dau.
- Public dashboard aggregate.
- Trang nop ket qua cua nguoi dung.
- Client-side image compression.
- Upload Storage va goi `submit_evidence`.
- Xac thuc lai mat khau truoc khi submit.
- Xu ly cleanup object mo coi neu upload thanh cong nhung `submit_evidence` loi.

L3:

- UI quan tri approval flow builder.
- Man hinh duyet nhieu cap.
- Quan ly tai khoan, don vi, scope.
- Import CSV/Excel.
- Bao cao Excel/PDF.
- Thong ke nguoi duyet va lich su phe duyet nang cao.

## Nguyen tac bao mat chinh

- Khong luu mat khau trong bang ung dung.
- Khong luu CCCD plaintext mac dinh; chi luu hash va last4, truong encrypted de trong neu chua co phuong an ma hoa ro.
- Khong dua `service_role` vao frontend.
- Khong cho client update truc tiep status, approval action, approval step status hoac audit log.
- File minh chung nam trong private bucket, truy cap qua Storage policy hoac signed URL sau khi kiem tra quyen.
- Moi thay doi nhay cam phai di qua RPC va ghi `submission_events`/`audit_logs`.
