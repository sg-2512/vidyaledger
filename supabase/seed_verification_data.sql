-- Run after supabase/seed.sql.
-- Adds a larger verification dataset while keeping the script safe to rerun.

drop table if exists pg_temp.large_seed_students;

create temporary table large_seed_students as
select
  n,
  '00000000-0000-0000-0000-000000000001'::uuid as school_id,
  ('10000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid as guardian_id,
  ('20000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid as student_id,
  format('VL-2026-%s', lpad(n::text, 3, '0')) as admission_no,
  (
    (array[
      'Aditi', 'Kabir', 'Nisha', 'Rohan', 'Ishaan', 'Diya', 'Mehul', 'Anaya',
      'Vivaan', 'Tara', 'Kavya', 'Aryan', 'Zoya', 'Dev', 'Manya', 'Reyansh',
      'Saanvi', 'Yash', 'Pari', 'Advik'
    ])[1 + (n % 20)]
    || ' ' ||
    (array[
      'Verma', 'Singh', 'Patel', 'Joshi', 'Reddy', 'Sharma', 'Gupta', 'Nair',
      'Bose', 'Mehta', 'Yadav', 'Iyer', 'Choudhary', 'Das', 'Agarwal', 'Khan',
      'Mishra', 'Kapoor', 'Bansal', 'Saxena'
    ])[1 + ((n * 3) % 20)]
  ) as student_name,
  (6 + (n % 5))::text as class_name,
  (array['A', 'B', 'C', 'D'])[1 + (n % 4)] as section,
  (array['General', 'EWS', 'OBC', 'SC', 'ST', 'Minority'])[1 + (n % 6)] as category,
  '+91 98765 ' || lpad((10000 + n)::text, 5, '0') as phone
from generate_series(5, 50) as generated(n);

insert into guardians (id, school_id, name, phone, email, address)
select
  guardian_id,
  school_id,
  'Guardian of ' || student_name,
  phone,
  lower(replace(student_name, ' ', '.')) || '.guardian@example.com',
  'Verification address ' || n || ', Jaipur'
from large_seed_students
on conflict (id) do update set
  name = excluded.name,
  phone = excluded.phone,
  email = excluded.email,
  address = excluded.address;

insert into students (
  id,
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
select
  student_id,
  school_id,
  guardian_id,
  admission_no,
  student_name,
  class_name,
  section,
  category,
  phone,
  case when n % 17 = 0 then 'inactive' else 'active' end
from large_seed_students
on conflict (id) do update set
  guardian_id = excluded.guardian_id,
  admission_no = excluded.admission_no,
  name = excluded.name,
  class_name = excluded.class_name,
  section = excluded.section,
  category = excluded.category,
  phone = excluded.phone,
  status = excluded.status;

insert into fee_rules (id, school_id, fee_head_id, title, amount, scope_label, frequency, due_date, late_fee_amount)
values
  (
    '51000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000002',
    'Transport Route Fee 2026',
    9000,
    'Bus route users',
    'Term',
    current_date + 15,
    250
  ),
  (
    '52000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000003',
    'Exam Fee Cycle 1',
    2500,
    'Classes 6-10',
    'Term',
    current_date + 30,
    0
  )
on conflict (id) do update set
  title = excluded.title,
  amount = excluded.amount,
  scope_label = excluded.scope_label,
  frequency = excluded.frequency,
  due_date = excluded.due_date,
  late_fee_amount = excluded.late_fee_amount;

insert into fee_demands (id, school_id, student_id, fee_head_id, amount, due_date, status)
select
  ('61000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid,
  school_id,
  student_id,
  '30000000-0000-0000-0000-000000000001',
  22000 + ((n % 5) * 2500),
  current_date - ((n % 24)::int),
  'open'
from large_seed_students
on conflict (id) do update set
  amount = excluded.amount,
  due_date = excluded.due_date,
  status = excluded.status;

insert into fee_demands (id, school_id, student_id, fee_head_id, amount, due_date, status)
select
  ('62000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid,
  school_id,
  student_id,
  '30000000-0000-0000-0000-000000000002',
  7000 + ((n % 4) * 1000),
  current_date + ((n % 18)::int),
  'open'
from large_seed_students
where n % 3 <> 0
on conflict (id) do update set
  amount = excluded.amount,
  due_date = excluded.due_date,
  status = excluded.status;

insert into fee_demands (id, school_id, student_id, fee_head_id, amount, due_date, status)
select
  ('63000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid,
  school_id,
  student_id,
  '30000000-0000-0000-0000-000000000003',
  2500,
  current_date + 30,
  'open'
from large_seed_students
where n % 4 = 0
on conflict (id) do update set
  amount = excluded.amount,
  due_date = excluded.due_date,
  status = excluded.status;

insert into concessions (
  id,
  school_id,
  student_id,
  category,
  concession_type,
  amount,
  funding_source,
  status,
  reason,
  approved_by
)
select
  ('71000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid,
  school_id,
  student_id,
  category,
  case
    when category = 'EWS' then 'RTE/EWS tuition waiver'
    when category in ('SC', 'ST') then 'Welfare-linked support'
    else 'Need-based fee support'
  end,
  case
    when category = 'EWS' then 12000
    when category in ('SC', 'ST') then 8000
    else 5000
  end,
  case
    when category = 'EWS' then 'RTE reimbursement receivable'
    when category in ('SC', 'ST') then 'Scholarship receivable'
    else 'School waiver'
  end,
  case
    when n % 4 = 0 then 'approved'::concession_status
    when n % 4 = 1 then 'submitted'::concession_status
    when n % 4 = 2 then 'draft'::concession_status
    else 'rejected'::concession_status
  end,
  'Verification dataset: certificate and guardian consent tracked for review.',
  case when n % 4 = 0 then '40000000-0000-0000-0000-000000000002'::uuid else null end
from large_seed_students
where category in ('EWS', 'SC', 'ST', 'Minority')
on conflict (id) do update set
  category = excluded.category,
  concession_type = excluded.concession_type,
  amount = excluded.amount,
  funding_source = excluded.funding_source,
  status = excluded.status,
  reason = excluded.reason,
  approved_by = excluded.approved_by;

drop table if exists pg_temp.large_seed_payments;

create temporary table large_seed_payments as
select
  row_number() over (order by n) + 3 as receipt_seq,
  n,
  school_id,
  student_id,
  ('81000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid as payment_id,
  case
    when n % 4 = 0 then 'upi'::payment_mode
    when n % 4 = 1 then 'cash'::payment_mode
    when n % 4 = 2 then 'bank_transfer'::payment_mode
    else 'cheque'::payment_mode
  end as mode,
  9000 + ((n % 6) * 1500) as amount
from large_seed_students
where n between 5 and 32;

insert into payments (
  id,
  school_id,
  student_id,
  amount,
  mode,
  status,
  cheque_status,
  reference_no,
  receipt_no,
  note,
  paid_at
)
select
  payment_id,
  school_id,
  student_id,
  amount,
  mode,
  case when mode = 'cheque' then 'pending'::payment_status else 'completed'::payment_status end,
  case when mode = 'cheque' then 'deposited'::cheque_status else null end,
  case
    when mode = 'upi' then 'UPI-DEMO-' || lpad(n::text, 3, '0')
    when mode = 'cash' then 'CASH-DEMO-' || lpad(n::text, 3, '0')
    when mode = 'bank_transfer' then 'NEFT-DEMO-' || lpad(n::text, 3, '0')
    else 'CHQ-DEMO-' || lpad(n::text, 3, '0')
  end,
  format('VL/2026/SEED-%s', lpad(receipt_seq::text, 4, '0')),
  'Verification payment sample',
  now() - ((n % 12) || ' days')::interval
from large_seed_payments
on conflict (id) do update set
  amount = excluded.amount,
  mode = excluded.mode,
  status = excluded.status,
  cheque_status = excluded.cheque_status,
  reference_no = excluded.reference_no,
  receipt_no = excluded.receipt_no,
  note = excluded.note,
  paid_at = excluded.paid_at;

insert into receipts (id, school_id, payment_id, receipt_no, pdf_url, issued_at)
select
  ('82000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid,
  school_id,
  payment_id,
  format('VL/2026/SEED-%s', lpad(receipt_seq::text, 4, '0')),
  null,
  now() - ((n % 12) || ' days')::interval
from large_seed_payments
on conflict (id) do update set
  receipt_no = excluded.receipt_no,
  issued_at = excluded.issued_at;

insert into reconciliation_items (id, school_id, payment_id, channel_ref, status, exception_reason)
select
  ('91000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid,
  school_id,
  payment_id,
  case
    when mode = 'upi' then 'UPI settlement batch ' || lpad((n % 7 + 1)::text, 2, '0')
    when mode = 'bank_transfer' then 'Bank statement line ' || lpad(n::text, 3, '0')
    when mode = 'cash' then 'Cash counter close ' || lpad((n % 5 + 1)::text, 2, '0')
    else 'Cheque clearing queue'
  end,
  case
    when mode = 'cheque' then 'unmatched'::reconciliation_status
    when n % 13 = 0 then 'partial'::reconciliation_status
    when n % 11 = 0 then 'duplicate'::reconciliation_status
    else 'matched'::reconciliation_status
  end,
  case
    when mode = 'cheque' then 'Awaiting bank confirmation'
    when n % 13 = 0 then 'Gateway amount differs from receipt'
    when n % 11 = 0 then 'Possible duplicate settlement reference'
    else ''
  end
from large_seed_payments
on conflict (id) do update set
  channel_ref = excluded.channel_ref,
  status = excluded.status,
  exception_reason = excluded.exception_reason;

insert into ledger_entries (
  id,
  school_id,
  voucher_no,
  debit_ledger,
  credit_ledger,
  amount,
  entry_date,
  narration
)
select
  ('b1000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid,
  school_id,
  'FEE-DEMAND-' || admission_no,
  'Student Fee Receivable',
  'Tuition Fee Income',
  22000 + ((n % 5) * 2500),
  current_date - ((n % 24)::int),
  'Tuition demand posted for ' || student_name
from large_seed_students
on conflict (id) do update set
  amount = excluded.amount,
  entry_date = excluded.entry_date,
  narration = excluded.narration;

insert into ledger_entries (
  id,
  school_id,
  voucher_no,
  debit_ledger,
  credit_ledger,
  amount,
  entry_date,
  narration
)
select
  ('b2000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid,
  school_id,
  'RCPT-' || format('VL-2026-SEED-%s', lpad(receipt_seq::text, 4, '0')),
  case
    when mode = 'cash' then 'Cash in Hand'
    when mode = 'cheque' then 'Cheque Clearing'
    else 'Bank Account'
  end,
  'Student Fee Receivable',
  amount,
  current_date - ((n % 12)::int),
  'Receipt ledger entry for verification payment'
from large_seed_payments
on conflict (id) do update set
  amount = excluded.amount,
  entry_date = excluded.entry_date,
  narration = excluded.narration;

insert into audit_logs (id, school_id, user_id, actor, action, object_type, object_id)
values
  (
    'a1000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    'Sanchit Gupta',
    'Loaded 50-student verification dataset with demands, concessions, receipts, reconciliation, and ledger entries',
    'seed',
    null
  )
on conflict (id) do update set
  action = excluded.action,
  created_at = now();

select
  (select count(*) from students where school_id = '00000000-0000-0000-0000-000000000001') as student_count,
  (select count(*) from fee_demands where school_id = '00000000-0000-0000-0000-000000000001') as fee_demand_count,
  (select count(*) from concessions where school_id = '00000000-0000-0000-0000-000000000001') as concession_count,
  (select count(*) from payments where school_id = '00000000-0000-0000-0000-000000000001') as payment_count,
  (select count(*) from ledger_entries where school_id = '00000000-0000-0000-0000-000000000001') as ledger_entry_count;
