begin;

alter table public.support_tickets
  add column if not exists user_id uuid references auth.users(id) on delete set null,
  add column if not exists category text not null default 'other';

alter table public.support_tickets
  drop constraint if exists support_tickets_category_check;

alter table public.support_tickets
  add constraint support_tickets_category_check
  check (category in (
    'account','courses','payments','meditation','chakra','kundalini',
    'fengshui','education','feedback','technical','other'
  ));

create index if not exists support_tickets_user_id_idx
  on public.support_tickets(user_id);
create index if not exists support_tickets_category_idx
  on public.support_tickets(category);

drop policy if exists "Anyone can submit support tickets" on public.support_tickets;
create policy "Anyone can submit support tickets"
on public.support_tickets for insert
to anon, authenticated
with check (
  status = 'open'
  and admin_reply is null
  and replied_at is null
  and (
    (auth.uid() is null and user_id is null)
    or (auth.uid() is not null and user_id = auth.uid())
  )
);

commit;