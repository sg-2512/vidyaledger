import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';

class ReconciliationScreen extends ConsumerWidget {
  const ReconciliationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Reconciliation',
          subtitle: 'Match UPI, bank transfer, cheque, and cash records against receipts.',
        ),
        SectionCard(
          title: 'Exception Queue',
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Receipt')),
              DataColumn(label: Text('Channel Ref')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Exception')),
              DataColumn(label: Text('Action')),
            ],
            rows: state.reconciliationItems.map((item) {
              final payment = state.payments.firstWhere((pay) => pay.id == item.paymentId);
              return DataRow(cells: [
                DataCell(Text(payment.receiptNo)),
                DataCell(Text(item.channelRef)),
                DataCell(Text(moneyFormat.format(payment.amount))),
                DataCell(StatusPill(label: item.status.label, color: statusColor(item.status.label))),
                DataCell(Text(item.exceptionReason.isEmpty ? '-' : item.exceptionReason)),
                DataCell(
                  Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        onPressed: () => ref.read(appControllerProvider.notifier).updateReconciliation(
                              item.id,
                              ReconciliationStatus.matched,
                              '',
                            ),
                        child: const Text('Match'),
                      ),
                      TextButton(
                        onPressed: () => ref.read(appControllerProvider.notifier).updateReconciliation(
                              item.id,
                              ReconciliationStatus.duplicate,
                              'Possible duplicate settlement',
                            ),
                        child: const Text('Duplicate'),
                      ),
                      TextButton(
                        onPressed: () => ref.read(appControllerProvider.notifier).updateReconciliation(
                              item.id,
                              ReconciliationStatus.partial,
                              'Amount mismatch needs accountant review',
                            ),
                        child: const Text('Partial'),
                      ),
                    ],
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
