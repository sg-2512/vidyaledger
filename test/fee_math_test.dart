import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidyaledger/models/models.dart';
import 'package:vidyaledger/providers/app_state.dart';

void main() {
  test('approved concessions and completed payments reduce pending amount', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    final summary = controller.financeFor('s-1');

    expect(summary.totalDemand, 38000);
    expect(summary.approvedConcessions, 15000);
    expect(summary.paid, 10000);
    expect(summary.pending, 13000);
  });

  test('pending cheque is excluded until it clears', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);

    final before = controller.financeFor('s-4');
    expect(before.paid, 0);
    expect(before.pending, 34000);

    controller.updateChequeStatus('p-3', ChequeStatus.cleared);

    final after = controller.financeFor('s-4');
    final state = container.read(appControllerProvider);
    final reconciliation = state.reconciliationItems.firstWhere(
      (item) => item.paymentId == 'p-3',
    );

    expect(after.paid, 12000);
    expect(after.pending, 22000);
    expect(reconciliation.status, ReconciliationStatus.matched);
    expect(reconciliation.exceptionReason, isEmpty);
  });

  test('bounced cheque reopens reconciliation exception', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);

    controller.updateChequeStatus('p-3', ChequeStatus.bounced);

    final summary = controller.financeFor('s-4');
    final state = container.read(appControllerProvider);
    final payment = state.payments.firstWhere((item) => item.id == 'p-3');
    final reconciliation = state.reconciliationItems.firstWhere(
      (item) => item.paymentId == 'p-3',
    );

    expect(summary.paid, 0);
    expect(summary.pending, 34000);
    expect(payment.status, PaymentStatus.bounced);
    expect(reconciliation.status, ReconciliationStatus.unmatched);
    expect(
      reconciliation.exceptionReason,
      'Cheque bounced; receivable reopened',
    );
  });

  test('demo UPI payment request generates a payable UPI link', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);

    final request = controller.createPaymentRequest(
      studentId: 's-1',
      amount: 2500,
      provider: PaymentProvider.upiIntent,
      note: 'Transport balance',
    );
    final state = container.read(appControllerProvider);

    expect(request.provider, PaymentProvider.upiIntent);
    expect(request.status, PaymentRequestStatus.created);
    expect(request.payableLink, startsWith('upi://pay?'));
    expect(request.payableLink, contains('am=2500.00'));
    expect(state.paymentRequests.first.id, request.id);
  });
}
