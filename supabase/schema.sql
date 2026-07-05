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
  created_at timestamptz not null default now()
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
  note text,
  paid_at timestamptz not null default now(),
  unique (school_id, receipt_no)
);

create table receipts (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  payment_id uuid not null references payments(id),
  receipt_no text not null,
  pdf_url text,
  issued_at timestamptz not null default now()
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

alter table schools enable row level security;
alter table users enable row level security;
alter table guardians enable row level security;
alter table students enable row level security;
alter table fee_heads enable row level security;
alter table fee_rules enable row level security;
alter table fee_demands enable row level security;
alter table concessions enable row level security;
alter table payments enable row level security;
alter table receipts enable row level security;
alter table ledger_entries enable row level security;
alter table reconciliation_items enable row level security;
alter table audit_logs enable row level security;

create policy "school members can read own school"
on schools for select
using (id = current_user_school_id());

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
