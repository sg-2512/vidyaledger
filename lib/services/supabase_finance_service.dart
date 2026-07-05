import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../providers/app_state.dart';

class FinanceSnapshot {
  const FinanceSnapshot({
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

  Future<FinanceSnapshot> loadSnapshot() async {
    final results = await Future.wait<List<Map<String, dynamic>>>([
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
      users: results[0].map(_userFromRow).toList(),
      guardians: results[1].map(_guardianFromRow).toList(),
      students: results[2].map(_studentFromRow).toList(),
      feeHeads: results[3].map(_feeHeadFromRow).toList(),
      feeRules: results[4].map(_feeRuleFromRow).toList(),
      feeDemands: results[5].map(_feeDemandFromRow).toList(),
      concessions: results[6].map(_concessionFromRow).toList(),
      payments: results[7].map(_paymentFromRow).toList(),
      reconciliationItems: results[8].map(_reconciliationFromRow).toList(),
      auditLogs: results[9].map(_auditLogFromRow).toList(),
    );
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
    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
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

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _toDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
