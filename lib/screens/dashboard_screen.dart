import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/finance_providers.dart';
import '../widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final byClass = ref.watch(classPendingProvider);
    final modeTotals = ref.watch(paymentModeTotalsProvider);
    final defaulters = ref.watch(priorityDefaultersProvider);
    final width = MediaQuery.of(context).size.width;
    final statColumns = width > 1100 ? 4 : width > 720 ? 2 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Finance Command Center',
          subtitle: 'Live view of fee demand, collection, concessions, and risk.',
        ),
        GridView.count(
          crossAxisCount: statColumns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.45,
          children: [
            StatCard(
              title: 'Total Demand',
              value: moneyFormat.format(stats.totalDemand),
              icon: Icons.request_quote_outlined,
              accent: const Color(0xFF2563EB),
            ),
            StatCard(
              title: 'Collected',
              value: moneyFormat.format(stats.totalCollected),
              icon: Icons.account_balance_wallet_outlined,
              accent: const Color(0xFF047857),
              footer: '${(stats.collectionRate * 100).toStringAsFixed(1)}% collection rate',
            ),
            StatCard(
              title: 'Pending',
              value: moneyFormat.format(stats.totalPending),
              icon: Icons.pending_actions_outlined,
              accent: const Color(0xFFB45309),
            ),
            StatCard(
              title: 'Concessions',
              value: moneyFormat.format(stats.totalConcessions),
              icon: Icons.verified_outlined,
              accent: const Color(0xFF7C3AED),
              footer: '${stats.defaulters} overdue students',
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SectionCard(
                title: 'Class-wise Pending Dues',
                child: SimpleBarChart(items: byClass),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: SectionCard(
                title: 'Payment Mode Split',
                child: modeTotals.isEmpty
                    ? const EmptyState(message: 'No completed payments yet.')
                    : SimpleBarChart(items: modeTotals),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Priority Defaulters',
          child: defaulters.isEmpty
              ? const EmptyState(message: 'No overdue defaulters in current data.')
              : DataTable(
                  columns: const [
                    DataColumn(label: Text('Student')),
                    DataColumn(label: Text('Class')),
                    DataColumn(label: Text('Pending')),
                    DataColumn(label: Text('Overdue')),
                    DataColumn(label: Text('Category')),
                  ],
                  rows: defaulters.map((student) {
                    final summary = ref.watch(financeSummaryProvider(student.id));
                    return DataRow(
                      cells: [
                        DataCell(Text(student.name)),
                        DataCell(Text(student.classLabel)),
                        DataCell(Text(moneyFormat.format(summary.pending))),
                        DataCell(Text('${summary.overdueDays} days')),
                        DataCell(StatusPill(label: student.category, color: const Color(0xFF0F766E))),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
