enum UserRole { admin, principal, accountant, clerk, parent }

enum PaymentMode { upi, cash, cheque, bankTransfer }

enum PaymentStatus { pending, completed, bounced, reversed }

enum ChequeStatus { received, deposited, cleared, bounced }

enum ConcessionStatus { draft, submitted, approved, rejected }

enum ReconciliationStatus { unmatched, matched, duplicate, partial, overpaid }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.admin => 'Admin',
    UserRole.principal => 'Principal',
    UserRole.accountant => 'Accountant',
    UserRole.clerk => 'Fee Clerk',
    UserRole.parent => 'Parent',
  };
}

extension PaymentModeLabel on PaymentMode {
  String get label => switch (this) {
    PaymentMode.upi => 'UPI',
    PaymentMode.cash => 'Cash',
    PaymentMode.cheque => 'Cheque',
    PaymentMode.bankTransfer => 'Bank Transfer',
  };
}

extension PaymentStatusLabel on PaymentStatus {
  String get label => switch (this) {
    PaymentStatus.pending => 'Pending',
    PaymentStatus.completed => 'Completed',
    PaymentStatus.bounced => 'Bounced',
    PaymentStatus.reversed => 'Reversed',
  };
}

extension ConcessionStatusLabel on ConcessionStatus {
  String get label => switch (this) {
    ConcessionStatus.draft => 'Draft',
    ConcessionStatus.submitted => 'Submitted',
    ConcessionStatus.approved => 'Approved',
    ConcessionStatus.rejected => 'Rejected',
  };
}

extension ReconciliationStatusLabel on ReconciliationStatus {
  String get label => switch (this) {
    ReconciliationStatus.unmatched => 'Unmatched',
    ReconciliationStatus.matched => 'Matched',
    ReconciliationStatus.duplicate => 'Duplicate',
    ReconciliationStatus.partial => 'Partial',
    ReconciliationStatus.overpaid => 'Overpaid',
  };
}

class SchoolProfile {
  const SchoolProfile({
    required this.id,
    required this.name,
    required this.board,
    required this.state,
    required this.district,
    required this.schoolType,
    required this.academicYear,
  });

  final String id;
  final String name;
  final String board;
  final String state;
  final String district;
  final String schoolType;
  final String academicYear;

  String get locationLabel => '$district, $state';
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.guardianId,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? guardianId;
}

class Guardian {
  const Guardian({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
}

class Student {
  const Student({
    required this.id,
    required this.admissionNo,
    required this.name,
    required this.className,
    required this.section,
    required this.guardianId,
    required this.category,
    required this.phone,
    required this.status,
  });

  final String id;
  final String admissionNo;
  final String name;
  final String className;
  final String section;
  final String guardianId;
  final String category;
  final String phone;
  final String status;

  String get classLabel => '$className-$section';
}

class FeeHead {
  const FeeHead({
    required this.id,
    required this.name,
    required this.ledger,
    required this.refundable,
    required this.active,
  });

  final String id;
  final String name;
  final String ledger;
  final bool refundable;
  final bool active;
}

class FeeRule {
  const FeeRule({
    required this.id,
    required this.feeHeadId,
    required this.title,
    required this.amount,
    required this.scopeLabel,
    required this.frequency,
    required this.dueDate,
    required this.lateFeeAmount,
  });

  final String id;
  final String feeHeadId;
  final String title;
  final double amount;
  final String scopeLabel;
  final String frequency;
  final DateTime dueDate;
  final double lateFeeAmount;
}

class FeeDemand {
  const FeeDemand({
    required this.id,
    required this.studentId,
    required this.feeHeadId,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  final String id;
  final String studentId;
  final String feeHeadId;
  final double amount;
  final DateTime dueDate;
  final String status;
}

class Concession {
  const Concession({
    required this.id,
    required this.studentId,
    required this.category,
    required this.concessionType,
    required this.amount,
    required this.fundingSource,
    required this.status,
    required this.reason,
    required this.createdAt,
    this.approvedBy,
  });

  final String id;
  final String studentId;
  final String category;
  final String concessionType;
  final double amount;
  final String fundingSource;
  final ConcessionStatus status;
  final String reason;
  final DateTime createdAt;
  final String? approvedBy;

  Concession copyWith({ConcessionStatus? status, String? approvedBy}) {
    return Concession(
      id: id,
      studentId: studentId,
      category: category,
      concessionType: concessionType,
      amount: amount,
      fundingSource: fundingSource,
      status: status ?? this.status,
      reason: reason,
      createdAt: createdAt,
      approvedBy: approvedBy ?? this.approvedBy,
    );
  }
}

class Payment {
  const Payment({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.mode,
    required this.status,
    required this.date,
    required this.referenceNo,
    required this.receiptNo,
    required this.note,
    this.chequeStatus,
  });

  final String id;
  final String studentId;
  final double amount;
  final PaymentMode mode;
  final PaymentStatus status;
  final DateTime date;
  final String referenceNo;
  final String receiptNo;
  final String note;
  final ChequeStatus? chequeStatus;

  Payment copyWith({
    PaymentStatus? status,
    ChequeStatus? chequeStatus,
    String? note,
  }) {
    return Payment(
      id: id,
      studentId: studentId,
      amount: amount,
      mode: mode,
      status: status ?? this.status,
      date: date,
      referenceNo: referenceNo,
      receiptNo: receiptNo,
      note: note ?? this.note,
      chequeStatus: chequeStatus ?? this.chequeStatus,
    );
  }
}

class ReconciliationItem {
  const ReconciliationItem({
    required this.id,
    required this.paymentId,
    required this.channelRef,
    required this.status,
    required this.exceptionReason,
  });

  final String id;
  final String paymentId;
  final String channelRef;
  final ReconciliationStatus status;
  final String exceptionReason;

  ReconciliationItem copyWith({
    ReconciliationStatus? status,
    String? exceptionReason,
  }) {
    return ReconciliationItem(
      id: id,
      paymentId: paymentId,
      channelRef: channelRef,
      status: status ?? this.status,
      exceptionReason: exceptionReason ?? this.exceptionReason,
    );
  }
}

class AuditLog {
  const AuditLog({
    required this.id,
    required this.actor,
    required this.action,
    required this.objectType,
    required this.createdAt,
  });

  final String id;
  final String actor;
  final String action;
  final String objectType;
  final DateTime createdAt;
}

class StudentFinanceSummary {
  const StudentFinanceSummary({
    required this.totalDemand,
    required this.approvedConcessions,
    required this.paid,
    required this.pending,
    required this.overdueDays,
  });

  final double totalDemand;
  final double approvedConcessions;
  final double paid;
  final double pending;
  final int overdueDays;
}

class DashboardStats {
  const DashboardStats({
    required this.totalDemand,
    required this.totalCollected,
    required this.totalPending,
    required this.totalConcessions,
    required this.defaulters,
    required this.collectionRate,
  });

  final double totalDemand;
  final double totalCollected;
  final double totalPending;
  final double totalConcessions;
  final int defaulters;
  final double collectionRate;
}
