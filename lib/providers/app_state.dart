import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

class AppState {
  const AppState({
    required this.currentUser,
    required this.selectedStudentId,
    required this.school,
    required this.users,
    required this.guardians,
    required this.students,
    required this.classSections,
    required this.feeHeads,
    required this.feeRules,
    required this.feeDemands,
    required this.concessions,
    required this.payments,
    required this.paymentRequests,
    required this.reconciliationItems,
    required this.auditLogs,
  });

  final AppUser? currentUser;
  final String? selectedStudentId;
  final SchoolProfile school;
  final List<AppUser> users;
  final List<Guardian> guardians;
  final List<Student> students;
  final List<ClassSection> classSections;
  final List<FeeHead> feeHeads;
  final List<FeeRule> feeRules;
  final List<FeeDemand> feeDemands;
  final List<Concession> concessions;
  final List<Payment> payments;
  final List<PaymentRequest> paymentRequests;
  final List<ReconciliationItem> reconciliationItems;
  final List<AuditLog> auditLogs;

  factory AppState.seeded() {
    final now = DateTime.now();
    const school = SchoolProfile(
      id: 'school-1',
      name: 'Vidya Public School',
      board: 'CBSE',
      state: 'Rajasthan',
      district: 'Jaipur',
      schoolType: 'Unaided Private School',
      academicYear: '2026-27',
      address: 'Sector 12, Jaipur, Rajasthan',
      contactEmail: 'office@vidyapublic.demo',
      contactPhone: '+91 141 400 2026',
    );
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
        id: 's-5',
        admissionNo: 'VL-2026-005',
        name: 'Ira Sharma',
        className: '4',
        section: 'C',
        guardianId: 'g-1',
        category: 'General',
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
    final classSections = [
      const ClassSection(
        id: 'cs-4-c',
        className: '4',
        section: 'C',
        classTeacher: 'Ritika Sen',
        roomLabel: 'Room 108',
        capacity: 38,
        active: true,
      ),
      const ClassSection(
        id: 'cs-6-a',
        className: '6',
        section: 'A',
        classTeacher: 'Nisha Verma',
        roomLabel: 'Room 201',
        capacity: 45,
        active: true,
      ),
      const ClassSection(
        id: 'cs-7-a',
        className: '7',
        section: 'A',
        classTeacher: 'Anil Sharma',
        roomLabel: 'Room 205',
        capacity: 45,
        active: true,
      ),
      const ClassSection(
        id: 'cs-8-b',
        className: '8',
        section: 'B',
        classTeacher: 'Farah Khan',
        roomLabel: 'Room 302',
        capacity: 42,
        active: true,
      ),
      const ClassSection(
        id: 'cs-9-c',
        className: '9',
        section: 'C',
        classTeacher: 'Ravi Meena',
        roomLabel: 'Room 401',
        capacity: 40,
        active: true,
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
        id: 'fd-6',
        studentId: 's-5',
        feeHeadId: 'fh-1',
        amount: 24000,
        dueDate: now.add(const Duration(days: 18)),
        status: 'open',
      ),
      FeeDemand(
        id: 'fd-7',
        studentId: 's-5',
        feeHeadId: 'fh-3',
        amount: 4500,
        dueDate: now.add(const Duration(days: 36)),
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
        id: 'p-4',
        studentId: 's-5',
        amount: 9000,
        mode: PaymentMode.upi,
        status: PaymentStatus.completed,
        date: now.subtract(const Duration(days: 6)),
        referenceNo: 'UPI558241',
        receiptNo: 'VL/2026/0004',
        note: 'Initial tuition payment',
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
      selectedStudentId: null,
      school: school,
      users: const [
        AppUser(
          id: 'u-admin',
          name: 'Sanchit Gupta',
          email: 'admin@vidyaledger.demo',
          role: UserRole.admin,
        ),
        AppUser(
          id: 'u-parent',
          name: 'Meera Sharma',
          email: 'parent@vidyaledger.demo',
          role: UserRole.parent,
          guardianId: 'g-1',
        ),
        AppUser(
          id: 'u-student',
          name: 'Asha Sharma',
          email: 'student@vidyaledger.demo',
          role: UserRole.student,
          guardianId: 'g-1',
        ),
      ],
      guardians: guardians,
      students: students,
      classSections: classSections,
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
      paymentRequests: [
        PaymentRequest(
          id: 'pr-1',
          studentId: 's-2',
          amount: 8000,
          provider: PaymentProvider.upiIntent,
          status: PaymentRequestStatus.shared,
          requestNo: 'VPR/2026/0001',
          checkoutUrl:
              'upi://pay?pa=vidyaledger.demo%40upi&pn=Vidya%20Public%20School&am=8000.00&cu=INR&tn=VPR%2F2026%2F0001',
          upiUri:
              'upi://pay?pa=vidyaledger.demo%40upi&pn=Vidya%20Public%20School&am=8000.00&cu=INR&tn=VPR%2F2026%2F0001',
          note: 'SC concession balance follow-up',
          createdAt: now.subtract(const Duration(hours: 6)),
          expiresAt: now.add(const Duration(days: 2)),
        ),
      ],
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
          id: 'r-4',
          paymentId: 'p-4',
          channelRef: 'UPI settlement batch 03',
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
    String? selectedStudentId,
    SchoolProfile? school,
    bool clearCurrentUser = false,
    bool clearSelectedStudent = false,
    List<AppUser>? users,
    List<Guardian>? guardians,
    List<Student>? students,
    List<ClassSection>? classSections,
    List<FeeHead>? feeHeads,
    List<FeeRule>? feeRules,
    List<FeeDemand>? feeDemands,
    List<Concession>? concessions,
    List<Payment>? payments,
    List<PaymentRequest>? paymentRequests,
    List<ReconciliationItem>? reconciliationItems,
    List<AuditLog>? auditLogs,
  }) {
    return AppState(
      currentUser: clearCurrentUser ? null : currentUser ?? this.currentUser,
      selectedStudentId: clearSelectedStudent
          ? null
          : selectedStudentId ?? this.selectedStudentId,
      school: school ?? this.school,
      users: users ?? this.users,
      guardians: guardians ?? this.guardians,
      students: students ?? this.students,
      classSections: classSections ?? this.classSections,
      feeHeads: feeHeads ?? this.feeHeads,
      feeRules: feeRules ?? this.feeRules,
      feeDemands: feeDemands ?? this.feeDemands,
      concessions: concessions ?? this.concessions,
      payments: payments ?? this.payments,
      paymentRequests: paymentRequests ?? this.paymentRequests,
      reconciliationItems: reconciliationItems ?? this.reconciliationItems,
      auditLogs: auditLogs ?? this.auditLogs,
    );
  }
}

class AppController extends Notifier<AppState> {
  @override
  AppState build() => AppState.seeded();

