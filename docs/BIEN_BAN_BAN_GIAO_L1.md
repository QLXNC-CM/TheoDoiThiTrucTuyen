# BIÊN BẢN BÀN GIAO L1 - DỰ ÁN THEODÕITHITRUCTUYEN

## 1. Thông tin bàn giao

- Tên dự án: TheoDoiThiTrucTuyen
- Giai đoạn bàn giao: L1 - Nền móng kỹ thuật
- Bên bàn giao: Nhóm/AI hỗ trợ triển khai kỹ thuật
- Bên tiếp nhận: Chủ dự án/người vận hành hệ thống
- Ngày bàn giao: [ĐIỀN NGÀY BÀN GIAO]
- Repository GitHub: [ĐIỀN LINK GITHUB]
- Supabase project: [ĐIỀN TÊN/LINK PROJECT SUPABASE NẾU CẦN]

## 2. Phạm vi bàn giao

L1 bàn giao:

- Tài liệu kiến trúc.
- Database schema.
- Constraints/indexes/triggers.
- RLS policies.
- RPC bảo mật.
- Storage buckets/policies.
- Seed data dev.
- README vận hành.
- Hướng dẫn tạo Super Admin/provision user.

L1 không bàn giao:

- Frontend React.
- UI dashboard.
- UI login.
- UI upload.
- UI duyệt.
- Báo cáo Excel/PDF.
- Import CSV/Excel.
- Edge Function production.

## 3. Danh mục file bàn giao

| STT | Đường dẫn file | Mục đích | Trạng thái |
| --- | --- | --- | --- |
| 1 | `README.md` | Hướng dẫn chạy L1, cấu hình Supabase, Auth, Storage và vận hành cơ bản. | Đã bàn giao |
| 2 | `docs/ARCHITECTURE_L1.md` | Mô tả kiến trúc free-tier first và phân tách L1/L2/L3. | Đã bàn giao |
| 3 | `docs/ASSUMPTIONS.md` | Ghi nhận giả định thiết kế và điểm cần phê duyệt. | Đã bàn giao |
| 4 | `docs/SECURITY_NOTES.md` | Ghi chú bảo mật về CCCD, Auth, service role, RLS/RPC, Storage. | Đã bàn giao |
| 5 | `docs/FREE_TIER_NOTES.md` | Ghi chú giới hạn free tier, backup/export thủ công và lưu ý vận hành. | Đã bàn giao |
| 6 | `docs/NEXT_STEPS.md` | Danh sách việc dự kiến cho L2/L3 và câu hỏi cần chốt. | Đã bàn giao |
| 7 | `docs/BAN_CHOT_L1.md` | Bản chốt nghiệm thu L1. | Đã bàn giao |
| 8 | `docs/BIEN_BAN_BAN_GIAO_L1.md` | Biên bản bàn giao kỹ thuật L1. | Đã bàn giao |
| 9 | `supabase/migrations/0001_schema.sql` | Schema, constraints, indexes, triggers và đồng bộ cấu trúc L1 cuối cùng. | Đã bàn giao |
| 10 | `supabase/migrations/0002_rls.sql` | RLS policies, helper functions và RPC bảo mật. | Đã bàn giao |
| 11 | `supabase/migrations/0003_storage.sql` | Storage buckets và Storage policies. | Đã bàn giao |
| 12 | `supabase/seed/seed_dev.sql` | Seed dev cho role, units, contests, approval flow và rejection reasons. | Đã bàn giao |

## 4. Danh mục thành phần database đã bàn giao

### 4.1. Người dùng và phân quyền

- `profiles`
- `roles`
- `user_roles`
- `units`
- `user_scopes`
- `participant_groups`

### 4.2. Cấu hình và cuộc thi

- `app_settings`
- `contests`
- `contest_participants`

### 4.3. Quy trình duyệt

- `approval_flows`
- `approval_steps`
- `approval_step_roles`
- `approval_step_assignees`

### 4.4. Nộp minh chứng và lịch sử

- `submissions`
- `submission_files`
- `submission_approval_steps`
- `submission_step_approvers`
- `approval_actions`
- `submission_events`

### 4.5. Audit và báo cáo

- `audit_logs`
- `report_exports`
- `rejection_reason_templates`

## 5. Danh mục RPC/helper đã bàn giao

