-- Migration: enforce published chapter visibility for chapter-linked lessons
-- Legacy lessons with chapter_id IS NULL retain their existing visibility behavior.

begin;

drop policy if exists "Enrolled students can view published lessons"
  on public.lessons;

create policy "Enrolled students can view published lessons"
  on public.lessons
  for select
  to authenticated
  using (
    (
      is_published = true
      and exists (
        select 1
        from public.enrollments e
        where e.course_id = lessons.course_id
          and e.student_id = (select auth.uid())
      )
      and (
        chapter_id is null
        or exists (
          select 1
          from public.chapters ch
          join public.courses c on c.id = ch.course_id
          where ch.id = lessons.chapter_id
            and ch.course_id = lessons.course_id
            and ch.is_published = true
            and c.is_published = true
        )
      )
    )
    or (select public.is_admin())
  );

commit;

-- Admins retain access through is_admin().
-- Enrolled students can see chapter-linked lessons only if both chapter and course
-- are published. Existing unassigned lessons retain the previous policy behavior.
