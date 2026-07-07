import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/finance_providers.dart';
import '../providers/supabase_providers.dart';
import '../services/report_service.dart';
import '../widgets/common.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  String? studentId;
  PaymentMode mode = PaymentMode.upi;
  final amountController = TextEditingController(text: '8000');
  final referenceController = TextEditingController(text: 'UPI-DEMO-001');
  final noteController = TextEditingController(text: 'Term fee payment');
  bool recording = false;

  @override
  void dispose() {
    amountController.dispose();
    referenceController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final stats = ref.watch(dashboardStatsProvider);
    studentId ??= state.students.first.id;
    final chequeQueue = state.payments
        .where((payment) => payment.mode == PaymentMode.cheque)
        .where((payment) => payment.status == PaymentStatus.pending)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Payment Collection',
          subtitle:
              'Counter collection, receipt issue, and cheque lifecycle control.',
        ),
        _PaymentSummary(
          collected: stats.totalCollected,
          pending: stats.totalPending,
          chequeQueue: chequeQueue,
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            final form = _PaymentForm(
              students: state.students,
              selectedStudentId: studentId,
              mode: mode,
              amountController: amountController,
              referenceController: referenceController,
              noteController: noteController,
              recording: recording,
              onStudentChanged: (value) => setState(() => studentId = value),
              onModeChanged: (value) => setState(() => mode = value ?? mode),
              onRecord: _recordPayment,
            );
            final receipts = _ReceiptRegister(
              students: state.students,
              payments: state.payments,
              school: state.school,
            );

            return stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [form, const SizedBox(height: 18), receipts],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 410, child: form),
                      const SizedBox(width: 18),
                      Expanded(child: receipts),
                    ],
                  );
          },
        ),
      ],
    );
  }

  Future<void> _recordPayment() async {
    if (studentId == null || recording) return;

    setState(() => recording = true);
    try {
      final service = ref.read(supabaseFinanceServiceProvider);
      final amount = double.tryParse(amountController.text) ?? 0;
      final referenceNo = referenceController.text.trim();
      final note = noteController.text.trim();

      if (service == null) {
        final payment = ref
            .read(appControllerProvider.notifier)
            .recordPayment(
              studentId: studentId!,
              amount: amount,
              mode: mode,
              referenceNo: referenceNo,
              note: note,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment recorded: ${payment.receiptNo}')),
        );
        return;
      }

      final payment = await service.recordPayment(
        studentId: studentId!,
        amount: amount,
        mode: mode,
        referenceNo: referenceNo,
        note: note,
      );
      await refreshAppStateFromSupabase(
        ref,
        currentUser: ref.read(appControllerProvider).currentUser,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backend payment saved: ${payment.receiptNo}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment failed: $error')));
    } finally {
      if (mounted) setState(() => recording = false);
    }
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({
    required this.collected,
    required this.pending,
    required this.chequeQueue,
  });

  final double collected;
  final double pending;
  final int chequeQueue;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: MediaQuery.of(context).size.width > 900 ? 3.2 : 3.8,
      children: [
        _PaymentMetric(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Collected',
          value: moneyFormat.format(collected),
          color: const Color(0xFF047857),
        ),
        _PaymentMetric(
          icon: Icons.pending_actions_outlined,
          label: 'Pending Dues',
          value: moneyFormat.format(pending),
          color: const Color(0xFFB45309),
        ),
        _PaymentMetric(
          icon: Icons.price_check_outlined,
          label: 'Cheque Queue',
          value: chequeQueue.toString(),
          color: const Color(0xFF2563EB),
        ),
      ],
    );
  }
}

