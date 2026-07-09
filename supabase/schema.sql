create extension if not exists "pgcrypto";

create type user_role as enum ('admin', 'principal', 'accountant', 'clerk', 'parent');
create type concession_status as enum ('draft', 'submitted', 'approved', 'rejected');
create type payment_mode as enum ('upi', 'cash', 'cheque', 'bank_transfer');
create type payment_status as enum ('pending', 'completed', 'bounced', 'reversed');
create type cheque_status as enum ('received', 'deposited', 'cleared', 'bounced');
create type reconciliation_status as enum ('unmatched', 'matched', 'duplicate', 'partial', 'overpaid');

create table schools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  board text not null,
  state text not null,
  district text not null,
  school_type text not null,
  academic_year text not null,
  address text not null default '',
  contact_email text not null default '',
  contact_phone text not null default '',
  logo_url text not null default '',
  created_at timestamptz not null default now()
);

create table class_sections (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  class_name text not null,
  section text not null,
  class_teacher text not null default '',
  room_label text not null default '',
  capacity integer not null default 45 check (capacity > 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (school_id, class_name, section)
);

create table users (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid references auth.users(id) on delete cascade,
  school_id uuid not null references schools(id) on delete cascade,
  name text not null,
  email text not null unique,
  role user_role not null,
  guardian_id uuid,
  created_at timestamptz not null default now()
);

create table guardians (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  name text not null,
  phone text not null,
  email text,
  address text,
  created_at timestamptz not null default now()
);

alter table users
  add constraint users_guardian_id_fkey foreign key (guardian_id) references guardians(id);

create table students (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  guardian_id uuid not null references guardians(id),
  admission_no text not null,
  name text not null,
  class_name text not null,
  section text not null,
  category text not null,
  phone text,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  unique (school_id, admission_no)
);

create table fee_heads (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  name text not null,
  ledger text not null,
  refundable boolean not null default false,
  active boolean not null default true
);

create table fee_rules (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  fee_head_id uuid not null references fee_heads(id),
  title text not null,
  amount numeric(12, 2) not null check (amount >= 0),
  scope_label text not null,
  frequency text not null,
  due_date date not null,
  late_fee_amount numeric(12, 2) not null default 0
);

create table fee_demands (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  student_id uuid not null references students(id),
  fee_head_id uuid not null references fee_heads(id),
  amount numeric(12, 2) not null check (amount >= 0),
  due_date date not null,
  status text not null default 'open',
  created_at timestamptz not null default now()
);

create table concessions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  student_id uuid not null references students(id),
  category text not null,
  concession_type text not null,
  amount numeric(12, 2) not null check (amount >= 0),
  funding_source text not null,
  status concession_status not null default 'submitted',
  reason text not null,
  approved_by uuid references users(id),
  created_at timestamptz not null default now()
);

create table payments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  student_id uuid not null references students(id),
  amount numeric(12, 2) not null check (amount >= 0),
  mode payment_mode not null,
  status payment_status not null,
  cheque_status cheque_status,
  reference_no text not null,
  receipt_no text not null,
  idempotency_key text,
  note text,
  paid_at timestamptz not null default now(),
  unique (school_id, receipt_no)
);

create unique index payments_school_idempotency_key_idx
on payments (school_id, idempotency_key)
where idempotency_key is not null;

create table receipts (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  payment_id uuid not null references payments(id),
  receipt_no text not null,
  pdf_url text,
  issued_at timestamptz not null default now()
);

create unique index receipts_payment_id_idx on receipts (payment_id);

create table receipt_sequences (
  school_id uuid not null references schools(id) on delete cascade,
  academic_year text not null,
  next_no integer not null default 1 check (next_no > 0),
  updated_at timestamptz not null default now(),
  primary key (school_id, academic_year)
);

create table ledger_entries (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  voucher_no text not null,
  debit_ledger text not null,
  credit_ledger text not null,
  amount numeric(12, 2) not null check (amount >= 0),
  entry_date date not null default current_date,
  narration text
);

