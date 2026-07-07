import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../providers/app_state.dart';

class FinanceSnapshot {
  const FinanceSnapshot({
    required this.school,
    required this.users,
    required this.guardians,
    required this.students,
    required this.feeHeads,
    required this.feeRules,
    required this.feeDemands,
    required this.concessions,
    required this.payments,
    required this.reconciliationItems,
    required this.auditLogs,
  });

  final SchoolProfile school;
  final List<AppUser> users;
  final List<Guardian> guardians;
  final List<Student> students;
  final List<FeeHead> feeHeads;
  final List<FeeRule> feeRules;
  final List<FeeDemand> feeDemands;
  final List<Concession> concessions;
  final List<Payment> payments;
  final List<ReconciliationItem> reconciliationItems;
  final List<AuditLog> auditLogs;

  AppState toAppState({AppUser? currentUser}) {
    return AppState(
      currentUser: currentUser,
      school: school,
      users: users,
      guardians: guardians,
      students: students,
      feeHeads: feeHeads,
      feeRules: feeRules,
      feeDemands: feeDemands,
      concessions: concessions,
      payments: payments,
      reconciliationItems: reconciliationItems,
      auditLogs: auditLogs,
    );
  }
}

class SupabaseFinanceService {
  SupabaseFinanceService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  Future<void> signIn({required String email, required String password}) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<AppUser> loadCurrentAppUser() async {
    final row = await _currentUserRow();
    return _userFromRow(row);
  }

  Future<FinanceSnapshot> loadSnapshot() async {
    final results = await Future.wait<List<Map<String, dynamic>>>([
      _selectTable('schools'),
      _selectTable('users', orderBy: 'name'),
      _selectTable('guardians', orderBy: 'name'),
      _selectTable('students', orderBy: 'admission_no'),
      _selectTable('fee_heads', orderBy: 'name'),
      _selectTable('fee_rules', orderBy: 'due_date'),
      _selectTable('fee_demands', orderBy: 'due_date'),
      _selectTable('concessions', orderBy: 'created_at'),
      _selectTable('payments', orderBy: 'paid_at'),
      _selectTable('reconciliation_items'),
      _selectTable('audit_logs', orderBy: 'created_at'),
    ]);

    return FinanceSnapshot(
      school: results[0].isEmpty
          ? AppState.seeded().school
          : _schoolFromRow(results[0].first),
      users: results[1].map(_userFromRow).toList(),
      guardians: results[2].map(_guardianFromRow).toList(),
      students: results[3].map(_studentFromRow).toList(),
      feeHeads: results[4].map(_feeHeadFromRow).toList(),
      feeRules: results[5].map(_feeRuleFromRow).toList(),
      feeDemands: results[6].map(_feeDemandFromRow).toList(),
      concessions: results[7].map(_concessionFromRow).toList(),
      payments: results[8].map(_paymentFromRow).toList(),
      reconciliationItems: results[9].map(_reconciliationFromRow).toList(),
      auditLogs: results[10].map(_auditLogFromRow).toList(),
    );
  }

  Future<Payment> recordPayment({
    required String studentId,
    required double amount,
    required PaymentMode mode,
    required String referenceNo,
    required String note,
  }) async {
    final data = await client.rpc(
      'record_payment_with_receipt',
      params: {
        'p_student_id': studentId,
        'p_amount': amount,
        'p_mode': _paymentModeDb(mode),
        'p_reference_no': referenceNo,
        'p_note': note,
        'p_idempotency_key': _paymentIdempotencyKey(
          studentId: studentId,
          amount: amount,
          mode: mode,
          referenceNo: referenceNo,
        ),
      },
    );
    return _paymentFromRow(_singleRowFromRpc(data));
  }

  Future<int> generateFeeDemand({
    required String feeHeadId,
    required String title,
    required double amount,
    required String className,
    required DateTime dueDate,
    required double lateFeeAmount,
  }) async {
    final data = await client.rpc(
      'generate_fee_demand_for_class',
      params: {
        'p_fee_head_id': feeHeadId,
        'p_title': title,
        'p_amount': amount,
        'p_class_name': className,
        'p_due_date': _dateOnly(dueDate),
        'p_late_fee_amount': lateFeeAmount,
        'p_frequency': 'Term',
      },
    );
    return _toInt(_singleRowFromRpc(data)['demand_count']);
  }

