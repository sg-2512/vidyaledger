import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';

final appControllerProvider =
    NotifierProvider<AppController, AppState>(AppController.new);

class AppState {
  const AppState({
    required this.currentUser,
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

  final AppUser? currentUser;
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

  factory AppState.seeded() {
    final now = DateTime.now();
    final guardians = [
      const Guardian(
        id: 'g-1',
        name: 'Meera Sharma',
        phone: '+91 98765 10001',
        email: 'meera.sharma@example.com',
        address: 'Sector 12, Jaipur, Rajasthan',
      ),
      const Guardian(
        id: 'g-2',
        name: 'Ramesh Kumar',
        phone: '+91 98765 10002',
        email: 'ramesh.kumar@example.com',
        address: 'Ashok Nagar, Patna, Bihar',
      ),
      const Guardian(
        id: 'g-3',
        name: 'Farida Khan',
        phone: '+91 98765 10003',
        email: 'farida.khan@example.com',
        address: 'Bandra East, Mumbai, Maharashtra',
      ),
      const Guardian(
        id: 'g-4',
        name: 'Lakshmi Murmu',
        phone: '+91 98765 10004',
        email: 'lakshmi.murmu@example.com',
        address: 'Ranchi, Jharkhand',
      ),
    ];
    final students = [
      const Student(
        id: 's-1',
        admissionNo: 'VL-2026-001',
        name: 'Asha Sharma',
        className: '7',
        section: 'A',
        guardianId: 'g-1',
        category: 'EWS',
        phone: '+91 98765 10001',
        status: 'Active',
      ),
      const Student(
        id: 's-2',
        admissionNo: 'VL-2026-002',
        name: 'Arjun Kumar',
        className: '8',
        section: 'B',
        guardianId: 'g-2',
        category: 'SC',
        phone: '+91 98765 10002',
        status: 'Active',
      ),
      const Student(
        id: 's-3',
        admissionNo: 'VL-2026-003',
        name: 'Sara Khan',
        className: '6',
        section: 'A',
        guardianId: 'g-3',
        category: 'Minority',
        phone: '+91 98765 10003',
        status: 'Active',
      ),
      const Student(
        id: 's-4',
        admissionNo: 'VL-2026-004',
        name: 'Birsa Murmu',
        className: '9',
        section: 'C',
        guardianId: 'g-4',
        category: 'ST',
        phone: '+91 98765 10004',
        status: 'Active',
      ),
    ];
    final feeHeads = [
      const FeeHead(
        id: 'fh-1',
        name: 'Tuition Fee',
        ledger: 'Tuition Fee Income',
        refundable: false,
        active: true,
      ),
      const FeeHead(
        id: 'fh-2',
        name: 'Transport Fee',
        ledger: 'Transport Fee Income',
        refundable: false,
        active: true,
      ),
      const FeeHead(
        id: 'fh-3',
        name: 'Exam Fee',
        ledger: 'Exam Fee Income',
        refundable: false,
        active: true,
      ),
      const FeeHead(
        id: 'fh-4',
        name: 'Caution Deposit',
        ledger: 'Refundable Deposit Liability',
        refundable: true,
        active: true,
      ),
    ];
    final feeDemands = [
      FeeDemand(
        id: 'fd-1',
        studentId: 's-1',
        feeHeadId: 'fh-1',
        amount: 30000,
        dueDate: now.subtract(const Duration(days: 12)),
        status: 'open',
      ),
      FeeDemand(
        id: 'fd-2',
        studentId: 's-1',
        feeHeadId: 'fh-2',
        amount: 8000,
        dueDate: now.add(const Duration(days: 5)),
        status: 'open',
      ),
      FeeDemand(
        id: 'fd-3',
        studentId: 's-2',
        feeHeadId: 'fh-1',
        amount: 32000,
        dueDate: now.subtract(const Duration(days: 20)),
        status: 'open',
      ),
      FeeDemand(
        id: 'fd-4',
        studentId: 's-3',
        feeHeadId: 'fh-1',
        amount: 28000,
        dueDate: now.add(const Duration(days: 10)),
        status: 'open',
      ),
      FeeDemand(
        id: 'fd-5',
        studentId: 's-4',
        feeHeadId: 'fh-1',
        amount: 34000,
        dueDate: now.subtract(const Duration(days: 7)),
        status: 'open',
      ),
    ];
    final payments = [
      Payment(
        id: 'p-1',
        studentId: 's-1',
        amount: 10000,
        mode: PaymentMode.upi,
        status: PaymentStatus.completed,
        date: now.subtract(const Duration(days: 3)),
        referenceNo: 'UPI145322',
        receiptNo: 'VL/2026/0001',
        note: 'Partial tuition fee',
      ),
      Payment(
        id: 'p-2',
        studentId: 's-3',
        amount: 28000,
        mode: PaymentMode.bankTransfer,
        status: PaymentStatus.completed,
        date: now.subtract(const Duration(days: 1)),
        referenceNo: 'NEFT7731',
        receiptNo: 'VL/2026/0002',
        note: 'Term tuition payment',
      ),
      Payment(
        id: 'p-3',
        studentId: 's-4',
        amount: 12000,
        mode: PaymentMode.cheque,
        status: PaymentStatus.pending,
        date: now,
        referenceNo: 'CHQ219873',
        receiptNo: 'VL/2026/0003',
        note: 'Cheque awaiting clearance',
        chequeStatus: ChequeStatus.deposited,
      ),
    ];
    return AppState(
      currentUser: null,
      users: const [
        AppUser(
          id: 'u-admin',
          name: 'Sanchit Gupta',
          email: 'admin@vidyaledger.demo',
          role: UserRole.admin,
        ),
        AppUser(
          id: 'u-principal',
          name: 'Principal Rao',
          email: 'principal@vidyaledger.demo',
          role: UserRole.principal,
        ),
        AppUser(
          id: 'u-accountant',
          name: 'Neha Accountant',
          email: 'accounts@vidyaledger.demo',
          role: UserRole.accountant,
        ),
        AppUser(
          id: 'u-clerk',
          name: 'Fee Clerk',
          email: 'clerk@vidyaledger.demo',
          role: UserRole.clerk,
        ),
        AppUser(
          id: 'u-parent',
          name: 'Meera Sharma',
          email: 'parent@vidyaledger.demo',
          role: UserRole.parent,
          guardianId: 'g-1',
        ),
      ],
      guardians: guardians,
      students: students,
      feeHeads: feeHeads,
      feeRules: [
        FeeRule(
          id: 'fr-1',
          feeHeadId: 'fh-1',
          title: 'Annual Tuition 2026',
          amount: 30000,
          scopeLabel: 'Classes 6-9',
          frequency: 'Annual',
          dueDate: now.subtract(const Duration(days: 15)),
          lateFeeAmount: 500,
        ),
      ],
      feeDemands: feeDemands,
      concessions: [
        Concession(
          id: 'c-1',
          studentId: 's-1',
          category: 'EWS',
          concessionType: 'Need-based tuition support',
          amount: 15000,
          fundingSource: 'School waiver',
          status: ConcessionStatus.approved,
          reason: 'Verified income certificate for 2026-27.',
          createdAt: now.subtract(const Duration(days: 8)),
          approvedBy: 'Principal Rao',
        ),
        Concession(
          id: 'c-2',
          studentId: 's-2',
          category: 'SC',
          concessionType: 'Welfare-linked support',
          amount: 8000,
          fundingSource: 'Scholarship receivable',
          status: ConcessionStatus.submitted,
          reason: 'Certificate verified; approval pending.',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ],
      payments: payments,
      reconciliationItems: [
        const ReconciliationItem(
          id: 'r-1',
          paymentId: 'p-1',
          channelRef: 'UPI settlement batch 04',
          status: ReconciliationStatus.matched,
          exceptionReason: '',
        ),
        const ReconciliationItem(
          id: 'r-2',
          paymentId: 'p-2',
          channelRef: 'Bank statement NEFT7731',
          status: ReconciliationStatus.matched,
          exceptionReason: '',
        ),
        const ReconciliationItem(
          id: 'r-3',
          paymentId: 'p-3',
          channelRef: 'Cheque clearing queue',
          status: ReconciliationStatus.unmatched,
          exceptionReason: 'Awaiting bank confirmation',
        ),
      ],
      auditLogs: [
        AuditLog(
          id: 'a-1',
          actor: 'Principal Rao',
          action: 'Approved EWS concession for Asha Sharma',
          objectType: 'concession',
          createdAt: now.subtract(const Duration(days: 8)),
        ),
      ],
    );
  }

  AppState copyWith({
    AppUser? currentUser,
    bool clearCurrentUser = false,
    List<FeeHead>? feeHeads,
    List<FeeRule>? feeRules,
    List<FeeDemand>? feeDemands,
    List<Concession>? concessions,
    List<Payment>? payments,
    List<ReconciliationItem>? reconciliationItems,
    List<AuditLog>? auditLogs,
  }) {
    return AppState(
      currentUser: clearCurrentUser ? null : currentUser ?? this.currentUser,
      users: users,
      guardians: guardians,
      students: students,
      feeHeads: feeHeads ?? this.feeHeads,
      feeRules: feeRules ?? this.feeRules,
      feeDemands: feeDemands ?? this.feeDemands,
      concessions: concessions ?? this.concessions,
      payments: payments ?? this.payments,
      reconciliationItems: reconciliationItems ?? this.reconciliationItems,
      auditLogs: auditLogs ?? this.auditLogs,
    );
  }
}

class AppController extends Notifier<AppState> {
  @override
  AppState build() => AppState.seeded();

  void loginAs(UserRole role) {
    final user = state.users.firstWhere((candidate) => candidate.role == role);
    state = state.copyWith(currentUser: user);
    _audit('${user.name} logged in as ${role.label}', 'auth');
  }

  void logout() {
    state = state.copyWith(clearCurrentUser: true);
  }

  void addFeeHead(String name, String ledger, bool refundable) {
    final feeHead = FeeHead(
      id: _id('fh'),
      name: name,
      ledger: ledger,
      refundable: refundable,
      active: true,
    );
    state = state.copyWith(feeHeads: [...state.feeHeads, feeHead]);
    _audit('Created fee head $name', 'fee_head');
  }

  void generateFeeDemand({
    required String feeHeadId,
    required String title,
    required double amount,
    required String className,
    required DateTime dueDate,
    required double lateFeeAmount,
  }) {
    final rule = FeeRule(
      id: _id('fr'),
      feeHeadId: feeHeadId,
      title: title,
      amount: amount,
      scopeLabel: 'Class $className',
      frequency: 'Term',
      dueDate: dueDate,
      lateFeeAmount: lateFeeAmount,
    );
    final targets =
        state.students.where((student) => student.className == className);
    final demands = targets.map((student) {
      return FeeDemand(
        id: _id('fd'),
        studentId: student.id,
        feeHeadId: feeHeadId,
        amount: amount,
        dueDate: dueDate,
        status: 'open',
      );
    }).toList();
    state = state.copyWith(
      feeRules: [...state.feeRules, rule],
      feeDemands: [...state.feeDemands, ...demands],
    );
    _audit('Generated $title for Class $className', 'fee_demand');
  }

  void submitConcession({
    required String studentId,
    required String category,
    required String concessionType,
    required double amount,
    required String fundingSource,
    required String reason,
  }) {
    final concession = Concession(
      id: _id('c'),
      studentId: studentId,
      category: category,
      concessionType: concessionType,
      amount: amount,
      fundingSource: fundingSource,
      status: ConcessionStatus.submitted,
      reason: reason,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(concessions: [...state.concessions, concession]);
    _audit('Submitted $category concession request', 'concession');
  }

  void updateConcessionStatus(String concessionId, ConcessionStatus status) {
    final actor = state.currentUser?.name ?? 'Demo Admin';
    final updated = state.concessions.map((concession) {
      if (concession.id != concessionId) return concession;
      return concession.copyWith(
        status: status,
        approvedBy: status == ConcessionStatus.approved ? actor : null,
      );
    }).toList();
    state = state.copyWith(concessions: updated);
    _audit('${status.label} concession $concessionId', 'concession');
  }

  Payment recordPayment({
    required String studentId,
    required double amount,
    required PaymentMode mode,
    required String referenceNo,
    required String note,
  }) {
    final receiptNo = 'VL/2026/${(state.payments.length + 1).toString().padLeft(4, '0')}';
    final payment = Payment(
      id: _id('p'),
      studentId: studentId,
      amount: amount,
      mode: mode,
      status: mode == PaymentMode.cheque
          ? PaymentStatus.pending
          : PaymentStatus.completed,
      date: DateTime.now(),
      referenceNo: referenceNo,
      receiptNo: receiptNo,
      note: note,
      chequeStatus:
          mode == PaymentMode.cheque ? ChequeStatus.received : null,
    );
    final reconciliation = ReconciliationItem(
      id: _id('r'),
      paymentId: payment.id,
      channelRef: referenceNo,
      status: mode == PaymentMode.cash
          ? ReconciliationStatus.matched
          : ReconciliationStatus.unmatched,
      exceptionReason:
          mode == PaymentMode.cash ? '' : 'Pending settlement verification',
    );
    state = state.copyWith(
      payments: [...state.payments, payment],
      reconciliationItems: [...state.reconciliationItems, reconciliation],
    );
    _audit('Recorded ${mode.label} payment $receiptNo', 'payment');
    return payment;
  }

  void updateChequeStatus(String paymentId, ChequeStatus chequeStatus) {
    final updated = state.payments.map((payment) {
      if (payment.id != paymentId) return payment;
      final status = chequeStatus == ChequeStatus.cleared
          ? PaymentStatus.completed
          : chequeStatus == ChequeStatus.bounced
              ? PaymentStatus.bounced
              : PaymentStatus.pending;
      return payment.copyWith(
        status: status,
        chequeStatus: chequeStatus,
        note: 'Cheque ${chequeStatus.name}',
      );
    }).toList();
    state = state.copyWith(payments: updated);
    _audit('Marked cheque $paymentId as ${chequeStatus.name}', 'payment');
  }

  void updateReconciliation(
    String itemId,
    ReconciliationStatus status,
    String reason,
  ) {
    final updated = state.reconciliationItems.map((item) {
      if (item.id != itemId) return item;
      return item.copyWith(status: status, exceptionReason: reason);
    }).toList();
    state = state.copyWith(reconciliationItems: updated);
    _audit('Updated reconciliation item $itemId to ${status.label}', 'reconciliation');
  }

  StudentFinanceSummary financeFor(String studentId) {
    final demands = state.feeDemands.where((demand) => demand.studentId == studentId);
    final concessions = state.concessions.where(
      (concession) =>
          concession.studentId == studentId &&
          concession.status == ConcessionStatus.approved,
    );
    final payments = state.payments.where(
      (payment) =>
          payment.studentId == studentId &&
          payment.status == PaymentStatus.completed,
    );
    final totalDemand = demands.fold<double>(0, (sum, item) => sum + item.amount);
    final concessionTotal =
        concessions.fold<double>(0, (sum, item) => sum + item.amount);
    final paid = payments.fold<double>(0, (sum, item) => sum + item.amount);
    final pending = (totalDemand - concessionTotal - paid).clamp(0, double.infinity);
    final oldestDue = demands
        .where((demand) => demand.dueDate.isBefore(DateTime.now()))
        .map((demand) => DateTime.now().difference(demand.dueDate).inDays)
        .fold<int>(0, (max, days) => days > max ? days : max);
    return StudentFinanceSummary(
      totalDemand: totalDemand,
      approvedConcessions: concessionTotal,
      paid: paid,
      pending: pending.toDouble(),
      overdueDays: pending > 0 ? oldestDue : 0,
    );
  }

  DashboardStats dashboardStats() {
    final totalDemand =
        state.feeDemands.fold<double>(0, (sum, demand) => sum + demand.amount);
    final totalConcessions = state.concessions
        .where((item) => item.status == ConcessionStatus.approved)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final totalCollected = state.payments
        .where((payment) => payment.status == PaymentStatus.completed)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final totalPending =
        (totalDemand - totalConcessions - totalCollected).clamp(0, double.infinity);
    final defaulters = state.students
        .where((student) => financeFor(student.id).pending > 0)
        .where((student) => financeFor(student.id).overdueDays > 0)
        .length;
    return DashboardStats(
      totalDemand: totalDemand,
      totalCollected: totalCollected,
      totalPending: totalPending.toDouble(),
      totalConcessions: totalConcessions,
      defaulters: defaulters,
      collectionRate: totalDemand == 0 ? 0 : totalCollected / totalDemand,
    );
  }

  List<Student> visibleStudents() {
    final user = state.currentUser;
    if (user?.role == UserRole.parent) {
      return state.students
          .where((student) => student.guardianId == user?.guardianId)
          .toList();
    }
    return state.students;
  }

  void _audit(String action, String objectType) {
    final actor = state.currentUser?.name ?? 'System';
    final log = AuditLog(
      id: _id('a'),
      actor: actor,
      action: action,
      objectType: objectType,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(auditLogs: [log, ...state.auditLogs]);
  }

  String _id(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}
