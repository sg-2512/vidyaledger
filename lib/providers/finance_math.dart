import '../models/models.dart';
import 'app_state.dart';

StudentFinanceSummary calculateFinanceFor(AppState state, String studentId) {
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
  final totalDemand = demands.fold<double>(0, (sum, item) => sum + item.amount);
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

DashboardStats calculateDashboardStats(AppState state) {
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
  final totalPending = (totalDemand - totalConcessions - totalCollected).clamp(
    0,
    double.infinity,
  );
  final defaulters = selectPriorityDefaulters(state).length;

  return DashboardStats(
    totalDemand: totalDemand,
    totalCollected: totalCollected,
    totalPending: totalPending.toDouble(),
    totalConcessions: totalConcessions,
    defaulters: defaulters,
    collectionRate: totalDemand == 0 ? 0 : totalCollected / totalDemand,
  );
}

List<Student> selectVisibleStudents(AppState state) {
  final user = state.currentUser;
  if (user?.role == UserRole.parent) {
    return state.students
        .where((student) => student.guardianId == user?.guardianId)
        .toList();
  }
  return state.students;
}

Map<String, double> calculateClassPending(AppState state) {
  final byClass = <String, double>{};
  for (final student in state.students) {
    final pending = calculateFinanceFor(state, student.id).pending;
    byClass.update(
      'Class ${student.className}',
      (value) => value + pending,
      ifAbsent: () => pending,
    );
  }
  return byClass;
}

Map<String, double> calculatePaymentModeTotals(AppState state) {
  final modeTotals = <String, double>{};
  for (final payment in state.payments.where(
    (payment) => payment.status == PaymentStatus.completed,
  )) {
    modeTotals.update(
      payment.mode.label,
      (value) => value + payment.amount,
      ifAbsent: () => payment.amount,
    );
  }
  return modeTotals;
}

List<Student> selectPriorityDefaulters(AppState state) {
  return state.students
      .where((student) => calculateFinanceFor(state, student.id).pending > 0)
      .where(
        (student) => calculateFinanceFor(state, student.id).overdueDays > 0,
      )
      .toList();
}
