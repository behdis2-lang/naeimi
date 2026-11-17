-- Section-specific learning page content and media
begin;

create table if not exists public.content_pages (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  eyebrow text,
  lead text,
  intro text,
  points jsonb not null default '[]'::jsonb,
  lesson text,
  practice text,
  next_step text,
  sort_order integer not null default 0,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.content_pages enable row level security;

drop policy if exists "Published content pages are public" on public.content_pages;
create policy "Published content pages are public"
on public.content_pages for select
to anon, authenticated
using (is_published = true);

drop policy if exists "Admins manage content pages" on public.content_pages;
create policy "Admins manage content pages"
on public.content_pages for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

insert into public.content_pages (slug, title, eyebrow, sort_order)
values
  ('awakening', 'آگاهی و بیداری معنوی', 'محور اول • آگاهی و بیداری معنوی', 1),
  ('self', 'خودشناسی و شناخت درون', 'محور دوم • خودشناسی و شناخت درون', 2),
  ('growth', 'رشد فردی و زندگی آگاهانه', 'محور سوم • رشد فردی و زندگی آگاهانه', 3),
  ('pause', 'مکث و مشاهده', 'گام اول • مکث و مشاهده', 4),
  ('patterns', 'شناخت الگوها', 'گام دوم • شناخت الگوها', 5),
  ('choice', 'انتخاب آگاهانه', 'گام سوم • انتخاب آگاهانه', 6),
  ('practice', 'تمرین و استمرار', 'گام چهارم • تمرین و استمرار', 7)
on conflict (slug) do nothing;

-- Public visitors can read only published, free media attached to a published page.
drop policy if exists "Public can view free published page media" on public.media_assets;
create policy "Public can view free published page media"
on public.media_assets for select
to anon, authenticated
using (
  owner_type = 'page'
  and access_level = 'free'
  and is_published = true
  and exists (
    select 1
    from public.content_pages p
    where p.id = media_assets.owner_id
      and p.is_published = true
  )
);

-- Signed URLs for public page media still respect the private bucket:
-- only objects referenced by a published/free page asset can be signed publicly.
drop policy if exists "Public can read published free page media objects" on storage.objects;
create policy "Public can read published free page media objects"
on storage.objects for select
to anon, authenticated
using (
  bucket_id = 'course-media'
  and exists (
    select 1
    from public.media_assets ma
    join public.content_pages p on p.id = ma.owner_id
    where ma.bucket_id = storage.objects.bucket_id
      and ma.storage_path = storage.objects.name
      and ma.owner_type = 'page'
      and ma.access_level = 'free'
      and ma.is_published = true
      and p.is_published = true
  )
);

commit;
