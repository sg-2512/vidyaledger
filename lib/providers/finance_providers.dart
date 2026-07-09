import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'app_state.dart';
import 'finance_math.dart';

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(appControllerProvider).currentUser;
});

final visibleStudentsProvider = Provider<List<Student>>((ref) {
  final state = ref.watch(appControllerProvider);
  return selectVisibleStudents(state);
});

final financeSummaryProvider = Provider.family<StudentFinanceSummary, String>((
  ref,
  studentId,
) {
  final state = ref.watch(appControllerProvider);
  return calculateFinanceFor(state, studentId);
});

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final state = ref.watch(appControllerProvider);
  return calculateDashboardStats(state);
});

final classPendingProvider = Provider<Map<String, double>>((ref) {
  final state = ref.watch(appControllerProvider);
  return calculateClassPending(state);
});

final paymentModeTotalsProvider = Provider<Map<String, double>>((ref) {
  final state = ref.watch(appControllerProvider);
  return calculatePaymentModeTotals(state);
});

final priorityDefaultersProvider = Provider<List<Student>>((ref) {
  final state = ref.watch(appControllerProvider);
  return selectPriorityDefaulters(state);
});

final approvedConcessionCountProvider = Provider<int>((ref) {
  final state = ref.watch(appControllerProvider);
  return state.concessions
      .where((item) => item.status == ConcessionStatus.approved)
      .length;
});

final pendingConcessionCountProvider = Provider<int>((ref) {
  final state = ref.watch(appControllerProvider);
  return state.concessions
      .where((item) => item.status == ConcessionStatus.submitted)
      .length;
});
