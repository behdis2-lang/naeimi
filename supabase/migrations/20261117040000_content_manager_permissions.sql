-- Admin content manager: explicit table privileges for dynamic section CRUD and private media previews.
begin;
grant select on table public.content_pages to anon, authenticated;
grant insert, update, delete on table public.content_pages to authenticated;
grant select on table public.media_assets to anon, authenticated;
grant insert, update, delete on table public.media_assets to authenticated;

-- Allow administrators to generate signed preview URLs for private media.
drop policy if exists "Admins can read course media" on storage.objects;
create policy "Admins can read course media"
on storage.objects for select
to authenticated
using (bucket_id = 'course-media' and public.is_admin());

commit;
