begin;

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  ticket_code text not null unique default upper(substr(encode(gen_random_bytes(8),'hex'),1,10)),
  visitor_name text,
  visitor_email text,
  subject text not null,
  message text not null,
  status text not null default 'open' check (status in ('open','in_progress','answered','closed')),
  admin_reply text,
  replied_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint support_subject_length check (char_length(subject) between 2 and 120),
  constraint support_message_length check (char_length(message) between 10 and 4000),
  constraint support_name_length check (visitor_name is null or char_length(visitor_name)<=100),
  constraint support_email_length check (visitor_email is null or char_length(visitor_email)<=254)
);

create index if not exists support_tickets_created_at_idx on public.support_tickets(created_at desc);
create index if not exists support_tickets_status_idx on public.support_tickets(status);

alter table public.support_tickets enable row level security;

drop policy if exists "Anyone can submit support tickets" on public.support_tickets;
create policy "Anyone can submit support tickets"
on public.support_tickets for insert
to anon, authenticated
with check (
  status = 'open'
  and admin_reply is null
  and replied_at is null
);

drop policy if exists "Admins manage support tickets" on public.support_tickets;
create policy "Admins manage support tickets"
on public.support_tickets for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

commit;
