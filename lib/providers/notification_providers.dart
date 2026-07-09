import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_state.dart';
import '../models/models.dart';

class AppNotification {
  const AppNotification({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.severity,
    required this.timestamp,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String severity;
  final DateTime timestamp;
}

final notificationsProvider = Provider<List<AppNotification>>((ref) {
  final state = ref.watch(appControllerProvider);
  final notifications = <AppNotification>[];
  final now = DateTime.now();

  // 1. Pending cheques
  final pendingCheques = state.payments
      .where(
        (p) =>
            p.mode == PaymentMode.cheque && p.status == PaymentStatus.pending,
      )
      .toList();
  if (pendingCheques.isNotEmpty) {
    final total = pendingCheques.fold<double>(0, (s, p) => s + p.amount);
    notifications.add(AppNotification(
      icon: 'cheque',
      title:
          '${pendingCheques.length} cheque${pendingCheques.length > 1 ? 's' : ''} pending clearance',
      subtitle: 'Total: Rs ${total.toStringAsFixed(0)}',
      severity: 'warning',
      timestamp: now,
    ));
  }

  // 2. Unreconciled payments
  final unreconciled = state.reconciliationItems
      .where((r) => r.status == ReconciliationStatus.unmatched)
      .toList();
  if (unreconciled.isNotEmpty) {
    notifications.add(AppNotification(
      icon: 'reconciliation',
      title:
          '${unreconciled.length} payment${unreconciled.length > 1 ? 's' : ''} unreconciled',
      subtitle: 'Requires accountant review',
      severity: 'warning',
      timestamp: now,
    ));
  }

  // 3. Concessions awaiting approval
  final pendingConcessions = state.concessions
      .where((c) => c.status == ConcessionStatus.submitted)
      .toList();
  if (pendingConcessions.isNotEmpty) {
    notifications.add(AppNotification(
      icon: 'concession',
      title:
          '${pendingConcessions.length} concession${pendingConcessions.length > 1 ? 's' : ''} awaiting approval',
      subtitle: pendingConcessions.map((c) => c.category).toSet().join(', '),
      severity: 'info',
      timestamp: now,
    ));
  }

  // 4. Overdue fee demands per class
  final overdueByClass = <String, int>{};
  for (final demand in state.feeDemands) {
    if (demand.dueDate.isBefore(now) && demand.status == 'open') {
      final student =
          state.students.where((s) => s.id == demand.studentId).firstOrNull;
      if (student != null) {
        overdueByClass.update(
          'Class ${student.className}',
          (v) => v + 1,
          ifAbsent: () => 1,
        );
      }
    }
  }
  for (final entry in overdueByClass.entries) {
    notifications.add(AppNotification(
      icon: 'overdue',
      title:
          '${entry.value} overdue demand${entry.value > 1 ? 's' : ''} in ${entry.key}',
      subtitle: 'Collection follow-up recommended',
      severity: 'urgent',
      timestamp: now,
    ));
  }

  // 5. Recent completed payments (last 24h)
  final recentPayments = state.payments
      .where(
        (p) =>
            p.status == PaymentStatus.completed &&
            now.difference(p.date).inHours < 24,
      )
      .toList();
  if (recentPayments.isNotEmpty) {
    final total = recentPayments.fold<double>(0, (s, p) => s + p.amount);
    notifications.add(AppNotification(
      icon: 'payment',
      title:
          '${recentPayments.length} payment${recentPayments.length > 1 ? 's' : ''} received today',
      subtitle: 'Total: Rs ${total.toStringAsFixed(0)}',
      severity: 'info',
      timestamp: now,
    ));
  }

  return notifications;
});

final notificationCountProvider = Provider<int>((ref) {
  return ref
      .watch(notificationsProvider)
      .where((n) => n.severity != 'info')
      .length;
});
