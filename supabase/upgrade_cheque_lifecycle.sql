-- Run this once on existing Supabase projects.
-- It upgrades cheque clearing/bounce into an auditable accounting lifecycle.

create or replace function update_cheque_status_with_ledger(
  p_payment_id uuid,
  p_cheque_status text
)
returns payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor users%rowtype;
  v_payment payments%rowtype;
  v_old_status payment_status;
  v_new_cheque_status cheque_status;
  v_new_payment_status payment_status;
  v_voucher_no text;
begin
  select *
  into v_actor
  from users
  where auth_user_id = auth.uid();

  if v_actor.id is null then
    raise exception 'No VidyaLedger user is linked to this Supabase account.';
  end if;

  if v_actor.role not in ('admin', 'principal', 'accountant', 'clerk') then
    raise exception 'This role cannot update cheque status.';
  end if;

  v_new_cheque_status := p_cheque_status::cheque_status;
  v_new_payment_status := case
    when v_new_cheque_status = 'cleared' then 'completed'::payment_status
    when v_new_cheque_status = 'bounced' then 'bounced'::payment_status
    else 'pending'::payment_status
  end;

  select *
  into v_payment
  from payments
  where id = p_payment_id
    and school_id = v_actor.school_id
    and mode = 'cheque';

  if v_payment.id is null then
    raise exception 'Cheque payment was not found for this school.';
  end if;

  v_old_status := v_payment.status;

  update payments
  set status = v_new_payment_status,
      cheque_status = v_new_cheque_status,
      note = 'Cheque ' || v_new_cheque_status::text
  where id = p_payment_id
    and school_id = v_actor.school_id
  returning * into v_payment;

  if v_new_cheque_status = 'cleared' and v_old_status <> 'completed' then
    v_voucher_no := 'CHQCLR-' || replace(v_payment.receipt_no, '/', '-');

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
      v_voucher_no,
      'Bank Account',
      'Cheque Clearing',
      v_payment.amount,
      current_date,
      'Cheque cleared for receipt ' || v_payment.receipt_no || ' by ' || v_actor.name
    );

    update reconciliation_items
    set status = 'matched',
        exception_reason = ''
    where school_id = v_actor.school_id
      and payment_id = v_payment.id;
  elsif v_new_cheque_status = 'bounced' and v_old_status <> 'bounced' then
    v_voucher_no := 'CHQBNC-' || replace(v_payment.receipt_no, '/', '-');

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
      v_voucher_no,
      'Student Fee Receivable',
      'Cheque Clearing',
      v_payment.amount,
      current_date,
      'Cheque bounced for receipt ' || v_payment.receipt_no || ' by ' || v_actor.name
    );

    update reconciliation_items
    set status = 'unmatched',
        exception_reason = 'Cheque bounced; receivable reopened'
    where school_id = v_actor.school_id
      and payment_id = v_payment.id;
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
    'Marked cheque payment ' || v_payment.receipt_no || ' as ' || v_new_cheque_status::text,
    'payment',
    v_payment.id
  );

  return v_payment;
end;
$$;

grant execute on function update_cheque_status_with_ledger(uuid, text) to authenticated;

select 'cheque_lifecycle_upgrade_ready' as status;