create table reconciliation_items (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  payment_id uuid not null references payments(id),
  channel_ref text not null,
  status reconciliation_status not null default 'unmatched',
  exception_reason text
);

create table audit_logs (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  user_id uuid references users(id),
  actor text not null,
  action text not null,
  object_type text not null,
  object_id uuid,
  created_at timestamptz not null default now()
);

create or replace function current_user_role()
returns user_role
language sql
security definer
stable
as $$
  select role from public.users where auth_user_id = auth.uid() limit 1;
$$;

create or replace function current_user_school_id()
returns uuid
language sql
security definer
stable
as $$
  select school_id from public.users where auth_user_id = auth.uid() limit 1;
$$;

create or replace function issue_next_receipt_no(p_school_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_academic_year text;
  v_year_prefix text;
  v_existing_next integer;
  v_current_no integer;
begin
  select academic_year
  into v_academic_year
  from schools
  where id = p_school_id;

  if v_academic_year is null then
    raise exception 'School not found for receipt numbering.';
  end if;

  v_year_prefix := coalesce(substring(v_academic_year from '^[0-9]{4}'), to_char(current_date, 'YYYY'));

  select coalesce(
    max((regexp_match(receipt_no, '^VL/[0-9]{4}/([0-9]+)$'))[1]::integer),
    0
  ) + 1
  into v_existing_next
  from payments
  where school_id = p_school_id
    and receipt_no ~ '^VL/[0-9]{4}/[0-9]+$';

  insert into receipt_sequences (school_id, academic_year, next_no)
  values (p_school_id, v_academic_year, v_existing_next)
  on conflict (school_id, academic_year) do update set
    next_no = greatest(receipt_sequences.next_no, excluded.next_no),
    updated_at = now();

  update receipt_sequences
  set next_no = next_no + 1,
      updated_at = now()
  where school_id = p_school_id
    and academic_year = v_academic_year
  returning next_no - 1 into v_current_no;

  return format('VL/%s/%s', v_year_prefix, lpad(v_current_no::text, 4, '0'));
end;
$$;

create or replace function record_payment_with_receipt(
  p_student_id uuid,
  p_amount numeric,
  p_mode text,
  p_reference_no text,
  p_note text default '',
  p_idempotency_key text default null
)
returns payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor users%rowtype;
  v_mode payment_mode;
  v_payment_status payment_status;
  v_cheque_status cheque_status;
  v_receipt_no text;
  v_payment payments%rowtype;
  v_idempotency_key text;
  v_debit_ledger text;
begin
  select *
  into v_actor
  from users
  where auth_user_id = auth.uid();

  if v_actor.id is null then
    raise exception 'No VidyaLedger user is linked to this Supabase account.';
  end if;

  if v_actor.role not in ('admin', 'principal', 'accountant', 'clerk') then
    raise exception 'This role cannot record payments.';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Payment amount must be greater than zero.';
  end if;

  if not exists (
    select 1 from students
    where id = p_student_id
      and school_id = v_actor.school_id
      and status = 'active'
  ) then
    raise exception 'Student is not active in your school.';
  end if;

  v_mode := p_mode::payment_mode;
  v_payment_status := case
    when v_mode = 'cheque' then 'pending'::payment_status
    else 'completed'::payment_status
  end;
  v_cheque_status := case
    when v_mode = 'cheque' then 'received'::cheque_status
    else null
  end;
  v_idempotency_key := nullif(trim(coalesce(p_idempotency_key, '')), '');

  if v_idempotency_key is not null then
    select *
    into v_payment
    from payments
    where school_id = v_actor.school_id
      and idempotency_key = v_idempotency_key;

    if found then
      return v_payment;
    end if;
  end if;

  v_receipt_no := issue_next_receipt_no(v_actor.school_id);

  insert into payments (
    school_id,
    student_id,
    amount,
    mode,
    status,
    cheque_status,
    reference_no,
    receipt_no,
    idempotency_key,
    note
  )
  values (
    v_actor.school_id,
    p_student_id,
    p_amount,
    v_mode,
    v_payment_status,
    v_cheque_status,
    trim(p_reference_no),
    v_receipt_no,
    v_idempotency_key,
    nullif(trim(coalesce(p_note, '')), '')
  )
  returning * into v_payment;

  insert into receipts (school_id, payment_id, receipt_no)
  values (v_actor.school_id, v_payment.id, v_receipt_no);

  insert into reconciliation_items (
    school_id,
    payment_id,
    channel_ref,
    status,
    exception_reason
  )
  values (
    v_actor.school_id,
    v_payment.id,
    trim(p_reference_no),
    case when v_mode = 'cash' then 'matched'::reconciliation_status else 'unmatched'::reconciliation_status end,
    case when v_mode = 'cash' then '' else 'Pending settlement verification' end
  );

  v_debit_ledger := case
    when v_mode = 'cash' then 'Cash in Hand'
    when v_mode = 'cheque' then 'Cheque Clearing'
    else 'Bank Account'
  end;

  insert into ledger_entries (
    school_id,
    voucher_no,
    debit_ledger,
    credit_ledger,
    amount,
    entry_date,
    narration
  )
  values (
    v_actor.school_id,
    'RCPT-' || replace(v_receipt_no, '/', '-'),
    v_debit_ledger,
    'Student Fee Receivable',
    p_amount,
    current_date,
    'Payment receipt posted by ' || v_actor.name
  );

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
    'Recorded ' || v_mode::text || ' payment ' || v_receipt_no,
    'payment',
    v_payment.id
  );

  return v_payment;
