-- Run this once on existing Supabase projects.
-- It makes Fee Engine generation persist rules, demands, ledger rows, and audit logs.

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

select 'fee_generation_upgrade_ready' as status;
