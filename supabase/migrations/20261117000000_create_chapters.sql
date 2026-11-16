-- Migration: add course chapters without disturbing existing lessons
-- Safe to run once in Supabase SQL Editor. Existing lessons remain unassigned (chapter_id = NULL).

begin;

create table if not exists public.chapters (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  description text,
  sort_order integer not null default 0,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  constraint chapters_id_course_id_unique unique (id, course_id)
);

alter table public.lessons
  add column if not exists chapter_id uuid;

-- Composite FK prevents a lesson from being attached to a chapter in another course.
-- RESTRICT prevents accidental deletion of a chapter that still contains lessons.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'lessons_chapter_course_fkey'
      and conrelid = 'public.lessons'::regclass
  ) then
    alter table public.lessons
      add constraint lessons_chapter_course_fkey
      foreign key (chapter_id, course_id)
      references public.chapters (id, course_id)
      on delete restrict;
  end if;
end $$;

create index if not exists chapters_course_sort_idx
  on public.chapters (course_id, sort_order, created_at);

create index if not exists lessons_chapter_sort_idx
  on public.lessons (chapter_id, sort_order);

alter table public.chapters enable row level security;

-- Authenticated admins can manage chapters; RLS still governs every row.
drop policy if exists chapters_admin_manage_v1 on public.chapters;
create policy chapters_admin_manage_v1
  on public.chapters
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Students can read published chapters only when the parent course is published
-- and they have an enrollment for that course. Admin access is covered above.
drop policy if exists chapters_enrolled_read_v1 on public.chapters;
create policy chapters_enrolled_read_v1
  on public.chapters
  for select
  to authenticated
  using (
    is_published = true
    and exists (
      select 1
      from public.courses c
      join public.enrollments e on e.course_id = c.id
      where c.id = chapters.course_id
        and c.is_published = true
        and e.student_id = (select auth.uid())
    )
  );

grant select, insert, update, delete on public.chapters to authenticated;

commit;

-- Notes:
-- 1) Existing lessons are preserved and remain valid with chapter_id = NULL.
-- 2) A lesson can only reference a chapter belonging to its own course.
-- 3) Deleting a chapter with lessons is blocked until those lessons are reassigned
--    or detached by setting chapter_id = NULL.
-- 4) This migration does not modify Storage policies or existing media records.
