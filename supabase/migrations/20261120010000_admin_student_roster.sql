-- Secure administrator-only student roster; never expose auth.users to browser clients.
begin;

create or replace function public.admin_list_students()
returns table (
  student_id uuid,
  email text,
  full_name text,
  enrollment_count bigint,
  completed_lessons bigint,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    u.id,
    u.email::text,
    coalesce(
      nullif(u.raw_user_meta_data ->> 'full_name', ''),
      nullif(u.raw_user_meta_data ->> 'name', ''),
      ''
    )::text,
    count(distinct e.course_id)::bigint,
    count(distinct lp.lesson_id)::bigint,
    u.created_at
  from auth.users u
  join public.profiles p on p.id = u.id
  left join public.enrollments e on e.student_id = u.id
  left join public.lesson_progress lp on lp.student_id = u.id
  where p.role = 'student'
    and (select auth.uid()) is not null
    and exists (
      select 1 from public.profiles caller
      where caller.id = (select auth.uid())
        and caller.role = 'admin'
    )
  group by u.id, u.email, u.raw_user_meta_data, u.created_at
  order by u.created_at desc;
$$;

revoke all on function public.admin_list_students() from public;
revoke all on function public.admin_list_students() from anon;
grant execute on function public.admin_list_students() to authenticated;

commit;
