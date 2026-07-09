import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/supabase_providers.dart';
import '../widgets/common.dart';

class ReconciliationScreen extends ConsumerStatefulWidget {
  const ReconciliationScreen({super.key});

  @override
  ConsumerState<ReconciliationScreen> createState() =>
      _ReconciliationScreenState();
}

class _ReconciliationScreenState extends ConsumerState<ReconciliationScreen> {
  String? updatingItemId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Reconciliation',
          subtitle:
              'Match UPI, bank transfer, cheque, and cash records against receipts.',
        ),
        SectionCard(
          title: 'Exception Queue',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1000),
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
                  final payment = _paymentFor(state, item.paymentId);
                  final updating = updatingItemId == item.id;
                  return DataRow(
                    cells: [
                      DataCell(Text(payment?.receiptNo ?? 'Missing payment')),
                      DataCell(Text(item.channelRef)),
                      DataCell(Text(moneyFormat.format(payment?.amount ?? 0))),
                      DataCell(
                        StatusPill(
                          label: item.status.label,
                          color: statusColor(item.status.label),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.exceptionReason.isEmpty ? '-' : item.exceptionReason,
                        ),
                      ),
                      DataCell(
                        item.status == ReconciliationStatus.unmatched
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: updating
                                        ? null
                                        : () => _updateReconciliation(
                                              item.id,
                                              ReconciliationStatus.matched,
                                              '',
                                            ),
                                    icon: const Icon(Icons.check, size: 14),
                                    label: const Text('Match', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0F766E),
                                      side: const BorderSide(color: Color(0xFF0F766E)),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    onPressed: updating
                                        ? null
                                        : () => _updateReconciliation(
                                              item.id,
                                              ReconciliationStatus.duplicate,
                                              'Possible duplicate settlement',
                                            ),
                                    icon: const Icon(Icons.copy, size: 14),
                                    label: const Text('Duplicate', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFB45309),
                                      side: const BorderSide(color: Color(0xFFB45309)),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    onPressed: updating
                                        ? null
                                        : () => _updateReconciliation(
                                              item.id,
                                              ReconciliationStatus.partial,
                                              'Amount mismatch needs review',
                                            ),
                                    icon: const Icon(Icons.hourglass_bottom, size: 14),
                                    label: const Text('Partial', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2563EB),
                                      side: const BorderSide(color: Color(0xFF2563EB)),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateReconciliation(
    String itemId,
    ReconciliationStatus status,
    String reason,
  ) async {
    if (updatingItemId != null) return;

    setState(() => updatingItemId = itemId);
    try {
      final service = ref.read(supabaseFinanceServiceProvider);
      if (service == null) {
        ref
            .read(appControllerProvider.notifier)
            .updateReconciliation(itemId, status, reason);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demo reconciliation marked ${status.label}.'),
          ),
        );
        return;
      }

      await service.updateReconciliation(
        reconciliationId: itemId,
        status: status,
        reason: reason,
      );
      await refreshAppStateFromSupabase(
        ref,
        currentUser: ref.read(appControllerProvider).currentUser,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backend reconciliation marked ${status.label.toLowerCase()}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reconciliation update failed: $error')),
      );
    } finally {
      if (mounted) setState(() => updatingItemId = null);
    }
  }

  Payment? _paymentFor(AppState state, String paymentId) {
    for (final payment in state.payments) {
      if (payment.id == paymentId) return payment;
    }
    return null;
  }
}
