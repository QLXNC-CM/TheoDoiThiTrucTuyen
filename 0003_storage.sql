-- FILE: supabase/migrations/0003_storage.sql

begin;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'evidence-files',
  'evidence-files',
  false,
  1048576,
  array[
    'image/jpeg',
    'image/png',
    'image/webp'
  ]
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'app-assets',
  'app-assets',
  true,
  524288,
  array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/svg+xml'
  ]
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy evidence_files_select_scoped
on storage.objects
for select
to authenticated
using (
  bucket_id = 'evidence-files'
  and (
    public.is_super_admin(auth.uid())
    or ((storage.foldername(name))[2])::uuid = auth.uid()
    or exists (
      select 1
      from public.submission_files sf
      where sf.storage_path = storage.objects.name
        and public.can_view_submission(auth.uid(), sf.submission_id)
    )
  )
);

create policy evidence_files_insert_own_valid_extension
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'evidence-files'
  and array_length(storage.foldername(name), 1) = 3
  and ((storage.foldername(name))[1])::uuid is not null
  and ((storage.foldername(name))[2])::uuid = auth.uid()
  and ((storage.foldername(name))[3])::uuid is not null
  and lower(storage.filename(name)) ~ '^[0-9]+[.](jpg|jpeg|png|webp)$'
  and lower(coalesce(metadata ->> 'file_type', '')) in ('jpg', 'jpeg', 'png', 'webp')
  and public.evidence_file_type_matches_path(name, metadata ->> 'file_type')
);

create policy evidence_files_delete_own_unregistered
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'evidence-files'
  and ((storage.foldername(name))[2])::uuid = auth.uid()
  and not exists (
    select 1
    from public.submission_files sf
    where sf.storage_path = storage.objects.name
  )
);

create policy evidence_files_super_admin_all
on storage.objects
for all
to authenticated
using (
  bucket_id = 'evidence-files'
  and public.is_super_admin(auth.uid())
)
with check (
  bucket_id = 'evidence-files'
  and public.is_super_admin(auth.uid())
);

create policy app_assets_public_read
on storage.objects
for select
to anon, authenticated
using (
  bucket_id = 'app-assets'
);

create policy app_assets_super_admin_all
on storage.objects
for all
to authenticated
using (
  bucket_id = 'app-assets'
  and public.is_super_admin(auth.uid())
)
with check (
  bucket_id = 'app-assets'
  and public.is_super_admin(auth.uid())
);

comment on policy evidence_files_insert_own_valid_extension on storage.objects is
'Requires path contest_id/user_id/submission_id/version.ext, user_id = auth.uid(), and extension matching metadata.file_type. Real MIME sniffing is intentionally deferred to L2/L3.';

commit;
