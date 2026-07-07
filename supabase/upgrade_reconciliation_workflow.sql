-- Run this once on existing Supabase projects.
-- It persists reconciliation decisions and writes audit logs.

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

select 'reconciliation_workflow_upgrade_ready' as status;
