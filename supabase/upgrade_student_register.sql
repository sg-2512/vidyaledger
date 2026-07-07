-- Run this once on existing Supabase projects.
-- It lets staff add students and guardians inside their own school tenant.

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

select 'student_register_upgrade_ready' as status;
