import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
