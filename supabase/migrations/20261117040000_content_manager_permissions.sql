-- Admin content manager: explicit table privileges for dynamic section CRUD.
begin;
grant select on table public.content_pages to anon, authenticated;
grant insert, update, delete on table public.content_pages to authenticated;
grant select on table public.media_assets to anon, authenticated;
grant insert, update, delete on table public.media_assets to authenticated;
commit;
