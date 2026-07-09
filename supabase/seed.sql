insert into schools (
  id,
  name,
  board,
  state,
  district,
  school_type,
  academic_year,
  address,
  contact_email,
  contact_phone
)
values (
  '00000000-0000-0000-0000-000000000001',
  'Vidya Public School',
  'CBSE',
  'Rajasthan',
  'Jaipur',
  'Unaided Private School',
  '2026-27',
  'Sector 12, Jaipur, Rajasthan',
  'office@vidyapublic.demo',
  '+91 141 400 2026'
);

insert into class_sections (
  id,
  school_id,
  class_name,
  section,
  class_teacher,
  room_label,
  capacity,
  active
)
values
  ('51000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '6', 'A', 'Nisha Verma', 'Room 201', 45, true),
  ('51000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '7', 'A', 'Anil Sharma', 'Room 205', 45, true),
  ('51000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '8', 'B', 'Farah Khan', 'Room 302', 42, true),
  ('51000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '9', 'C', 'Ravi Meena', 'Room 401', 40, true);

insert into guardians (id, school_id, name, phone, email, address)
values
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Meera Sharma', '+91 98765 10001', 'meera.sharma@example.com', 'Sector 12, Jaipur'),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Ramesh Kumar', '+91 98765 10002', 'ramesh.kumar@example.com', 'Ashok Nagar, Patna'),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Farida Khan', '+91 98765 10003', 'farida.khan@example.com', 'Bandra East, Mumbai'),
  ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Lakshmi Murmu', '+91 98765 10004', 'lakshmi.murmu@example.com', 'Ranchi, Jharkhand');

insert into users (id, school_id, name, email, role, guardian_id)
values
  ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Sanchit Gupta', 'admin@vidyaledger.demo', 'admin', null),
  ('40000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Principal Rao', 'principal@vidyaledger.demo', 'principal', null),
  ('40000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Neha Accountant', 'accounts@vidyaledger.demo', 'accountant', null),
  ('40000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Fee Clerk', 'clerk@vidyaledger.demo', 'clerk', null),
  ('40000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'Meera Sharma', 'parent@vidyaledger.demo', 'parent', '10000000-0000-0000-0000-000000000001');

insert into students (id, school_id, guardian_id, admission_no, name, class_name, section, category, phone)
values
  ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'VL-2026-001', 'Asha Sharma', '7', 'A', 'EWS', '+91 98765 10001'),
  ('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', 'VL-2026-002', 'Arjun Kumar', '8', 'B', 'SC', '+91 98765 10002'),
  ('20000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000003', 'VL-2026-003', 'Sara Khan', '6', 'A', 'Minority', '+91 98765 10003'),
  ('20000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000004', 'VL-2026-004', 'Birsa Murmu', '9', 'C', 'ST', '+91 98765 10004');

insert into fee_heads (id, school_id, name, ledger, refundable, active)
values
  ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Tuition Fee', 'Tuition Fee Income', false, true),
  ('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Transport Fee', 'Transport Fee Income', false, true),
  ('30000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Exam Fee', 'Exam Fee Income', false, true),
  ('30000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Caution Deposit', 'Refundable Deposit Liability', true, true);

insert into fee_rules (id, school_id, fee_head_id, title, amount, scope_label, frequency, due_date, late_fee_amount)
values
  ('50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'Annual Tuition 2026', 30000, 'Classes 6-9', 'Annual', current_date - 15, 500);

insert into fee_demands (id, school_id, student_id, fee_head_id, amount, due_date, status)
values
  ('60000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 30000, current_date - 12, 'open'),
  ('60000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', 8000, current_date + 5, 'open'),
  ('60000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001', 32000, current_date - 20, 'open'),
  ('60000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000001', 28000, current_date + 10, 'open'),
  ('60000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000001', 34000, current_date - 7, 'open');

insert into concessions (id, school_id, student_id, category, concession_type, amount, funding_source, status, reason, approved_by)
values
  ('70000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'EWS', 'Need-based tuition support', 15000, 'School waiver', 'approved', 'Verified income certificate for 2026-27.', '40000000-0000-0000-0000-000000000002'),
  ('70000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', 'SC', 'Welfare-linked support', 8000, 'Scholarship receivable', 'submitted', 'Certificate verified; approval pending.', null);

insert into payments (id, school_id, student_id, amount, mode, status, cheque_status, reference_no, receipt_no, note, paid_at)
values
  ('80000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 10000, 'upi', 'completed', null, 'UPI145322', 'VL/2026/0001', 'Partial tuition fee', now() - interval '3 days'),
  ('80000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003', 28000, 'bank_transfer', 'completed', null, 'NEFT7731', 'VL/2026/0002', 'Term tuition payment', now() - interval '1 day'),
  ('80000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000004', 12000, 'cheque', 'pending', 'deposited', 'CHQ219873', 'VL/2026/0003', 'Cheque awaiting clearance', now());

insert into reconciliation_items (id, school_id, payment_id, channel_ref, status, exception_reason)
values
  ('90000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '80000000-0000-0000-0000-000000000001', 'UPI settlement batch 04', 'matched', ''),
  ('90000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '80000000-0000-0000-0000-000000000002', 'Bank statement NEFT7731', 'matched', ''),
  ('90000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '80000000-0000-0000-0000-000000000003', 'Cheque clearing queue', 'unmatched', 'Awaiting bank confirmation');

insert into audit_logs (id, school_id, user_id, actor, action, object_type, object_id)
values
  ('a0000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000002', 'Principal Rao', 'Approved EWS concession for Asha Sharma', 'concession', '70000000-0000-0000-0000-000000000001');
