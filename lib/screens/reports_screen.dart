import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/report_service.dart';
import '../widgets/common.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final stats = ref.read(appControllerProvider.notifier).dashboardStats();
    final approved = state.concessions
        .where((item) => item.status == ConcessionStatus.approved)
        .length;
    final pendingApprovals = state.concessions
        .where((item) => item.status == ConcessionStatus.submitted)
        .length;
    final width = MediaQuery.of(context).size.width;
    final statColumns = width > 1100 ? 4 : width > 720 ? 2 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Reports',
          subtitle: 'Export accountant-friendly collection, student ledger, concession, and defaulter summaries.',
          trailing: FilledButton.icon(
            onPressed: () async {
              final bytes = await ReportService.buildCollectionReport(state);
              await Printing.sharePdf(
                bytes: bytes,
                filename: 'vidyaledger-collection-report.pdf',
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Download Collection PDF'),
          ),
        ),
        GridView.count(
          crossAxisCount: statColumns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          childAspectRatio: 1.45,
          children: [
            StatCard(
              title: 'Daily Collection',
              value: moneyFormat.format(stats.totalCollected),
              icon: Icons.today,
              accent: const Color(0xFF047857),
            ),
            StatCard(
              title: 'Student Ledger Rows',
              value: state.feeDemands.length.toString(),
              icon: Icons.list_alt,
              accent: const Color(0xFF2563EB),
            ),
            StatCard(
              title: 'Approved Concessions',
              value: approved.toString(),
              icon: Icons.verified,
              accent: const Color(0xFF7C3AED),
            ),
            StatCard(
              title: 'Pending Approvals',
              value: pendingApprovals.toString(),
              icon: Icons.hourglass_top,
              accent: const Color(0xFFB45309),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Audit Trail',
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Actor')),
              DataColumn(label: Text('Action')),
              DataColumn(label: Text('Object')),
            ],
            rows: state.auditLogs.take(10).map((log) {
              return DataRow(cells: [
                DataCell(Text(log.actor)),
                DataCell(Text(log.action)),
                DataCell(Text(log.objectType)),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