  Future<Student> addStudentWithGuardian({
    required String admissionNo,
    required String studentName,
    required String className,
    required String section,
    required String category,
    required String studentPhone,
    required String guardianName,
    required String guardianPhone,
    required String guardianEmail,
    required String guardianAddress,
  }) async {
    final data = await client.rpc(
      'create_student_with_guardian',
      params: {
        'p_admission_no': admissionNo,
        'p_student_name': studentName,
        'p_class_name': className,
        'p_section': section,
        'p_category': category,
        'p_student_phone': studentPhone,
        'p_guardian_name': guardianName,
        'p_guardian_phone': guardianPhone,
        'p_guardian_email': guardianEmail,
        'p_guardian_address': guardianAddress,
      },
    );
    return _studentFromRow(_singleRowFromRpc(data));
  }

  Future<Concession> submitConcession({
    required String studentId,
    required String category,
    required String concessionType,
    required double amount,
    required String fundingSource,
    required String reason,
  }) async {
    final data = await client.rpc(
      'submit_concession_request',
      params: {
        'p_student_id': studentId,
        'p_category': category,
        'p_concession_type': concessionType,
        'p_amount': amount,
        'p_funding_source': fundingSource,
        'p_reason': reason,
      },
    );
    return _concessionFromRow(_singleRowFromRpc(data));
  }

  Future<Concession> updateConcessionStatus(
    String concessionId,
    ConcessionStatus status,
  ) async {
    final data = await client.rpc(
      'update_concession_decision',
      params: {
        'p_concession_id': concessionId,
        'p_status': _concessionStatusDb(status),
      },
    );
    return _concessionFromRow(_singleRowFromRpc(data));
  }

  Future<ReconciliationItem> updateReconciliation({
    required String reconciliationId,
    required ReconciliationStatus status,
    required String reason,
  }) async {
    final data = await client.rpc(
      'update_reconciliation_status',
      params: {
        'p_reconciliation_id': reconciliationId,
        'p_status': _reconciliationStatusDb(status),
        'p_exception_reason': reason,
      },
    );
    return _reconciliationFromRow(_singleRowFromRpc(data));
  }

  Future<Payment> updateChequeStatus(
    String paymentId,
    ChequeStatus chequeStatus,
  ) async {
    final userRow = await _currentUserRow();
    final paymentStatus = chequeStatus == ChequeStatus.cleared
        ? PaymentStatus.completed
        : chequeStatus == ChequeStatus.bounced
        ? PaymentStatus.bounced
        : PaymentStatus.pending;
    final updated = await client
        .from('payments')
        .update({
          'status': _paymentStatusDb(paymentStatus),
          'cheque_status': _chequeStatusDb(chequeStatus),
          'note': 'Cheque ${chequeStatus.name}',
        })
        .eq('id', paymentId)
        .select()
        .single();
    final payment = _paymentFromRow(Map<String, dynamic>.from(updated as Map));
    await _insertAuditLog(
      userRow: userRow,
      action: 'Marked cheque $paymentId as ${chequeStatus.name}',
      objectType: 'payment',
      objectId: paymentId,
    );
    return payment;
  }

