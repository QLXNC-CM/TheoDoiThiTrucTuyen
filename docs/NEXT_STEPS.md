FILE: docs/NEXT_STEPS.md

# Next Steps

## L2 du kien

1. Tao React + Vite + TypeScript app.
2. Cau hinh Supabase client chi dung anon key.
3. Dang nhap bang CCCD: chuan hoa CCCD, suy ra internal email, goi Supabase Auth.
4. Doi mat khau lan dau theo `profiles.force_password_change`.
5. Public dashboard aggregate bang RPC `get_public_dashboard`.
6. Trang nguoi dung xem cuoc thi duoc gan va trang thai submission.
7. Client-side image compression truoc khi upload.
8. Tao UUID `submission_id` truoc lan nop dau de dua vao Storage path, hoac dung lai `submission_id` hien co khi nop lai.
9. Upload minh chung len Storage private theo path `contest_id/user_id/submission_id/version.ext`.
10. Metadata upload phai co `file_type` khop voi extension trong path; MIME that cua file can kiem tra bang browser API truoc khi upload.
11. Xac thuc lai mat khau bang Supabase Auth truoc khi goi `submit_evidence`.
12. Goi RPC `submit_evidence` sau upload Storage.
13. Xu ly object mo coi: neu upload thanh cong nhung `submit_evidence` loi, frontend can thu xoa object vua upload neu con quyen; neu khong xoa duoc thi ghi huong dan cleanup thu cong.
14. Hien thi lich su `submission_events` cho user trong pham vi duoc phep.

## L3 du kien

1. UI quan ly approval flow builder.
2. UI duyet nhieu cap va hang doi phe duyet theo scope.
3. UI quan ly tai khoan, role va scope.
4. UI quan ly don vi, participant group va contest participants.
5. Import CSV/Excel cho users, units va contest participants.
6. Export Excel/PDF cho bao cao summary, detail va approver stats.
7. Cong cu cleanup object mo coi trong Storage bang Edge Function hoac man hinh admin.
8. Kiem tra MIME that nang cao o Edge Function neu yeu cau bao mat cao hon browser-only validation.
9. Them logging IP/user-agent tin cay hon neu di qua Edge Function.

## Cau hoi can chot

1. Co luu `citizen_id_encrypted` hay chi dung hash + last4?
2. Chon cach tao internal email nao cho Supabase Auth?
3. Co bat PDF evidence khong?
4. Deadline co khoa nop moi/gui lai hay chi danh dau trang thai suy ra?
5. Co xoa file cu sau khi gui lai khong, hay giu de doi soat?
6. Cleanup object mo coi thuc hien thu cong, Edge Function, hay UI admin L3?
7. Danh sach phong/doi/to va role thuc te can seed/provision ra sao?
8. Bao cao L3 can mau cot nao va co hien CCCD che bot theo dinh dang nao?
