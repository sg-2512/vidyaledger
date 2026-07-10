import '../models/models.dart';
import 'csv_utils.dart';

class SettlementImportPreview {
  const SettlementImportPreview({
    required this.decisions,
    required this.unmatchedRows,
    required this.invalidRows,
  });

  final List<SettlementDecision> decisions;
  final List<SettlementCsvEntry> unmatchedRows;
  final List<String> invalidRows;

  int get matchedCount => decisions
      .where((item) => item.status == ReconciliationStatus.matched)
      .length;

  int get duplicateCount => decisions
      .where((item) => item.status == ReconciliationStatus.duplicate)
      .length;

  int get partialCount => decisions
      .where((item) => item.status == ReconciliationStatus.partial)
      .length;

  int get overpaidCount => decisions
      .where((item) => item.status == ReconciliationStatus.overpaid)
      .length;
}

class SettlementDecision {
  const SettlementDecision({
    required this.reconciliationId,
    required this.reference,
    required this.receiptNo,
    required this.settlementAmount,
    required this.receiptAmount,
    required this.status,
    required this.reason,
  });

  final String reconciliationId;
  final String reference;
  final String receiptNo;
  final double settlementAmount;
  final double receiptAmount;
  final ReconciliationStatus status;
  final String reason;
}

class SettlementCsvEntry {
  const SettlementCsvEntry({
    required this.rowNumber,
    required this.reference,
    required this.amount,
    required this.status,
  });

  final int rowNumber;
  final String reference;
  final double amount;
  final String status;

  bool get isSuccess {
    final value = status.toLowerCase();
    return status.trim().isEmpty ||
        value.contains('success') ||
        value.contains('settled') ||
        value.contains('paid') ||
        value.contains('credit') ||
        value.contains('cleared') ||
        value == 'matched';
  }
}

SettlementImportPreview previewSettlementCsv({
  required String csv,
  required List<ReconciliationItem> reconciliationItems,
  required List<Payment> payments,
}) {
  final records = parseCsvRecords(csv);
  final entries = <SettlementCsvEntry>[];
  final invalidRows = <String>[];

  for (final record in records) {
    final reference = record.firstValue(const [
      'reference',
      'channel_ref',
      'channelRef',
      'payment_ref',
      'paymentRef',
      'utr',
      'transaction_id',
      'transactionId',
      'receipt',
      'receipt_no',
      'receiptNo',
    ]);
    final amountText = record.firstValue(const [
      'amount',
      'settlement_amount',
      'settlementAmount',
      'paid_amount',
      'paidAmount',
      'credit',
    ]);
    final amount = parseCsvAmount(amountText);
    final status = record.firstValue(const [
      'status',
      'state',
      'gateway_status',
      'gatewayStatus',
      'settlement_status',
      'settlementStatus',
    ]);

    if (reference.isEmpty || amount == null) {
      invalidRows.add(
        'Row ${record.rowNumber}: reference and amount are required.',
      );
      continue;
    }
    entries.add(
      SettlementCsvEntry(
        rowNumber: record.rowNumber,
        reference: reference,
        amount: amount,
        status: status,
      ),
    );
  }

  final paymentsById = {for (final payment in payments) payment.id: payment};
  final lookup = <String, List<ReconciliationItem>>{};
  for (final item in reconciliationItems) {
    final payment = paymentsById[item.paymentId];
    for (final key in [
      item.channelRef,
      if (payment != null) payment.referenceNo,
      if (payment != null) payment.receiptNo,
    ]) {
      final normalized = _normalizeReference(key);
      if (normalized.isEmpty) continue;
      lookup.putIfAbsent(normalized, () => []).add(item);
    }
  }

  final groupedEntries = <String, List<SettlementCsvEntry>>{};
  for (final entry in entries) {
    groupedEntries
        .putIfAbsent(_normalizeReference(entry.reference), () => [])
        .add(entry);
  }

  final decisions = <SettlementDecision>[];
  final unmatchedRows = <SettlementCsvEntry>[];
  final seenItemIds = <String>{};

  for (final entryGroup in groupedEntries.entries) {
    final matchingItems = lookup[entryGroup.key];
    if (matchingItems == null || matchingItems.isEmpty) {
      unmatchedRows.addAll(entryGroup.value);
      continue;
    }

    final duplicateSettlementRows = entryGroup.value.length > 1;
    for (final item in matchingItems) {
      if (!seenItemIds.add(item.id)) continue;
      final payment = paymentsById[item.paymentId];
      if (payment == null) continue;

      final entry = entryGroup.value.first;
      final status = _decisionStatus(
        entry: entry,
        receiptAmount: payment.amount,
        duplicateSettlementRows: duplicateSettlementRows,
      );
      decisions.add(
        SettlementDecision(
          reconciliationId: item.id,
          reference: entry.reference,
          receiptNo: payment.receiptNo,
          settlementAmount: entry.amount,
          receiptAmount: payment.amount,
          status: status,
          reason: _decisionReason(
            status: status,
            gatewayStatus: entry.status,
            settlementAmount: entry.amount,
            receiptAmount: payment.amount,
            duplicateSettlementRows: duplicateSettlementRows,
          ),
        ),
      );
    }
  }

  return SettlementImportPreview(
    decisions: decisions,
    unmatchedRows: unmatchedRows,
    invalidRows: invalidRows,
  );
}

ReconciliationStatus _decisionStatus({
  required SettlementCsvEntry entry,
  required double receiptAmount,
  required bool duplicateSettlementRows,
}) {
  if (duplicateSettlementRows) return ReconciliationStatus.duplicate;
  if (!entry.isSuccess) return ReconciliationStatus.unmatched;

  final delta = entry.amount - receiptAmount;
  if (delta.abs() <= 0.5) return ReconciliationStatus.matched;
  if (delta < 0) return ReconciliationStatus.partial;
  return ReconciliationStatus.overpaid;
}

String _decisionReason({
  required ReconciliationStatus status,
  required String gatewayStatus,
  required double settlementAmount,
  required double receiptAmount,
  required bool duplicateSettlementRows,
}) {
  if (duplicateSettlementRows) return 'Duplicate settlement rows in import';
  if (status == ReconciliationStatus.matched) return '';
  if (status == ReconciliationStatus.unmatched) {
    return gatewayStatus.trim().isEmpty
        ? 'Gateway row not marked successful'
        : 'Gateway status: $gatewayStatus';
  }
  if (status == ReconciliationStatus.partial) {
    return 'Settlement amount $settlementAmount is lower than receipt $receiptAmount';
  }
  if (status == ReconciliationStatus.overpaid) {
    return 'Settlement amount $settlementAmount is higher than receipt $receiptAmount';
  }
  return '';
}

String _normalizeReference(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
