import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/supabase_providers.dart';
import '../utils/settlement_reconciliation.dart';
import '../widgets/common.dart';

class ReconciliationScreen extends ConsumerStatefulWidget {
  const ReconciliationScreen({super.key});

  @override
  ConsumerState<ReconciliationScreen> createState() =>
      _ReconciliationScreenState();
}

class _ReconciliationScreenState extends ConsumerState<ReconciliationScreen> {
  String? updatingItemId;
  bool importingSettlement = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Reconciliation',
          subtitle:
              'Match UPI, bank transfer, cheque, and cash records against receipts.',
          trailing: OutlinedButton.icon(
            onPressed: importingSettlement ? null : _openSettlementImportDialog,
            icon: importingSettlement
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            label: Text(
              importingSettlement ? 'Applying...' : 'Import Settlement CSV',
            ),
          ),
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
                          item.exceptionReason.isEmpty
                              ? '-'
                              : item.exceptionReason,
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
                                    label: const Text(
                                      'Match',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0F766E),
                                      side: const BorderSide(
                                        color: Color(0xFF0F766E),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
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
                                    label: const Text(
                                      'Duplicate',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFB45309),
                                      side: const BorderSide(
                                        color: Color(0xFFB45309),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
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
                                    icon: const Icon(
                                      Icons.hourglass_bottom,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      'Partial',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2563EB),
                                      side: const BorderSide(
                                        color: Color(0xFF2563EB),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
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

  Future<void> _openSettlementImportDialog() async {
    final state = ref.read(appControllerProvider);
    final preview = await showDialog<SettlementImportPreview>(
      context: context,
      builder: (context) => _SettlementImportDialog(
        reconciliationItems: state.reconciliationItems,
        payments: state.payments,
      ),
    );
    if (preview == null) return;
    if (preview.decisions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matching settlement rows found.')),
      );
      return;
    }
    await _applySettlementPreview(preview);
  }

  Future<void> _applySettlementPreview(SettlementImportPreview preview) async {
    if (importingSettlement || updatingItemId != null) return;
    setState(() => importingSettlement = true);
    try {
      final service = ref.read(supabaseFinanceServiceProvider);
      if (service == null) {
        final controller = ref.read(appControllerProvider.notifier);
        for (final decision in preview.decisions) {
          controller.updateReconciliation(
            decision.reconciliationId,
            decision.status,
            decision.reason,
          );
        }
      } else {
        for (final decision in preview.decisions) {
          await service.updateReconciliation(
            reconciliationId: decision.reconciliationId,
            status: decision.status,
            reason: decision.reason,
          );
        }
        await refreshAppStateFromSupabase(
          ref,
          currentUser: ref.read(appControllerProvider).currentUser,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Applied ${preview.decisions.length} settlement decisions.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Settlement import failed: $error')),
      );
    } finally {
      if (mounted) setState(() => importingSettlement = false);
    }
  }
}

class _SettlementImportDialog extends StatefulWidget {
  const _SettlementImportDialog({
    required this.reconciliationItems,
    required this.payments,
  });

  final List<ReconciliationItem> reconciliationItems;
  final List<Payment> payments;

  @override
  State<_SettlementImportDialog> createState() =>
      _SettlementImportDialogState();
}

class _SettlementImportDialogState extends State<_SettlementImportDialog> {
  final csvController = TextEditingController(text: _settlementCsvSample);

  @override
  void dispose() {
    csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = previewSettlementCsv(
      csv: csvController.text,
      reconciliationItems: widget.reconciliationItems,
      payments: widget.payments,
    );

    return AlertDialog(
      title: const Text('Import Settlement CSV'),
      content: SizedBox(
        width: 780,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: csvController,
                  minLines: 7,
                  maxLines: 10,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    labelText: 'Settlement rows',
                    hintText: 'reference,amount,status',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(
                      label: '${preview.matchedCount} matched',
                      color: const Color(0xFF0F766E),
                    ),
                    StatusPill(
                      label: '${preview.partialCount} partial',
                      color: const Color(0xFF2563EB),
                    ),
                    StatusPill(
                      label: '${preview.duplicateCount} duplicate',
                      color: const Color(0xFFB45309),
                    ),
                    StatusPill(
                      label: '${preview.overpaidCount} overpaid',
                      color: const Color(0xFF7C3AED),
                    ),
                    StatusPill(
                      label: '${preview.unmatchedRows.length} unmatched rows',
                      color: preview.unmatchedRows.isEmpty
                          ? const Color(0xFF0F766E)
                          : const Color(0xFFB91C1C),
                    ),
                  ],
                ),
                if (preview.invalidRows.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...preview.invalidRows
                      .take(4)
                      .map(
                        (message) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Color(0xFFB91C1C),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                ],
                if (preview.unmatchedRows.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Unmatched: ${preview.unmatchedRows.take(4).map((row) => row.reference).join(', ')}',
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (preview.decisions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Preview',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  ...preview.decisions
                      .take(5)
                      .map(
                        (decision) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: statusColor(
                              decision.status.label,
                            ).withValues(alpha: 0.12),
                            child: Icon(
                              Icons.fact_check_outlined,
                              color: statusColor(decision.status.label),
                            ),
                          ),
                          title: Text(
                            '${decision.receiptNo} | ${decision.status.label}',
                          ),
                          subtitle: Text(
                            '${decision.reference} | settlement ${moneyFormat.format(decision.settlementAmount)} | receipt ${moneyFormat.format(decision.receiptAmount)}',
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: preview.decisions.isEmpty
              ? null
              : () => Navigator.of(context).pop(preview),
          icon: const Icon(Icons.fact_check_outlined),
          label: Text('Apply ${preview.decisions.length}'),
        ),
      ],
    );
  }
}

const _settlementCsvSample =
    'reference,amount,status\n'
    'CHQ219873,12000,cleared\n'
    'UPI145322,10000,settled';