end;
$$;

grant execute on function issue_next_receipt_no(uuid) to authenticated;
grant execute on function record_payment_with_receipt(uuid, numeric, text, text, text, text) to authenticated;

create or replace function generate_fee_demand_for_class(
  p_fee_head_id uuid,
  p_title text,
  p_amount numeric,
  p_class_name text,
  p_due_date date,
  p_late_fee_amount numeric default 0,
  p_frequency text default 'Term'
)
returns table(rule_id uuid, demand_count integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor users%rowtype;
  v_fee_head fee_heads%rowtype;
  v_rule_id uuid;
  v_demand_count integer;
begin
  select *
  into v_actor
  from users
  where auth_user_id = auth.uid();

  if v_actor.id is null then
    raise exception 'No VidyaLedger user is linked to this Supabase account.';
  end if;

  if v_actor.role not in ('admin', 'principal', 'accountant') then
    raise exception 'This role cannot generate fee demands.';
  end if;

  if nullif(trim(coalesce(p_title, '')), '') is null then
    raise exception 'Fee rule title is required.';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Fee amount must be greater than zero.';
  end if;

  select *
  into v_fee_head
  from fee_heads
  where id = p_fee_head_id
    and school_id = v_actor.school_id
    and active = true;

  if v_fee_head.id is null then
    raise exception 'Active fee head was not found for this school.';
  end if;

  select count(*)
  into v_demand_count
  from students
  where school_id = v_actor.school_id
    and class_name = trim(p_class_name)
    and status = 'active';

  if v_demand_count = 0 then
    raise exception 'No active students found for Class %.', trim(p_class_name);
  end if;

  insert into fee_rules (
    school_id,
    fee_head_id,
    title,
    amount,
    scope_label,
    frequency,
    due_date,
    late_fee_amount
  )
  values (
    v_actor.school_id,
    p_fee_head_id,
    trim(p_title),
    p_amount,
    'Class ' || trim(p_class_name),
    coalesce(nullif(trim(coalesce(p_frequency, '')), ''), 'Term'),
    p_due_date,
    coalesce(p_late_fee_amount, 0)
  )
  returning id into v_rule_id;

  insert into fee_demands (
    school_id,
    student_id,
    fee_head_id,
    amount,
    due_date,
    status
  )
  select
    v_actor.school_id,
    students.id,
    p_fee_head_id,
    p_amount,
    p_due_date,
    'open'
  from students
  where students.school_id = v_actor.school_id
    and students.class_name = trim(p_class_name)
    and students.status = 'active';

  insert into ledger_entries (
    school_id,
    voucher_no,
    debit_ledger,
    credit_ledger,
    amount,
    entry_date,
    narration
  )
  select
    v_actor.school_id,
    'DEMAND-' || replace(v_rule_id::text, '-', '') || '-' || students.admission_no,
    'Student Fee Receivable',
    v_fee_head.ledger,
    p_amount,
    p_due_date,
    trim(p_title) || ' posted for ' || students.name
  from students
  where students.school_id = v_actor.school_id
    and students.class_name = trim(p_class_name)
    and students.status = 'active';

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
    'Generated ' || trim(p_title) || ' for Class ' || trim(p_class_name) || ' (' || v_demand_count || ' students)',
    'fee_demand',
    v_rule_id
  );

  return query select v_rule_id, v_demand_count;
