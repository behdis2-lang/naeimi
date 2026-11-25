-- Read-only diagnostics for the academy's existing Supabase core security setup.
-- Run in Supabase SQL Editor using a project owner/admin session.
-- This script does not read customer rows, alter schema, change policies, or write data.

-- 1) Confirm core tables and the role/profile columns exist.
select
  table_schema,
  table_name,
  column_name,
  data_type,
  is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name in (
    'profiles', 'courses', 'lessons', 'enrollments',
    'media_assets', 'lesson_progress', 'support_tickets'
  )
order by table_name, ordinal_position;

-- 2) Inspect Row Level Security state for core tables.
select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind in ('r', 'p')
  and c.relname in (
    'profiles', 'courses', 'lessons', 'enrollments',
    'media_assets', 'lesson_progress', 'support_tickets'
  )
order by c.relname;

-- 3) Show policies, especially the policy protecting profiles.role.
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename in (
    'profiles', 'courses', 'lessons', 'enrollments',
    'media_assets', 'lesson_progress', 'support_tickets'
  )
order by tablename, policyname;

-- 4) Inspect grants on profiles. A client must not be able to promote itself
--    by updating its own role column.
select
  grantee,
  privilege_type,
  column_name,
  is_grantable
from information_schema.column_privileges
where table_schema = 'public'
  and table_name = 'profiles'
order by grantee, privilege_type, column_name;

select
  grantee,
  privilege_type,
  is_grantable
from information_schema.table_privileges
where table_schema = 'public'
  and table_name = 'profiles'
order by grantee, privilege_type;

-- 5) Inspect profile/signup triggers on auth.users without exposing user records.
select
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
from information_schema.triggers
where event_object_schema = 'auth'
  and event_object_table = 'users'
order by trigger_name, event_manipulation;

-- 6) Inspect relevant function definitions and security mode.
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  p.prosecdef as security_definer,
  p.proconfig as function_settings,
  pg_get_functiondef(p.oid) as definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and (
    p.proname in ('is_admin', 'admin_list_students')
    or p.proname ilike '%profile%'
    or p.proname ilike '%user%'
  )
order by p.proname;

-- 7) Confirm the course-media bucket exists and whether it is public.
select
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
from storage.buckets
where id = 'course-media';

-- 8) Inspect Storage object policies for the course-media bucket.
select
  schemaname,
  tablename,
  policyname,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'storage'
  and tablename = 'objects'
order by policyname;

-- 9) Inspect profile role defaults, constraints, and indexes. This helps verify
--    that new accounts cannot receive an elevated role through column defaults.
select
  column_name,
  column_default,
  is_nullable,
  data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'profiles'
  and column_name in ('id', 'role')
order by ordinal_position;

select
  conname,
  contype,
  pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid = 'public.profiles'::regclass
order by conname;

-- 10) Inspect execute grants on security-sensitive public functions.
select
  routine_schema,
  routine_name,
  grantee,
  privilege_type,
  is_grantable
from information_schema.routine_privileges
where routine_schema = 'public'
  and routine_name in ('is_admin', 'admin_list_students')
order by routine_name, grantee, privilege_type;

-- 11) Inspect enabled triggers directly from PostgreSQL catalogs, including
--     non-internal triggers on auth.users.
select
  t.tgname as trigger_name,
  pg_get_triggerdef(t.oid, true) as trigger_definition,
  p.proname as trigger_function
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
join pg_proc p on p.oid = t.tgfoid
where n.nspname = 'auth'
  and c.relname = 'users'
  and not t.tgisinternal
order by t.tgname;
