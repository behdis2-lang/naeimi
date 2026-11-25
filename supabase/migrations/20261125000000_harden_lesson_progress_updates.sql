-- Tighten lesson progress updates: the target lesson must remain published
-- and enrolled by the same student, just like inserts.
begin;

drop policy if exists lesson_progress_student_update on public.lesson_progress;

create policy lesson_progress_student_update
  on public.lesson_progress
  for update
  to authenticated
  using (
    student_id = (select auth.uid())
    and exists (
      select 1
      from public.lessons l
      join public.enrollments e on e.course_id = l.course_id
      join public.courses c on c.id = l.course_id
      where l.id = lesson_progress.lesson_id
        and e.student_id = (select auth.uid())
        and l.is_published = true
        and c.is_published = true
        and (
          l.chapter_id is null
          or exists (
            select 1
            from public.chapters ch
            where ch.id = l.chapter_id
              and ch.course_id = l.course_id
              and ch.is_published = true
          )
        )
    )
  )
  with check (
    student_id = (select auth.uid())
    and exists (
      select 1
      from public.lessons l
      join public.enrollments e on e.course_id = l.course_id
      join public.courses c on c.id = l.course_id
      where l.id = lesson_progress.lesson_id
        and e.student_id = (select auth.uid())
        and l.is_published = true
        and c.is_published = true
        and (
          l.chapter_id is null
          or exists (
            select 1
            from public.chapters ch
            where ch.id = l.chapter_id
              and ch.course_id = l.course_id
              and ch.is_published = true
          )
        )
    )
  );

commit;

-- This closes the gap where a student could update their own progress row
-- to point at a lesson outside their current enrollment or a non-published lesson.
