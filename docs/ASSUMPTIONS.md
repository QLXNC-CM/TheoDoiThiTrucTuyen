FILE: docs/ASSUMPTIONS.md

# Assumptions L1

## Gia dinh da ap dung

1. Schema phai ho tro nhieu cuoc thi trong lich su, khong xoa du lieu cu khi tao cuoc thi moi.
2. Co the co nhieu cuoc thi `active` cung luc; dashboard public mac dinh chon cuoc thi active gan deadline nhat neu caller khong truyen `contest_id`.
3. Toan bo thoi gian trong database dung `timestamptz`; UI va bao cao L2/L3 hien thi theo `Asia/Ho_Chi_Minh`.
4. Don vi co cau truc cay: phong/ban > doi/to > nhom neu can.
5. `profiles.primary_unit_id` tro den don vi truc tiep nho nhat cua nguoi dung. Phong/ban cap tren duoc suy ra bang `units.parent_id` va helper `unit_is_descendant`.
6. `participant_group` la danh muc do admin cau hinh, khong hard-code trong ung dung. Seed dev tao mau `CAN_BO`, `CHI_HUY`, `DOAN_VIEN`, `CHIEN_SI`, `KHAC`.
7. `NOT_SUBMITTED`, `EXPIRED_NOT_SUBMITTED`, `EXPIRED_PENDING` la trang thai suy ra khi query/dashboard, khong luu thanh row trong `submissions`.
8. `ALL_REQUIRED` chi ap dung cho tat ca nguoi duoc gan cu the trong snapshot `submission_step_approvers`; khong hieu la tat ca user co role trong scope.
9. Step `ALL_REQUIRED` khong co assignee cu the la cau hinh khong hop le; RPC `submit_evidence` se raise exception.
10. Khi nguoi dung gui lai sau khi bi tu choi, quy trinh duyet mac dinh chay lai tu buoc 1 va snapshot lai active flow hien tai.
11. Public/anonymous chi xem aggregate an danh qua RPC `get_public_dashboard`, khong xem danh sach chi tiet.
12. Mot cuoc thi chi co mot approval flow active tai mot thoi diem; cac flow cu duoc giu lai bang `version` va `is_active = false`.
13. Moi nguoi dung trong mot cuoc thi chi co mot row `submissions`; cac lan gui lai duoc luu bang event, version file va snapshot duyet moi.
14. Moi submission chi co mot file minh chung hien hanh tai mot thoi diem, enforced bang unique partial index tren `submission_files`.
15. Khi thay file hien hanh, RPC `submit_evidence` update cac file cu `is_current = false` truoc, sau do moi insert file moi `is_current = true`.
16. File minh chung cho phep mac dinh `jpg`, `jpeg`, `png`, `webp`; `pdf` co cot/schema du phong nhung mac dinh tat bang setting va policy.
17. Storage policy kiem tra extension trong path khop voi `metadata.file_type`; viec kiem MIME that cua file se bo sung o frontend L2 va/hoac Edge Function L2/L3.
18. Upload Storage xay ra truoc khi goi `submit_evidence`, nen co nguy co object mo coi neu upload thanh cong nhung RPC loi.
19. Cleanup object mo coi se xu ly thu cong trong MVP hoac bang Supabase Edge Function/job nhe o L2/L3.
20. Seed data L1 khong tao auth users vi can Admin API/service_role hoac Supabase Dashboard rieng.
21. Mat khau ban dau neu provisioning user phai dung placeholder `[INITIAL_PASSWORD]` hoac bien moi truong, khong commit gia tri that.
22. `service_role` chi dung trong moi truong admin/provisioning/Edge Function secret, khong co trong frontend.
23. Super Admin co quyen toan he thong; IT Admin chi nen duoc cap scope phu hop neu can xem audit/ho tro ky thuat.
24. Bao cao chi tiet va export file se lam o L3; L1 chi tao bang `report_exports` de ghi nhan lich su export.

## Can phe duyet truoc L2

1. Cach tao internal email tu CCCD: hash CCCD + salt hay dung dinh danh noi bo khac.
2. Chinh sach co luu `citizen_id_encrypted` hay khong; L1 de cot nullable va khong dung mac dinh.
3. Gioi han dung luong file sau nen: mac dinh 1024 KB, co the ha xuong 500 KB neu can tiet kiem Storage.
4. Co cho phep PDF hay khong; L1 mac dinh tat PDF.
5. Chinh sach giu/xoa file cu sau khi nguoi dung gui lai; L1 dat mac dinh `keep_old_files = false`, neu can giu lich su file vat ly thi phai bat theo tung cuoc thi.
6. Phuong an cleanup object mo coi: thao tac thu cong, Edge Function co lich, hay nut cleanup admin o L3.
7. Danh sach role/scope thuc te cua don vi va mapping chinh xac phong/doi/to.
8. Quy dinh deadline: sau deadline co cho nop lai hay khong.
9. Yeu cau audit log them IP/user-agent se lay tu frontend hay Edge Function.
