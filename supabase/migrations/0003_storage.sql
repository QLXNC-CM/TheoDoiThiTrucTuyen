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

do $$
declare
  v_can_manage_storage_objects boolean := false;
begin
  select pg_has_role(current_user, c.relowner, 'MEMBER')
  into v_can_manage_storage_objects
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'storage'
    and c.relname = 'objects';

  if not coalesce(v_can_manage_storage_objects, false) then
    raise notice
      'Skip storage.objects policies: current role "%" is not owner/member of storage.objects owner. Create the same policies from Supabase Storage Policies UI or rerun this block with an owner role.',
      current_user;
    return;
  end if;

  execute 'drop policy if exists evidence_files_select_scoped on storage.objects';
  execute 'drop policy if exists evidence_files_insert_own_valid_extension on storage.objects';
  execute 'drop policy if exists evidence_files_delete_own_unregistered on storage.objects';
  execute 'drop policy if exists evidence_files_super_admin_all on storage.objects';
  execute 'drop policy if exists app_assets_public_read on storage.objects';
  execute 'drop policy if exists app_assets_super_admin_all on storage.objects';

  execute $policy$
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
    )
  $policy$;

  execute $policy$
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
    )
  $policy$;

  execute $policy$
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
    )
  $policy$;

  execute $policy$
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
    )
  $policy$;

  execute $policy$
    create policy app_assets_public_read
    on storage.objects
    for select
    to anon, authenticated
    using (
      bucket_id = 'app-assets'
    )
  $policy$;

  execute $policy$
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
    )
  $policy$;

  execute $policy$
    comment on policy evidence_files_insert_own_valid_extension on storage.objects is
    'Requires path contest_id/user_id/submission_id/version.ext, user_id = auth.uid(), and extension matching metadata.file_type. Real MIME sniffing is intentionally deferred to L2/L3.'
  $policy$;
exception
  when insufficient_privilege then
    raise notice
      'Skip storage.objects policies because current role "%" does not own storage.objects. Buckets were created/updated; apply policies from Supabase Storage Policies UI or an owner role.',
      current_user;
end;
$$;

commit;
