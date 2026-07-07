-- Run this once after supabase/schema.sql + seed files on an existing project.
-- It upgrades payments to use database-issued receipt numbers and atomic posting.

alter table payments
  add column if not exists idempotency_key text;

create unique index if not exists payments_school_idempotency_key_idx
on payments (school_id, idempotency_key)
where idempotency_key is not null;

create unique index if not exists receipts_payment_id_idx on receipts (payment_id);

create table if not exists receipt_sequences (
  school_id uuid not null references schools(id) on delete cascade,
  academic_year text not null,
  next_no integer not null default 1 check (next_no > 0),
  updated_at timestamptz not null default now(),
  primary key (school_id, academic_year)
);

alter table receipt_sequences enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'receipt_sequences'
      and policyname = 'staff can manage receipt sequences'
  ) then
    create policy "staff can manage receipt sequences"
    on receipt_sequences for all
    using (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant'))
    with check (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal', 'accountant'));
  end if;
end $$;

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

select
  'receipt_numbering_upgrade_ready' as status,
  (select count(*) from receipt_sequences) as sequence_rows,
  (select count(*) from payments where idempotency_key is not null) as idempotent_payments;