| RPC/helper | Mục đích |
| --- | --- |
| `is_super_admin` | Kiểm tra người dùng có vai trò Super Admin hay không. |
| `has_role` | Kiểm tra người dùng có một role cụ thể hay không. |
| `unit_is_descendant` | Kiểm tra quan hệ cấp dưới/cấp trên trong cây đơn vị. |
| `user_has_scope` | Kiểm tra quyền theo `scope_type`, `scope_kind`, đơn vị và cuộc thi. |
| `can_view_profile` | Kiểm tra quyền xem hồ sơ người dùng. |
| `can_view_submission` | Kiểm tra quyền xem submission và file liên quan. |
| `can_approve_submission` | Kiểm tra quyền duyệt submission tại bước hiện tại. |
| `get_public_dashboard` | Trả aggregate công khai đã ẩn danh cho dashboard public. |
| `get_admin_dashboard` | Trả aggregate theo phạm vi quyền của tài khoản quản trị/duyệt. |
| `submit_evidence` | Tạo/cập nhật submission, file minh chứng, snapshot quy trình duyệt và audit/event. |
| `approve_submission` | Ghi nhận phê duyệt, chuyển bước hoặc hoàn tất duyệt. |
| `reject_submission` | Ghi nhận từ chối, lý do từ chối và cập nhật trạng thái submission. |
| `log_audit` | Ghi audit log cho hành động nhạy cảm. |

## 6. Danh mục kiểm tra đã thực hiện

| Nội dung kiểm tra | Kết quả | Ghi chú |
| --- | --- | --- |
| Database chạy được | Đạt | Đã kiểm tra thực tế trên Supabase. |
| `user_scopes` có `scope_kind` | Đạt | Có check `all`, `unit`, `user`. |
| `contests` có `resubmit_mode` | Đạt | Có đủ `restart_from_step_1` và `restart_from_rejected_step`. |
| RPC tồn tại | Đạt | Có RPC/helper cốt lõi trong `0002_rls.sql`. |
| Storage bucket tồn tại | Đạt | Có `evidence-files` và `app-assets`. |
| `evidence-files` private | Đạt | Bucket được cấu hình private trong migration. |
| Super Admin đã tạo | Đạt | Đã tạo trên Supabase theo kiểm tra thực tế. |
| GitHub đã commit | Đạt | Theo trạng thái chốt L1 đã xác nhận. |
| Migration đã đồng bộ lại | Đạt | Đã cập nhật theo kiểm tra thực tế. |
| Không tạo UI/frontend | Đạt | L1 chỉ bàn giao tài liệu và nền tảng Supabase. |

## 7. Tài khoản Super Admin đầu tiên

- Đã tạo Super Admin đầu tiên trên Supabase.
- Không ghi mật khẩu thật.
- Không ghi `service_role` key.
- Email: [ĐIỀN EMAIL SUPER ADMIN]
- User UID: [ĐIỀN USER UID NẾU MUỐN]
- Cảnh báo: mật khẩu và secret phải lưu ngoài repository.

## 8. Rủi ro và lưu ý vận hành

- Free tier cần theo dõi giới hạn Supabase/hosting.
- Cần backup/export thủ công theo README.
- Không đưa `service_role` key lên frontend/GitHub.
- Storage upload xảy ra trước `submit_evidence` nên có thể phát sinh object mồ côi.
- MIME thật của file sẽ kiểm thêm ở L2/frontend hoặc Edge Function giai đoạn sau.
- RLS/RPC cần test lại khi bổ sung UI L2.
- Các tài khoản thật phải tạo theo quy trình provisioning, không hard-code mật khẩu.

## 9. Điều kiện chuyển sang L2

L2 chỉ bắt đầu sau khi:

- Biên bản L1 được xác nhận.
- Repo GitHub đã có toàn bộ file L1.
- Supabase đã chạy ổn.
- Super Admin đầu tiên đã tạo.
- Chủ dự án chấp nhận giới hạn L1.

## 10. Xác nhận bàn giao

Bên bàn giao:

- Họ tên:
- Vai trò:
- Ngày:

Bên tiếp nhận:

- Họ tên:
- Vai trò:
- Ngày:

## 11. Kết luận

L1 đã hoàn thành phần nền móng kỹ thuật của dự án TheoDoiThiTrucTuyen, đủ điều kiện để lập kế hoạch L2 sau khi được xác nhận. Tài liệu này không triển khai L2 và không bao gồm giao diện người dùng/frontend.

Dừng tại đây - chờ phê duyệt L1 trước khi sang L2.