  void replaceState(AppState nextState) {
    final selectedStudentId =
        _canUseSelectedStudentId(
          nextState.currentUser,
          nextState.students,
          nextState.selectedStudentId,
        )
        ? nextState.selectedStudentId
        : _defaultStudentIdForUser(nextState.currentUser, nextState.students);
    state = nextState.copyWith(
      selectedStudentId: selectedStudentId,
      clearSelectedStudent: selectedStudentId == null,
    );
  }

  void loginAs(UserRole role) {
    final user = state.users.firstWhere((candidate) => candidate.role == role);
    final selectedStudentId = _defaultStudentIdFor(user);
    state = state.copyWith(
      currentUser: user,
      selectedStudentId: selectedStudentId,
      clearSelectedStudent: selectedStudentId == null,
    );
    _audit('${user.name} logged in as ${role.label}', 'auth');
  }

  void logout() {
    state = state.copyWith(clearCurrentUser: true, clearSelectedStudent: true);
  }

  void selectStudent(String studentId) {
    final canSeeStudent = visibleStudents().any(
      (student) => student.id == studentId,
    );
    if (!canSeeStudent) return;
    state = state.copyWith(selectedStudentId: studentId);
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

  void updateSchoolProfile(SchoolProfile school) {
    state = state.copyWith(school: school);
    _audit('Updated school profile for ${school.name}', 'school');
  }

  void addClassSection({
    required String className,
    required String section,
    required String classTeacher,
    required String roomLabel,
    required int capacity,
  }) {
    final normalizedClass = className.trim();
    final normalizedSection = section.trim().toUpperCase();
    final existingIndex = state.classSections.indexWhere(
      (item) =>
          item.className == normalizedClass &&
          item.section == normalizedSection,
    );
    final classSection = ClassSection(
      id: existingIndex >= 0
          ? state.classSections[existingIndex].id
          : _id('cs'),
      className: normalizedClass,
      section: normalizedSection,
      classTeacher: classTeacher,
      roomLabel: roomLabel,
      capacity: capacity,
      active: true,
    );

    final nextSections = [...state.classSections];
    if (existingIndex >= 0) {
      nextSections[existingIndex] = classSection;
    } else {
      nextSections.add(classSection);
    }
    state = state.copyWith(classSections: nextSections);
    _audit('Configured ${classSection.label}', 'class_section');
  }

  void setClassSectionActive(String classSectionId, bool active) {
    final nextSections = state.classSections.map((item) {
      if (item.id != classSectionId) return item;
      return item.copyWith(active: active);
    }).toList();
    state = state.copyWith(classSections: nextSections);
    _audit(
      '${active ? 'Activated' : 'Archived'} class section $classSectionId',
      'class_section',
    );
  }

  void addStudentWithGuardian({
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
  }) {
    final guardian = Guardian(
      id: _id('g'),
      name: guardianName,
      phone: guardianPhone,
      email: guardianEmail,
      address: guardianAddress,
    );
    final student = Student(
      id: _id('s'),
      admissionNo: admissionNo,
      name: studentName,
      className: className,
      section: section,
      guardianId: guardian.id,
      category: category,
      phone: studentPhone,
      status: 'active',
    );
    state = state.copyWith(
      guardians: [...state.guardians, guardian],
      students: [...state.students, student],
    );
    _audit('Added student $studentName ($admissionNo)', 'student');
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
    final targets = state.students.where(
      (student) => student.className == className,
    );
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
    final receiptNo =
        'VL/2026/${(state.payments.length + 1).toString().padLeft(4, '0')}';
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
      chequeStatus: mode == PaymentMode.cheque ? ChequeStatus.received : null,
    );
    final reconciliation = ReconciliationItem(
      id: _id('r'),
      paymentId: payment.id,
      channelRef: referenceNo,
      status: mode == PaymentMode.cash
          ? ReconciliationStatus.matched
          : ReconciliationStatus.unmatched,
      exceptionReason: mode == PaymentMode.cash
          ? ''
          : 'Pending settlement verification',
    );
    state = state.copyWith(
      payments: [...state.payments, payment],
      reconciliationItems: [...state.reconciliationItems, reconciliation],
    );
    _audit('Recorded ${mode.label} payment $receiptNo', 'payment');
    return payment;
  }

