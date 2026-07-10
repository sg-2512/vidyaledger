-- Run this once on existing Supabase projects.
-- It adds provider-neutral UPI/gateway payment requests for payment links and hosted checkouts.

do $$
begin
  if not exists (select 1 from pg_type where typname = 'payment_provider') then
    create type payment_provider as enum ('upi_intent', 'razorpay', 'cashfree', 'phonepe', 'payu');
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'payment_request_status') then
    create type payment_request_status as enum ('created', 'shared', 'paid', 'expired', 'failed', 'cancelled');
  end if;
end $$;

create table if not exists payment_requests (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  student_id uuid not null references students(id),
  amount numeric(12, 2) not null check (amount > 0),
  provider payment_provider not null,
  status payment_request_status not null default 'created',
  request_no text not null,
  checkout_url text not null,
  upi_uri text,
  gateway_order_id text,
  gateway_payment_id text,
  note text,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  unique (school_id, request_no)
);

alter table payment_requests enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'payment_requests'
      and policyname = 'staff can manage payment requests'
  ) then
    create policy "staff can manage payment requests"
    on payment_requests for all
    using (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant', 'clerk'))
    with check (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant', 'clerk'));
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'payment_requests'
      and policyname = 'parents can read own payment requests'
  ) then
    create policy "parents can read own payment requests"
    on payment_requests for select
    using (
      school_id = current_user_school_id()
      and student_id in (
        select id from students where guardian_id in (
          select guardian_id from users where auth_user_id = auth.uid()
        )
      )
    );
  end if;
end $$;

create or replace function create_payment_request(
  p_student_id uuid,
  p_amount numeric,
  p_provider text,
  p_note text default ''
)
returns payment_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor users%rowtype;
  v_student students%rowtype;
  v_school schools%rowtype;
  v_provider payment_provider;
  v_request payment_requests%rowtype;
  v_request_no text;
  v_upi_uri text;
  v_checkout_url text;
  v_gateway_order_id text;
  v_note text;
begin
  select *
  into v_actor
  from users
  where auth_user_id = auth.uid();

  if v_actor.id is null then
    raise exception 'No VidyaLedger user is linked to this Supabase account.';
  end if;

  if v_actor.role not in ('admin', 'principal', 'accountant', 'clerk') then
    raise exception 'This role cannot create payment requests.';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Payment request amount must be greater than zero.';
  end if;

  select *
  into v_student
  from students
  where id = p_student_id
    and school_id = v_actor.school_id
    and status = 'active';

  if v_student.id is null then
    raise exception 'Student is not active in your school.';
  end if;

  select *
  into v_school
  from schools
  where id = v_actor.school_id;

  v_provider := p_provider::payment_provider;
  v_note := nullif(trim(coalesce(p_note, '')), '');
  v_request_no := 'VPR/' ||
    coalesce(substring(v_school.academic_year from '^[0-9]{4}'), to_char(current_date, 'YYYY')) ||
    '/' ||
    upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));

  if v_provider = 'upi_intent' then
    v_upi_uri :=
      'upi://pay?pa=vidyaledger.demo%40upi' ||
      '&pn=' || replace(v_school.name, ' ', '%20') ||
      '&am=' || to_char(p_amount, 'FM9999999990.00') ||
      '&cu=INR' ||
      '&tn=' || replace(v_request_no || coalesce(' ' || v_note, ''), ' ', '%20');
    v_checkout_url := v_upi_uri;
  else
    v_gateway_order_id := lower(v_provider::text) || '_' || replace(gen_random_uuid()::text, '-', '');
    v_checkout_url := 'https://payments.vidyaledger.example/checkout/' || v_gateway_order_id;
  end if;

  insert into payment_requests (
    school_id,
    student_id,
    amount,
    provider,
    status,
    request_no,
    checkout_url,
    upi_uri,
    gateway_order_id,
    note,
    expires_at
  )
  values (
    v_actor.school_id,
    p_student_id,
    p_amount,
    v_provider,
    'created',
    v_request_no,
    v_checkout_url,
    v_upi_uri,
    v_gateway_order_id,
    v_note,
    now() + interval '3 days'
  )
  returning * into v_request;

  insert into audit_logs (
    school_id,
    user_id,
    actor,
    action,
    object_type,
    object_id
  )
  values (
    v_actor.school_id,
    v_actor.id,
    v_actor.name,
    'Created ' || v_provider::text || ' payment request ' || v_request_no,
    'payment_request',
    v_request.id
  );

  return v_request;
end;
$$;

grant execute on function create_payment_request(uuid, numeric, text, text) to authenticated;

select 'payment_requests_upgrade_ready' as status;