class _PaymentMetric extends StatelessWidget {
  const _PaymentMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentForm extends StatelessWidget {
  const _PaymentForm({
    required this.students,
    required this.selectedStudentId,
    required this.mode,
    required this.amountController,
    required this.referenceController,
    required this.noteController,
    required this.recording,
    required this.onStudentChanged,
    required this.onModeChanged,
    required this.onRecord,
  });

  final List<Student> students;
  final String? selectedStudentId;
  final PaymentMode mode;
  final TextEditingController amountController;
  final TextEditingController referenceController;
  final TextEditingController noteController;
  final bool recording;
  final ValueChanged<String?> onStudentChanged;
  final ValueChanged<PaymentMode?> onModeChanged;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Record Payment',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedStudentId,
            decoration: const InputDecoration(labelText: 'Student'),
            items: students
                .map(
                  (student) => DropdownMenuItem(
                    value: student.id,
                    child: Text('${student.name} - ${student.classLabel}'),
                  ),
                )
                .toList(),
            onChanged: onStudentChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PaymentMode>(
            initialValue: mode,
            decoration: const InputDecoration(labelText: 'Payment mode'),
            items: PaymentMode.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.label)),
                )
                .toList(),
            onChanged: onModeChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixIcon: Icon(Icons.currency_rupee),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: referenceController,
            decoration: const InputDecoration(
              labelText: 'UPI / cheque / bank reference',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Collection note',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: recording ? null : onRecord,
              icon: recording
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.receipt_long),
              label: Text(
                recording ? 'Recording...' : 'Record and Issue Receipt',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRegister extends ConsumerWidget {
  const _ReceiptRegister({
    required this.students,
    required this.payments,
    required this.school,
  });

  final List<Student> students;
  final List<Payment> payments;
  final SchoolProfile school;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      title: 'Receipt Register',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 860),
          child: Column(
            children: payments.map((payment) {
              final student = students.firstWhere(
                (item) => item.id == payment.studentId,
              );
              Future<void> updateCheque(ChequeStatus status) async {
                try {
                  final service = ref.read(supabaseFinanceServiceProvider);
                  if (service == null) {
                    ref
                        .read(appControllerProvider.notifier)
                        .updateChequeStatus(payment.id, status);
                  } else {
                    await service.updateChequeStatus(payment.id, status);
                    await refreshAppStateFromSupabase(
                      ref,
                      currentUser: ref.read(appControllerProvider).currentUser,
                    );
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cheque marked ${status.name}.')),
                  );
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cheque update failed: $error')),
                  );
                }
              }

              return _ReceiptRow(
                payment: payment,
                student: student,
                onPdf: () async {
                  final summary = ref.read(financeSummaryProvider(student.id));
                  final bytes = await ReportService.buildReceiptPdf(
                    payment: payment,
                    student: student,
                    summary: summary,
                    school: school,
                  );
                  await Printing.sharePdf(
                    bytes: bytes,
                    filename: '${payment.receiptNo.replaceAll('/', '-')}.pdf',
                  );
                },
                onClear: payment.mode == PaymentMode.cheque
                    ? () => updateCheque(ChequeStatus.cleared)
                    : null,
                onBounce: payment.mode == PaymentMode.cheque
                    ? () => updateCheque(ChequeStatus.bounced)
                    : null,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.payment,
    required this.student,
    required this.onPdf,
    required this.onClear,
    required this.onBounce,
  });

  final Payment payment;
  final Student student;
  final VoidCallback onPdf;
  final VoidCallback? onClear;
  final VoidCallback? onBounce;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 860,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 132,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.receiptNo,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payment.referenceNo,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 180,
              child: Text(
                '${student.name}\nClass ${student.classLabel}',
                style: const TextStyle(height: 1.35),
              ),
            ),
            SizedBox(width: 120, child: Text(payment.mode.label)),
            SizedBox(
              width: 110,
              child: Text(moneyFormat.format(payment.amount)),
            ),
            SizedBox(
              width: 118,
              child: StatusPill(
                label: payment.status.label,
                color: statusColor(payment.status.label),
              ),
            ),
            SizedBox(
              width: 252,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MiniAction(
                    label: 'PDF',
                    icon: Icons.picture_as_pdf,
                    onTap: onPdf,
                  ),
                  if (onClear != null)
                    _MiniAction(
                      label: 'Clear',
                      icon: Icons.check_circle_outline,
                      onTap: onClear!,
                    ),
                  if (onBounce != null)
                    _MiniAction(
                      label: 'Bounce',
                      icon: Icons.report_gmailerrorred,
                      onTap: onBounce!,
                      danger: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFB91C1C) : const Color(0xFF0F766E);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