  Future<List<Map<String, dynamic>>> _selectTable(
    String table, {
    String? orderBy,
  }) async {
    dynamic query = client.from(table).select();
    if (orderBy != null) {
      query = query.order(orderBy);
    }
    final data = await query;
    final rows = data as List<dynamic>;
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<Map<String, dynamic>> _currentUserRow() async {
    final authUser = client.auth.currentUser;
    if (authUser == null) {
      throw StateError('No Supabase user is signed in.');
    }
    final row = await client
        .from('users')
        .select()
        .eq('auth_user_id', authUser.id)
        .single();
    return Map<String, dynamic>.from(row as Map);
  }

  Future<void> _insertAuditLog({
    required Map<String, dynamic> userRow,
    required String action,
    required String objectType,
    String? objectId,
  }) async {
    await client.from('audit_logs').insert({
      'school_id': userRow['school_id'],
      'user_id': userRow['id'],
      'actor': userRow['name'],
      'action': action,
      'object_type': objectType,
      'object_id': objectId,
    });
  }

  AppUser _userFromRow(Map<String, dynamic> row) {
    return AppUser(
      id: row['id'].toString(),
      name: row['name']?.toString() ?? '',
      email: row['email']?.toString() ?? '',
      role: _userRole(row['role']?.toString()),
      guardianId: row['guardian_id']?.toString(),
    );
  }

  SchoolProfile _schoolFromRow(Map<String, dynamic> row) {
    return SchoolProfile(
      id: row['id'].toString(),
      name: row['name']?.toString() ?? 'School',
      board: row['board']?.toString() ?? '',
      state: row['state']?.toString() ?? '',
      district: row['district']?.toString() ?? '',
      schoolType: row['school_type']?.toString() ?? '',
      academicYear: row['academic_year']?.toString() ?? '',
    );
  }

  Map<String, dynamic> _singleRowFromRpc(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    throw StateError('Supabase did not return a payment row.');
  }

  Guardian _guardianFromRow(Map<String, dynamic> row) {
    return Guardian(
      id: row['id'].toString(),
      name: row['name']?.toString() ?? '',
      phone: row['phone']?.toString() ?? '',
      email: row['email']?.toString() ?? '',
      address: row['address']?.toString() ?? '',
    );
  }

  Student _studentFromRow(Map<String, dynamic> row) {
    return Student(
      id: row['id'].toString(),
      admissionNo: row['admission_no']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      className: row['class_name']?.toString() ?? '',
      section: row['section']?.toString() ?? '',
      guardianId: row['guardian_id']?.toString() ?? '',
      category: row['category']?.toString() ?? '',
      phone: row['phone']?.toString() ?? '',
      status: row['status']?.toString() ?? 'active',
    );
  }

  FeeHead _feeHeadFromRow(Map<String, dynamic> row) {
    return FeeHead(
      id: row['id'].toString(),
      name: row['name']?.toString() ?? '',
      ledger: row['ledger']?.toString() ?? '',
      refundable: row['refundable'] == true,
      active: row['active'] != false,
    );
  }

  FeeRule _feeRuleFromRow(Map<String, dynamic> row) {
    return FeeRule(
      id: row['id'].toString(),
      feeHeadId: row['fee_head_id']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      amount: _toDouble(row['amount']),
      scopeLabel: row['scope_label']?.toString() ?? '',
      frequency: row['frequency']?.toString() ?? '',
      dueDate: _toDate(row['due_date']),
      lateFeeAmount: _toDouble(row['late_fee_amount']),
    );
  }

  FeeDemand _feeDemandFromRow(Map<String, dynamic> row) {
    return FeeDemand(
      id: row['id'].toString(),
      studentId: row['student_id']?.toString() ?? '',
      feeHeadId: row['fee_head_id']?.toString() ?? '',
      amount: _toDouble(row['amount']),
      dueDate: _toDate(row['due_date']),
      status: row['status']?.toString() ?? 'open',
    );
  }

  Concession _concessionFromRow(Map<String, dynamic> row) {
    return Concession(
      id: row['id'].toString(),
      studentId: row['student_id']?.toString() ?? '',
      category: row['category']?.toString() ?? '',
      concessionType: row['concession_type']?.toString() ?? '',
      amount: _toDouble(row['amount']),
      fundingSource: row['funding_source']?.toString() ?? '',
      status: _concessionStatus(row['status']?.toString()),
      reason: row['reason']?.toString() ?? '',
      createdAt: _toDate(row['created_at']),
      approvedBy: row['approved_by']?.toString(),
    );
  }

  Payment _paymentFromRow(Map<String, dynamic> row) {
    return Payment(
      id: row['id'].toString(),
      studentId: row['student_id']?.toString() ?? '',
      amount: _toDouble(row['amount']),
      mode: _paymentMode(row['mode']?.toString()),
      status: _paymentStatus(row['status']?.toString()),
      date: _toDate(row['paid_at']),
      referenceNo: row['reference_no']?.toString() ?? '',
      receiptNo: row['receipt_no']?.toString() ?? '',
      note: row['note']?.toString() ?? '',
      chequeStatus: _nullableChequeStatus(row['cheque_status']?.toString()),
    );
  }

  ReconciliationItem _reconciliationFromRow(Map<String, dynamic> row) {
    return ReconciliationItem(
      id: row['id'].toString(),
      paymentId: row['payment_id']?.toString() ?? '',
      channelRef: row['channel_ref']?.toString() ?? '',
      status: _reconciliationStatus(row['status']?.toString()),
      exceptionReason: row['exception_reason']?.toString() ?? '',
    );
  }

  AuditLog _auditLogFromRow(Map<String, dynamic> row) {
    return AuditLog(
      id: row['id'].toString(),
      actor: row['actor']?.toString() ?? '',
      action: row['action']?.toString() ?? '',
      objectType: row['object_type']?.toString() ?? '',
      createdAt: _toDate(row['created_at']),
    );
  }

  UserRole _userRole(String? value) {
    return switch (value) {
      'principal' => UserRole.principal,
      'accountant' => UserRole.accountant,
      'clerk' => UserRole.clerk,
      'parent' => UserRole.parent,
      _ => UserRole.admin,
    };
  }

  PaymentMode _paymentMode(String? value) {
    return switch (value) {
      'cash' => PaymentMode.cash,
      'cheque' => PaymentMode.cheque,
      'bank_transfer' => PaymentMode.bankTransfer,
      _ => PaymentMode.upi,
    };
  }

  PaymentStatus _paymentStatus(String? value) {
    return switch (value) {
      'pending' => PaymentStatus.pending,
      'bounced' => PaymentStatus.bounced,
      'reversed' => PaymentStatus.reversed,
      _ => PaymentStatus.completed,
    };
  }

  ChequeStatus? _nullableChequeStatus(String? value) {
    return switch (value) {
      'received' => ChequeStatus.received,
      'deposited' => ChequeStatus.deposited,
      'cleared' => ChequeStatus.cleared,
      'bounced' => ChequeStatus.bounced,
      _ => null,
    };
  }

  ConcessionStatus _concessionStatus(String? value) {
    return switch (value) {
      'draft' => ConcessionStatus.draft,
      'approved' => ConcessionStatus.approved,
      'rejected' => ConcessionStatus.rejected,
      _ => ConcessionStatus.submitted,
    };
  }

  ReconciliationStatus _reconciliationStatus(String? value) {
    return switch (value) {
      'matched' => ReconciliationStatus.matched,
      'duplicate' => ReconciliationStatus.duplicate,
      'partial' => ReconciliationStatus.partial,
      'overpaid' => ReconciliationStatus.overpaid,
      _ => ReconciliationStatus.unmatched,
    };
  }

  String _paymentModeDb(PaymentMode value) {
    return switch (value) {
      PaymentMode.cash => 'cash',
      PaymentMode.cheque => 'cheque',
      PaymentMode.bankTransfer => 'bank_transfer',
      PaymentMode.upi => 'upi',
    };
  }

  String _paymentIdempotencyKey({
    required String studentId,
    required double amount,
    required PaymentMode mode,
    required String referenceNo,
  }) {
    final normalizedReference = referenceNo.trim().isEmpty
        ? 'no-reference-${DateTime.now().microsecondsSinceEpoch}'
        : referenceNo.trim().toLowerCase();
    return [
      'manual-payment',
      studentId,
      _paymentModeDb(mode),
      amount.toStringAsFixed(2),
      normalizedReference,
    ].join(':');
  }

  String _paymentStatusDb(PaymentStatus value) {
    return switch (value) {
      PaymentStatus.pending => 'pending',
      PaymentStatus.bounced => 'bounced',
      PaymentStatus.reversed => 'reversed',
      PaymentStatus.completed => 'completed',
    };
  }

  String _chequeStatusDb(ChequeStatus value) {
    return switch (value) {
      ChequeStatus.received => 'received',
      ChequeStatus.deposited => 'deposited',
      ChequeStatus.cleared => 'cleared',
      ChequeStatus.bounced => 'bounced',
    };
  }

  String _concessionStatusDb(ConcessionStatus value) {
    return switch (value) {
      ConcessionStatus.draft => 'draft',
      ConcessionStatus.submitted => 'submitted',
      ConcessionStatus.approved => 'approved',
      ConcessionStatus.rejected => 'rejected',
    };
  }

  String _reconciliationStatusDb(ReconciliationStatus value) {
    return switch (value) {
      ReconciliationStatus.unmatched => 'unmatched',
      ReconciliationStatus.matched => 'matched',
      ReconciliationStatus.duplicate => 'duplicate',
      ReconciliationStatus.partial => 'partial',
      ReconciliationStatus.overpaid => 'overpaid',
    };
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  DateTime _toDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