end;
$$;

grant execute on function generate_fee_demand_for_class(uuid, text, numeric, text, date, numeric, text) to authenticated;

create or replace function submit_concession_request(
  p_student_id uuid,
  p_category text,
  p_concession_type text,
  p_amount numeric,
  p_funding_source text,
  p_reason text
)
returns concessions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor users%rowtype;
  v_concession concessions%rowtype;
begin
  select *
  into v_actor
  from users
  where auth_user_id = auth.uid();

  if v_actor.id is null then
    raise exception 'No VidyaLedger user is linked to this Supabase account.';
  end if;

  if v_actor.role not in ('admin', 'principal', 'accountant', 'clerk') then
    raise exception 'This role cannot submit concession requests.';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Concession amount must be greater than zero.';
  end if;

  if nullif(trim(coalesce(p_reason, '')), '') is null then
    raise exception 'Concession reason or document note is required.';
  end if;

  if not exists (
    select 1 from students
    where id = p_student_id
      and school_id = v_actor.school_id
      and status = 'active'
  ) then
    raise exception 'Student is not active in your school.';
  end if;

  insert into concessions (
    school_id,
    student_id,
    category,
    concession_type,
    amount,
    funding_source,
    status,
    reason
  )
  values (
    v_actor.school_id,
    p_student_id,
    trim(p_category),
    trim(p_concession_type),
    p_amount,
    trim(p_funding_source),
    'submitted',
    trim(p_reason)
  )
  returning * into v_concession;

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
    'Submitted ' || trim(p_category) || ' concession request',
    'concession',
    v_concession.id
  );

  return v_concession;
end;
$$;

create or replace function update_concession_decision(
  p_concession_id uuid,
  p_status text
)
returns concessions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor users%rowtype;
  v_old_status concession_status;
  v_new_status concession_status;
  v_concession concessions%rowtype;
  v_debit_ledger text;
begin
  select *
  into v_actor
  from users
  where auth_user_id = auth.uid();

  if v_actor.id is null then
    raise exception 'No VidyaLedger user is linked to this Supabase account.';
  end if;

  if v_actor.role not in ('admin', 'principal', 'accountant') then
    raise exception 'This role cannot approve or reject concessions.';
  end if;

  v_new_status := p_status::concession_status;

  if v_new_status not in ('approved', 'rejected') then
    raise exception 'Concession decision must be approved or rejected.';
  end if;

  select status
  into v_old_status
  from concessions
  where id = p_concession_id
    and school_id = v_actor.school_id;

  if v_old_status is null then
    raise exception 'Concession was not found for this school.';
  end if;

  update concessions
  set status = v_new_status,
      approved_by = case when v_new_status = 'approved' then v_actor.id else null end
  where id = p_concession_id
    and school_id = v_actor.school_id
  returning * into v_concession;

  if v_new_status = 'approved' and v_old_status <> 'approved' then
    v_debit_ledger := case
      when lower(v_concession.funding_source) like '%reimbursement%' then 'RTE Reimbursement Receivable'
      when lower(v_concession.funding_source) like '%scholarship%' then 'Scholarship Receivable'
      when lower(v_concession.funding_source) like '%sponsor%' then 'Sponsor Receivable'
      else 'Concession Expense'
    end;

    insert into ledger_entries (
      school_id,
      voucher_no,
      debit_ledger,
      credit_ledger,
      amount,
      entry_date,
      narration
    )
    values (
      v_actor.school_id,
      'CONC-' || replace(v_concession.id::text, '-', ''),
      v_debit_ledger,
      'Student Fee Receivable',
      v_concession.amount,
      current_date,
      'Approved ' || v_concession.category || ' concession by ' || v_actor.name
    );
  end if;

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
    initcap(v_new_status::text) || ' concession request',
    'concession',
    v_concession.id
  );

  return v_concession;