  PaymentRequest createPaymentRequest({
    required String studentId,
    required double amount,
    required PaymentProvider provider,
    required String note,
  }) {
    final yearPrefix = state.school.academicYear.length >= 4
        ? state.school.academicYear.substring(0, 4)
        : DateTime.now().year.toString();
    final requestNo =
        'VPR/$yearPrefix/${(state.paymentRequests.length + 1).toString().padLeft(4, '0')}';
    final upiUri = provider == PaymentProvider.upiIntent
        ? _buildUpiUri(amount: amount, note: note, requestNo: requestNo)
        : null;
    final checkoutUrl =
        upiUri ??
        'https://payments.vidyaledger.demo/${provider.name}/${requestNo.replaceAll('/', '-')}';
    final request = PaymentRequest(
      id: _id('pr'),
      studentId: studentId,
      amount: amount,
      provider: provider,
      status: PaymentRequestStatus.created,
      requestNo: requestNo,
      checkoutUrl: checkoutUrl,
      upiUri: upiUri,
      note: note,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 3)),
      gatewayOrderId: provider == PaymentProvider.upiIntent
          ? null
          : 'demo_${provider.name}_${DateTime.now().millisecondsSinceEpoch}',
    );
    state = state.copyWith(
      paymentRequests: [request, ...state.paymentRequests],
    );
    _audit('Created ${provider.label} request $requestNo', 'payment_request');
    return request;
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
    final updatedReconciliation = state.reconciliationItems.map((item) {
      if (item.paymentId != paymentId) return item;
      if (chequeStatus == ChequeStatus.cleared) {
        return item.copyWith(
          status: ReconciliationStatus.matched,
          exceptionReason: '',
        );
      }
      if (chequeStatus == ChequeStatus.bounced) {
        return item.copyWith(
          status: ReconciliationStatus.unmatched,
          exceptionReason: 'Cheque bounced; receivable reopened',
        );
      }
      return item.copyWith(
        status: ReconciliationStatus.unmatched,
        exceptionReason: 'Awaiting cheque clearance',
      );
    }).toList();
    state = state.copyWith(
      payments: updated,
      reconciliationItems: updatedReconciliation,
    );
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
    _audit(
      'Updated reconciliation item $itemId to ${status.label}',
      'reconciliation',
    );
  }

  StudentFinanceSummary financeFor(String studentId) {
    final demands = state.feeDemands.where(
      (demand) => demand.studentId == studentId,
    );
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
    final totalDemand = demands.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final concessionTotal = concessions.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final paid = payments.fold<double>(0, (sum, item) => sum + item.amount);
    final pending = (totalDemand - concessionTotal - paid).clamp(
      0,
      double.infinity,
    );
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
    final totalDemand = state.feeDemands.fold<double>(
      0,
      (sum, demand) => sum + demand.amount,
    );
    final totalConcessions = state.concessions
        .where((item) => item.status == ConcessionStatus.approved)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final totalCollected = state.payments
        .where((payment) => payment.status == PaymentStatus.completed)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final totalPending = (totalDemand - totalConcessions - totalCollected)
        .clamp(0, double.infinity);
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
    if (user?.role == UserRole.student) {
      // Students can only see themselves
      try {
        final student = state.students.firstWhere((s) {
          final ug = user?.guardianId;
          if (ug == null) return false;
          return ug == s.guardianId;
        });
        return [student];
      } catch (e) {
        return [];
      }
    }
    return state.students;
  }

  String? _defaultStudentIdFor(AppUser user) {
    return _defaultStudentIdForUser(user, state.students);
  }

  String? _defaultStudentIdForUser(AppUser? user, List<Student> students) {
    if (user == null ||
        (user.role != UserRole.parent && user.role != UserRole.student)) {
      return null;
    }
    for (final student in students) {
      if (student.guardianId == user.guardianId) {
        return student.id;
      }
    }
    return null;
  }

  bool _canUseSelectedStudentId(
    AppUser? user,
    List<Student> students,
    String? studentId,
  ) {
    if (studentId == null ||
        user == null ||
        (user.role != UserRole.parent && user.role != UserRole.student)) {
      return false;
    }
    return students.any(
      (student) =>
          student.id == studentId && student.guardianId == user.guardianId,
    );
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

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  String _buildUpiUri({
    required double amount,
    required String note,
    required String requestNo,
  }) {
    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': 'vidyaledger.demo@upi',
        'pn': state.school.name,
        'am': amount.toStringAsFixed(2),
        'cu': 'INR',
        'tn': note.isEmpty ? requestNo : '$requestNo $note',
      },
    ).toString();
  }
}
