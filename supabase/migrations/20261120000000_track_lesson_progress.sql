-- Track each enrolled student's completion state for published lessons.
begin;

create table if not exists public.lesson_progress (
  student_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  completed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key (student_id, lesson_id)
);

create index if not exists lesson_progress_lesson_id_idx
  on public.lesson_progress(lesson_id);

alter table public.lesson_progress enable row level security;

drop policy if exists lesson_progress_student_read on public.lesson_progress;
create policy lesson_progress_student_read
  on public.lesson_progress for select
  to authenticated
  using (
    student_id = (select auth.uid())
    and exists (
      select 1 from public.lessons l
      join public.enrollments e on e.course_id = l.course_id
      join public.courses c on c.id = l.course_id
      where l.id = lesson_progress.lesson_id
        and e.student_id = (select auth.uid())
        and l.is_published = true
        and c.is_published = true
        and (
          l.chapter_id is null
          or exists (
            select 1 from public.chapters ch
            where ch.id = l.chapter_id
              and ch.course_id = l.course_id
              and ch.is_published = true
          )
        )
    )
  );

drop policy if exists lesson_progress_student_insert on public.lesson_progress;
create policy lesson_progress_student_insert
  on public.lesson_progress for insert
  to authenticated
  with check (
    student_id = (select auth.uid())
    and exists (
      select 1 from public.lessons l
      join public.enrollments e on e.course_id = l.course_id
      join public.courses c on c.id = l.course_id
      where l.id = lesson_progress.lesson_id
        and e.student_id = (select auth.uid())
        and l.is_published = true
        and c.is_published = true
        and (
          l.chapter_id is null
          or exists (
            select 1 from public.chapters ch
            where ch.id = l.chapter_id
              and ch.course_id = l.course_id
              and ch.is_published = true
          )
        )
    )
  );

drop policy if exists lesson_progress_student_update on public.lesson_progress;
create policy lesson_progress_student_update
  on public.lesson_progress for update
  to authenticated
  using (student_id = (select auth.uid()))
  with check (student_id = (select auth.uid()));

drop policy if exists lesson_progress_student_delete on public.lesson_progress;
create policy lesson_progress_student_delete
  on public.lesson_progress for delete
  to authenticated
  using (student_id = (select auth.uid()));

grant select, insert, update, delete on public.lesson_progress to authenticated;

commit;