end;
$$;

grant execute on function submit_concession_request(uuid, text, text, numeric, text, text) to authenticated;
grant execute on function update_concession_decision(uuid, text) to authenticated;

create or replace function update_reconciliation_status(
  p_reconciliation_id uuid,
  p_status text,
  p_exception_reason text default ''
)
returns reconciliation_items
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor users%rowtype;
  v_status reconciliation_status;
  v_item reconciliation_items%rowtype;
begin
  select *
  into v_actor
  from users
  where auth_user_id = auth.uid();

  if v_actor.id is null then
    raise exception 'No VidyaLedger user is linked to this Supabase account.';
  end if;

  if v_actor.role not in ('admin', 'principal', 'accountant') then
    raise exception 'This role cannot update reconciliation status.';
  end if;

  v_status := p_status::reconciliation_status;

  update reconciliation_items
  set status = v_status,
      exception_reason = trim(coalesce(p_exception_reason, ''))
  where id = p_reconciliation_id
    and school_id = v_actor.school_id
  returning * into v_item;

  if v_item.id is null then
    raise exception 'Reconciliation item was not found for this school.';
  end if;

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
    'Marked reconciliation item as ' || v_status::text,
    'reconciliation',
    v_item.id
  );

  return v_item;
end;
$$;

grant execute on function update_reconciliation_status(uuid, text, text) to authenticated;

create or replace function create_student_with_guardian(
  p_admission_no text,
  p_student_name text,
  p_class_name text,
  p_section text,
  p_category text,
  p_student_phone text,
  p_guardian_name text,
  p_guardian_phone text,
  p_guardian_email text default '',
  p_guardian_address text default ''
)
returns students
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor users%rowtype;
  v_guardian guardians%rowtype;
  v_student students%rowtype;
begin
  select *
  into v_actor
  from users
  where auth_user_id = auth.uid();

  if v_actor.id is null then
    raise exception 'No VidyaLedger user is linked to this Supabase account.';
  end if;

  if v_actor.role not in ('admin', 'principal', 'accountant', 'clerk') then
    raise exception 'This role cannot add students.';
  end if;

  if nullif(trim(coalesce(p_admission_no, '')), '') is null then
    raise exception 'Admission number is required.';
  end if;

  if nullif(trim(coalesce(p_student_name, '')), '') is null then
    raise exception 'Student name is required.';
  end if;

  if nullif(trim(coalesce(p_guardian_name, '')), '') is null then
    raise exception 'Guardian name is required.';
  end if;

  if nullif(trim(coalesce(p_guardian_phone, '')), '') is null then
    raise exception 'Guardian phone is required.';
  end if;

  if exists (
    select 1
    from students
    where school_id = v_actor.school_id
      and lower(admission_no) = lower(trim(p_admission_no))
  ) then
    raise exception 'Admission number already exists for this school.';
  end if;

  insert into guardians (
    school_id,
    name,
    phone,
    email,
    address
  )
  values (
    v_actor.school_id,
    trim(p_guardian_name),
    trim(p_guardian_phone),
    nullif(trim(coalesce(p_guardian_email, '')), ''),
    nullif(trim(coalesce(p_guardian_address, '')), '')
  )
  returning * into v_guardian;

  insert into students (
    school_id,
    guardian_id,
    admission_no,
    name,
    class_name,
    section,
    category,
    phone,
    status
  )
  values (
    v_actor.school_id,
    v_guardian.id,
    trim(p_admission_no),
    trim(p_student_name),
    trim(p_class_name),
    upper(trim(p_section)),
    trim(p_category),
    nullif(trim(coalesce(p_student_phone, '')), ''),
    'active'
  )
  returning * into v_student;

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
    'Added student ' || v_student.name || ' (' || v_student.admission_no || ')',
    'student',
    v_student.id
  );

  return v_student;
