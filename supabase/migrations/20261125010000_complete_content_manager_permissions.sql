-- Complete the administrator permissions required by the content manager.
-- Existing student/public read policies are preserved; these policies add admin CRUD only.
begin;

alter table public.media_assets enable row level security;

drop policy if exists "Admins manage media assets" on public.media_assets;
create policy "Admins manage media assets"
  on public.media_assets
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- The content manager uploads into and removes objects from this private bucket.
-- Keep all write operations restricted to authenticated administrators.
drop policy if exists "Admins can upload course media" on storage.objects;
create policy "Admins can upload course media"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'course-media'
    and public.is_admin()
  );

drop policy if exists "Admins can update course media" on storage.objects;
create policy "Admins can update course media"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'course-media'
    and public.is_admin()
  )
  with check (
    bucket_id = 'course-media'
    and public.is_admin()
  );

drop policy if exists "Admins can delete course media" on storage.objects;
create policy "Admins can delete course media"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'course-media'
    and public.is_admin()
  );

commit;
