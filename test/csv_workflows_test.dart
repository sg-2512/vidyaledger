import 'package:flutter_test/flutter_test.dart';
import 'package:vidyaledger/models/models.dart';
import 'package:vidyaledger/utils/csv_utils.dart';
import 'package:vidyaledger/utils/settlement_reconciliation.dart';

void main() {
  test('CSV parser handles quoted commas and normalized headers', () {
    final records = parseCsvRecords(
      'Student Name,Guardian Phone,Note\n'
      '"Asha, Rao",9876543210,"Uses ""school van"""',
    );

    expect(records, hasLength(1));
    expect(records.first.firstValue(['student_name']), 'Asha, Rao');
    expect(records.first.firstValue(['guardianPhone']), '9876543210');
    expect(records.first.firstValue(['note']), 'Uses "school van"');
  });

  test('settlement preview marks exact, partial, and duplicate rows', () {
    final payments = [
      Payment(
        id: 'p-1',
        studentId: 's-1',
        amount: 1000,
        mode: PaymentMode.upi,
        status: PaymentStatus.completed,
        date: DateTime(2026, 7, 1),
        referenceNo: 'UPI-001',
        receiptNo: 'VL/2026/0001',
        note: '',
      ),
      Payment(
        id: 'p-2',
        studentId: 's-2',
        amount: 800,
        mode: PaymentMode.bankTransfer,
        status: PaymentStatus.completed,
        date: DateTime(2026, 7, 1),
        referenceNo: 'NEFT-002',
        receiptNo: 'VL/2026/0002',
        note: '',
      ),
      Payment(
        id: 'p-3',
        studentId: 's-3',
        amount: 600,
        mode: PaymentMode.upi,
        status: PaymentStatus.completed,
        date: DateTime(2026, 7, 1),
        referenceNo: 'UPI-003',
        receiptNo: 'VL/2026/0003',
        note: '',
      ),
    ];
    final items = [
      ReconciliationItem(
        id: 'r-1',
        paymentId: 'p-1',
        channelRef: 'UPI-001',
        status: ReconciliationStatus.unmatched,
        exceptionReason: 'Pending settlement verification',
      ),
      ReconciliationItem(
        id: 'r-2',
        paymentId: 'p-2',
        channelRef: 'NEFT-002',
        status: ReconciliationStatus.unmatched,
        exceptionReason: 'Pending settlement verification',
      ),
      ReconciliationItem(
        id: 'r-3',
        paymentId: 'p-3',
        channelRef: 'UPI-003',
        status: ReconciliationStatus.unmatched,
        exceptionReason: 'Pending settlement verification',
      ),
    ];

    final preview = previewSettlementCsv(
      csv:
          'reference,amount,status\n'
          'UPI-001,1000,settled\n'
          'NEFT-002,500,settled\n'
          'UPI-003,600,success\n'
          'UPI-003,600,success\n'
          'MISSING,200,settled\n',
      reconciliationItems: items,
      payments: payments,
    );

    expect(preview.matchedCount, 1);
    expect(preview.partialCount, 1);
    expect(preview.duplicateCount, 1);
    expect(preview.unmatchedRows.single.reference, 'MISSING');
  });
}
