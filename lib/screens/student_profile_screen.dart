import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/finance_providers.dart';
import '../widgets/common.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.currentUser;
    final student = _studentFor(state, studentId);
    if (student == null ||
        (user?.role == UserRole.parent &&
            student.guardianId != user?.guardianId)) {
      return const _StudentAccessDenied();
    }

    final guardian = _guardianFor(state, student.guardianId);
    final summary = ref.watch(financeSummaryProvider(student.id));
    final demands = state.feeDemands.where((item) => item.studentId == student.id).toList();
    final concessions = state.concessions.where((item) => item.studentId == student.id).toList();
    final payments = state.payments.where((item) => item.studentId == student.id).toList();
    final width = MediaQuery.of(context).size.width;
    final statColumns = width > 1100 ? 4 : width > 720 ? 2 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: student.name,
          subtitle:
              '${student.admissionNo} | Class ${student.classLabel} | Guardian: ${guardian?.name ?? 'Not linked'}',
        ),
        GridView.count(
          crossAxisCount: statColumns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          childAspectRatio: 1.5,
          children: [
            StatCard(
              title: 'Demand',
              value: moneyFormat.format(summary.totalDemand),
              icon: Icons.request_quote,
              accent: const Color(0xFF2563EB),
            ),
            StatCard(
              title: 'Concession',
              value: moneyFormat.format(summary.approvedConcessions),
              icon: Icons.verified,
              accent: const Color(0xFF7C3AED),
            ),
            StatCard(
              title: 'Paid',
              value: moneyFormat.format(summary.paid),
              icon: Icons.payments,
              accent: const Color(0xFF047857),
            ),
            StatCard(
              title: 'Pending',
              value: moneyFormat.format(summary.pending),
              icon: Icons.warning_amber,
              accent: const Color(0xFFB45309),
              footer: '${summary.overdueDays} overdue days',
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Fee Demands',
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Fee Head')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Due Date')),
              DataColumn(label: Text('Status')),
            ],
            rows: demands.map((demand) {
              final head = state.feeHeads.firstWhere((item) => item.id == demand.feeHeadId);
              return DataRow(cells: [
                DataCell(Text(head.name)),
                DataCell(Text(moneyFormat.format(demand.amount))),
                DataCell(Text(DateFormat.yMMMd().format(demand.dueDate))),
                DataCell(StatusPill(label: demand.status, color: statusColor(demand.status))),
              ]);
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SectionCard(
                title: 'Concessions',
                child: concessions.isEmpty
                    ? const EmptyState(message: 'No concessions for this student.')
                    : Column(
                        children: concessions.map((item) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${item.category} - ${item.concessionType}'),
                            subtitle: Text(item.reason),
                            trailing: StatusPill(
                              label: item.status.label,
                              color: statusColor(item.status.label),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: SectionCard(
                title: 'Payments',
                child: payments.isEmpty
                    ? const EmptyState(message: 'No payments recorded yet.')
                    : Column(
                        children: payments.map((payment) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${payment.receiptNo} | ${payment.mode.label}'),
                            subtitle: Text(payment.referenceNo),
                            trailing: Text(moneyFormat.format(payment.amount)),
                          );
                        }).toList(),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Student? _studentFor(AppState state, String studentId) {
    for (final student in state.students) {
      if (student.id == studentId) return student;
    }
    return null;
  }

  Guardian? _guardianFor(AppState state, String guardianId) {
    for (final guardian in state.guardians) {
      if (guardian.id == guardianId) return guardian;
    }
    return null;
  }
}

class _StudentAccessDenied extends StatelessWidget {
  const _StudentAccessDenied();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline,
                color: Color(0xFFC2410C),
                size: 36,
              ),
              const SizedBox(height: 14),
              const Text(
                'Student access limited',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Parent accounts can only view fee details for their linked child.',
                style: TextStyle(color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => context.go('/students'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to students'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
