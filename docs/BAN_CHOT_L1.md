# BẢN CHỐT L1 - NỀN MÓNG KỸ THUẬT

## 1. Thông tin chung

- Tên dự án: TheoDoiThiTrucTuyen
- Giai đoạn: L1 - Nền móng kỹ thuật
- Phạm vi: Supabase schema, RLS, RPC, Storage policy, seed data, tài liệu kỹ thuật
- Trạng thái: Hoàn thành kiểm tra ban đầu
- L1 chưa bao gồm giao diện người dùng, React app, upload UI, dashboard frontend, login frontend.

## 2. Mục tiêu L1 đã hoàn thành

- Kiến trúc free-tier first.
- Tạo cấu trúc `docs/`, `supabase/migrations/`, `supabase/seed/`.
- Tạo schema PostgreSQL/Supabase.
- Tạo RLS policies.
- Tạo RPC cốt lõi.
- Tạo Storage bucket/policies.
- Tạo seed dev.
- Tạo README và tài liệu bảo mật/free-tier/next steps.
- Tạo Super Admin đầu tiên trên Supabase.
- Đồng bộ migration sau kiểm tra thực tế.

## 3. Thành phần đã bàn giao

- `README.md`
- `docs/ARCHITECTURE_L1.md`
- `docs/ASSUMPTIONS.md`
- `docs/SECURITY_NOTES.md`
- `docs/FREE_TIER_NOTES.md`
- `docs/NEXT_STEPS.md`
- `docs/PROVISION_DEV_USERS.md`: không có trong repo hiện tại.
- `supabase/migrations/0001_schema.sql`
- `supabase/migrations/0002_rls.sql`
- `supabase/migrations/0003_storage.sql`
- `supabase/seed/seed_dev.sql`

Ghi chú: `docs/PROVISION_DEV_USERS.md` không tồn tại trong repo tại thời điểm chốt L1. Hướng dẫn tạo Super Admin/provision user đang được ghi trong `README.md` và `SECURITY_NOTES.md`.

## 4. Kết quả kiểm tra nghiệm thu L1

| STT | Nội dung kiểm tra | Kết quả | Ghi chú |
| --- | --- | --- | --- |
| 1 | Supabase database chạy được | Đạt | Đã kiểm tra thực tế trên Supabase. |
| 2 | Super Admin đã tạo | Đạt | Đã tạo trên Supabase, không ghi mật khẩu trong repo. |
| 3 | RLS/RPC/Storage đã kiểm tra | Đạt | Đã kiểm tra thực tế và có migration tương ứng. |
| 4 | Migration đã đồng bộ lại | Đạt | `0001_schema.sql`, `0002_rls.sql`, `0003_storage.sql` đã được đồng bộ sau kiểm tra. |
| 5 | GitHub đã commit | Đạt | Theo trạng thái kiểm tra thực tế đã xác nhận. |
| 6 | `user_scopes` có `scope_kind` | Đạt | Có check `all`, `unit`, `user`. |
| 7 | `contests` có `resubmit_mode` | Đạt | Có check `restart_from_step_1`, `restart_from_rejected_step`. |
| 8 | Có RPC `submit_evidence` | Đạt | Có trong `0002_rls.sql`. |
| 9 | Có RPC `approve_submission` | Đạt | Có trong `0002_rls.sql`. |
| 10 | Có RPC `reject_submission` | Đạt | Có trong `0002_rls.sql`. |
| 11 | Có `get_public_dashboard(null)` | Đạt | RPC hỗ trợ tham số null/default và README có câu lệnh test. |
| 12 | Có bucket `evidence-files` private | Đạt | Có trong `0003_storage.sql`. |
| 13 | Có unique partial index `submission_files_one_current_idx` | Đạt | Có trong `0001_schema.sql`. |
| 14 | Có seed role/units/contest/approval flow/rejection reasons | Đạt | Có trong `seed_dev.sql`. |
| 15 | Không tạo UI/frontend trong L1 | Đạt | Repo L1 chỉ có tài liệu và Supabase SQL. |

## 5. Các điểm đã chỉnh sau kiểm tra thực tế

- Bổ sung/đồng bộ `resubmit_mode` và các cột upload/resubmit trong bảng `contests`.
- Bổ sung/đồng bộ `scope_kind` trong `user_scopes`.
- Cập nhật RPC/RLS để dùng `scope_kind = 'all'` thay vì suy luận mơ hồ `unit_id is null`.
- Đồng bộ `seed_dev.sql` để có cả `restart_from_step_1` và `restart_from_rejected_step`.
- Ghi nhận object mồ côi Storage là vấn đề xử lý thủ công hoặc L2/L3 bằng Edge Function/job phù hợp.

## 6. Giới hạn còn lại sau L1

- Chưa có giao diện người dùng.
- Chưa có React/Vite frontend.
- Chưa có login CCCD trên UI.
- Chưa có upload minh chứng trên UI.
- Chưa có dashboard frontend.
- Chưa có màn hình duyệt.
- Chưa có xuất báo cáo Excel/PDF.
- Chưa có import danh sách người dùng.
- Chưa có Edge Function cleanup object mồ côi.

## 7. Điều kiện cho phép chuyển sang L2

- L1 đã được commit lên GitHub.
- Supabase project hiện tại chạy được migration/seed đã kiểm tra.
- Super Admin đầu tiên đã tạo.
- Các RPC/RLS/Storage cơ bản đã tồn tại.
- Ban quản trị/phụ trách dự án chấp thuận phạm vi L2.

## 8. Kết luận

L1 đã hoàn thành phần nền móng kỹ thuật của dự án TheoDoiThiTrucTuyen. Các thành phần database, phân quyền, RPC, Storage, seed và tài liệu vận hành cơ bản đã được bàn giao. L1 đủ điều kiện để chuyển sang L2 sau khi được phê duyệt chính thức.

Dừng tại đây - chờ phê duyệt L1 trước khi sang L2.
