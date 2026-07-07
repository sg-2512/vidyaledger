-- Run this once on existing Supabase projects.
-- It persists concession submission and approval/rejection with audit and ledger posting.

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

select 'concession_workflow_upgrade_ready' as status;
