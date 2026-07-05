insert into schools (id, name, board, state, district, school_type, academic_year)
values (
  '00000000-0000-0000-0000-000000000001',
  'Vidya Public School',
  'CBSE',
  'Rajasthan',
  'Jaipur',
  'Unaided Private School',
  '2026-27'
);

insert into guardians (id, school_id, name, phone, email, address)
values
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Meera Sharma', '+91 98765 10001', 'meera.sharma@example.com', 'Sector 12, Jaipur'),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Ramesh Kumar', '+91 98765 10002', 'ramesh.kumar@example.com', 'Ashok Nagar, Patna'),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Farida Khan', '+91 98765 10003', 'farida.khan@example.com', 'Bandra East, Mumbai'),
  ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Lakshmi Murmu', '+91 98765 10004', 'lakshmi.murmu@example.com', 'Ranchi, Jharkhand');

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
  ('30000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Exam Fee', 'Exam Fee Income', false, true);

insert into fee_demands (school_id, student_id, fee_head_id, amount, due_date, status)
values
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 30000, current_date - 12, 'open'),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001', 32000, current_date - 20, 'open'),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000001', 28000, current_date + 10, 'open'),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000001', 34000, current_date - 7, 'open');

insert into concessions (school_id, student_id, category, concession_type, amount, funding_source, status, reason)
values
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'EWS', 'Need-based tuition support', 15000, 'School waiver', 'approved', 'Verified income certificate for 2026-27.'),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', 'SC', 'Welfare-linked support', 8000, 'Scholarship receivable', 'submitted', 'Certificate verified; approval pending.');

insert into payments (school_id, student_id, amount, mode, status, reference_no, receipt_no, note)
values
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 10000, 'upi', 'completed', 'UPI145322', 'VL/2026/0001', 'Partial tuition fee'),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003', 28000, 'bank_transfer', 'completed', 'NEFT7731', 'VL/2026/0002', 'Term tuition payment');
