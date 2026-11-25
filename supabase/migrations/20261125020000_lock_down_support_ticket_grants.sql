-- Make support-ticket privileges explicit instead of relying on project default grants.
-- RLS continues to decide which authenticated users may read or manage rows.
begin;

revoke all on table public.support_tickets from anon;
revoke all on table public.support_tickets from authenticated;

-- Visitors may submit only the fields accepted by the public support form.
-- Ticket code, status, replies and timestamps remain database-controlled.
grant insert (
  visitor_name,
  visitor_email,
  subject,
  message,
  category,
  user_id
) on table public.support_tickets to anon, authenticated;

-- Authenticated users receive table operations, but RLS restricts them to admins.
grant select, update, delete on table public.support_tickets to authenticated;

commit;