end;
$$;

grant execute on function create_student_with_guardian(text, text, text, text, text, text, text, text, text, text) to authenticated;

alter table schools enable row level security;
alter table class_sections enable row level security;
alter table users enable row level security;
alter table guardians enable row level security;
alter table students enable row level security;
alter table fee_heads enable row level security;
alter table fee_rules enable row level security;
alter table fee_demands enable row level security;
alter table concessions enable row level security;
alter table payments enable row level security;
alter table receipts enable row level security;
alter table receipt_sequences enable row level security;
alter table ledger_entries enable row level security;
alter table reconciliation_items enable row level security;
alter table audit_logs enable row level security;

create policy "school members can read own school"
on schools for select
using (id = current_user_school_id());

create policy "setup roles can update own school"
on schools for update
using (id = current_user_school_id() and current_user_role() in ('admin', 'principal'))
with check (id = current_user_school_id() and current_user_role() in ('admin', 'principal'));

create policy "school members can read class sections"
on class_sections for select
using (school_id = current_user_school_id());

create policy "setup roles can manage class sections"
on class_sections for all
using (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal'))
with check (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal'));

create policy "admins can manage users"
on users for all
using (school_id = current_user_school_id() and current_user_role() = 'admin')
with check (school_id = current_user_school_id() and current_user_role() = 'admin');

create policy "users can read own school users"
on users for select
using (school_id = current_user_school_id());

create policy "staff can read guardians"
on guardians for select
using (school_id = current_user_school_id());

create policy "staff can manage students"
on students for all
using (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant', 'clerk'))
with check (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant', 'clerk'));

create policy "parents can read linked students"
on students for select
using (
  school_id = current_user_school_id()
  and guardian_id in (select guardian_id from users where auth_user_id = auth.uid())
);

create policy "staff can manage fee config"
on fee_heads for all
using (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant'))
with check (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant'));

create policy "members can read fee heads"
on fee_heads for select
using (school_id = current_user_school_id());

create policy "staff can manage fee rules"
on fee_rules for all
using (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant'))
with check (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant'));

create policy "members can read fee rules"
on fee_rules for select
using (school_id = current_user_school_id());

create policy "staff can manage demands"
on fee_demands for all
using (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant', 'clerk'))
with check (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant', 'clerk'));

create policy "parents can read own demands"
on fee_demands for select
using (
  school_id = current_user_school_id()
  and student_id in (
    select id from students where guardian_id in (
      select guardian_id from users where auth_user_id = auth.uid()
    )
  )
);

create policy "staff can manage concessions"
on concessions for all
using (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant', 'clerk'))
with check (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant', 'clerk'));

create policy "parents can read own concessions"
on concessions for select
using (
  school_id = current_user_school_id()
  and student_id in (
    select id from students where guardian_id in (
      select guardian_id from users where auth_user_id = auth.uid()
    )
  )
);

create policy "staff can manage payments"
on payments for all
using (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant', 'clerk'))
with check (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant', 'clerk'));

create policy "parents can read own payments"
on payments for select
using (
  school_id = current_user_school_id()
  and student_id in (
    select id from students where guardian_id in (
      select guardian_id from users where auth_user_id = auth.uid()
    )
  )
);

create policy "staff can manage receipts"
on receipts for all
using (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant', 'clerk'))
with check (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant', 'clerk'));

create policy "staff can manage receipt sequences"
on receipt_sequences for all
using (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant'))
with check (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant'));

create policy "staff can manage ledger"
on ledger_entries for all
using (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant'))
with check (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant'));

create policy "staff can manage reconciliation"
on reconciliation_items for all
using (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant'))
with check (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant'));

create policy "school users can read audit logs"
on audit_logs for select
using (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant'));

create policy "staff can insert audit logs"
on audit_logs for insert
with check (school_id = current_user_school_id());
