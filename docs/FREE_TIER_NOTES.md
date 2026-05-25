FILE: docs/FREE_TIER_NOTES.md

# Free Tier Notes L1

## Nguyen tac tiet kiem tai nguyen

- Khong dung server rieng, VPS, database tra phi hoac API tra phi trong MVP.
- Frontend L2 nen deploy static tren Cloudflare Pages Free hoac Netlify Free.
- Supabase Free dung cho Auth, PostgreSQL, RLS, RPC va Storage.
- Dashboard nen doc aggregate qua RPC thay vi tai toan bo du lieu chi tiet.
- Khong upload video.
- Anh minh chung phai nen o client trong L2, mac dinh sau nen toi da 500 KB den 1 MB.
- Bucket `evidence-files` mac dinh chi chap nhan `jpg`, `jpeg`, `png`, `webp`; PDF de tat tru khi duoc phe duyet.
- Moi nguoi dung moi cuoc thi chi co mot file minh chung hien hanh; metadata file cu duoc danh dau khong hien hanh. Mac dinh `keep_old_files = false`, viec xoa object vat ly se do L2/L3 xu ly sau khi RPC thanh cong.

## Luu y backup/export thu cong

- Free tier co the khong co backup tu dong phu hop cho production.
- Truoc moi dot thi quan trong, nguoi van hanh nen export schema/data tu Supabase Dashboard hoac `pg_dump`.
- Sau moi dot thi, nen export bao cao va backup database thu cong.
- Storage evidence nen duoc kiem tra dung luong dinh ky; neu can luu tru dai han, can co quy trinh archive.

## Can kiem tra pricing/limits tai thoi diem deploy

Gioi han cua Supabase, Cloudflare Pages va Netlify co the thay doi theo thoi gian. Truoc khi deploy production, nguoi van hanh phai kiem tra lai:

1. Gioi han database size.
2. Gioi han Storage va bandwidth.
3. Gioi han Auth monthly active users.
4. Gioi han Edge Functions neu L2/L3 dung cleanup hoac provisioning.
5. Gioi han build/deploy cua Cloudflare Pages hoac Netlify.

## Rui ro vuot free tier

- Upload anh goc dung luong lon khong nen o client.
- Luu file cu qua lau ma khong co quy trinh archive.
- Dashboard/admin query quet toan bo bang lon thay vi aggregate/index.
- Import du lieu hang loat sai lap tao nhieu submission/file/event thua.
- Bat PDF khi chua co gioi han dung luong va MIME validation chat.
