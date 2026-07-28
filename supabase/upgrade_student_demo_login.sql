-- Adds the Student demo role and links student@vidyaledger.demo to Asha Sharma.
--
-- Run this on an existing Supabase project.
--
-- Important:
-- 1. Run the ALTER TYPE statement first.
-- 2. Then create student@vidyaledger.demo in Authentication > Users
--    with password VidyaLedger@2026.
-- 3. Then run the INSERT/UPDATE block.

alter type public.user_role add value if not exists 'student';

-- After the Auth user exists, run the block below.
-- If it returns no row, create the Auth user first and rerun.

insert into public.users (
  id,
  auth_user_id,
  school_id,
  name,
  email,
  role,
  guardian_id
)
select
  '40000000-0000-0000-0000-000000000006'::uuid,
  auth_users.id,
  '00000000-0000-0000-0000-000000000001'::uuid,
  'Asha Sharma',
  'student@vidyaledger.demo',
  'student'::public.user_role,
  '10000000-0000-0000-0000-000000000001'::uuid
from auth.users auth_users
where lower(auth_users.email) = 'student@vidyaledger.demo'
on conflict (email) do update
set
  auth_user_id = excluded.auth_user_id,
  name = excluded.name,
  role = excluded.role,
  guardian_id = excluded.guardian_id
returning id, email, role, guardian_id, auth_user_id;

-- Dashboard verification query.
select
  (select count(*) from public.schools) as schools,
  (select count(*) from public.users) as users,
  (select count(*) from public.students) as students,
  (select count(*) from public.guardians) as guardians,
  (select count(*) from public.fee_demands) as fee_demands,
  (select count(*) from public.payments) as payments,
  (select count(*) from public.payment_requests) as payment_requests,
  (select count(*) from public.reconciliation_items) as reconciliation_items;

-- User/Auth link verification query.
select
  public_users.name,
  public_users.email,
  public_users.role,
  public_users.guardian_id,
  public_users.auth_user_id,
  auth_users.email as auth_email
from public.users public_users
left join auth.users auth_users on auth_users.id = public_users.auth_user_id
where public_users.email in (
  'admin@vidyaledger.demo',
  'parent@vidyaledger.demo',
  'student@vidyaledger.demo'
)
order by public_users.role::text, public_users.email;
