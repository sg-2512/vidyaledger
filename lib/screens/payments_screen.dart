import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
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
    studentId ??= state.students.first.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Payment Collection',
          subtitle: 'Record UPI, cash, cheque, and bank-transfer payments with receipts.',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 400,
              child: SectionCard(
                title: 'Record Payment',
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: studentId,
                      decoration: const InputDecoration(labelText: 'Student'),
                      items: state.students
                          .map((student) => DropdownMenuItem(value: student.id, child: Text(student.name)))
                          .toList(),
                      onChanged: (value) => setState(() => studentId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PaymentMode>(
                      initialValue: mode,
                      decoration: const InputDecoration(labelText: 'Payment mode'),
                      items: PaymentMode.values
                          .map((item) => DropdownMenuItem(value: item, child: Text(item.label)))
                          .toList(),
                      onChanged: (value) => setState(() => mode = value ?? mode),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: referenceController,
                      decoration: const InputDecoration(labelText: 'UPI / cheque / bank reference'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(labelText: 'Note'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          final payment = ref.read(appControllerProvider.notifier).recordPayment(
                                studentId: studentId!,
                                amount: double.tryParse(amountController.text) ?? 0,
                                mode: mode,
                                referenceNo: referenceController.text.trim(),
                                note: noteController.text.trim(),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Payment recorded: ${payment.receiptNo}')),
                          );
                        },
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Record Payment'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: SectionCard(
                title: 'Receipt Register',
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Receipt')),
                    DataColumn(label: Text('Student')),
                    DataColumn(label: Text('Mode')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: state.payments.map((payment) {
                    final student = state.students.firstWhere((item) => item.id == payment.studentId);
                    return DataRow(cells: [
                      DataCell(Text(payment.receiptNo)),
                      DataCell(Text(student.name)),
                      DataCell(Text(payment.mode.label)),
                      DataCell(Text(moneyFormat.format(payment.amount))),
                      DataCell(StatusPill(label: payment.status.label, color: statusColor(payment.status.label))),
                      DataCell(
                        Wrap(
                          spacing: 4,
                          children: [
                            TextButton(
                              onPressed: () async {
                                final summary = ref
                                    .read(appControllerProvider.notifier)
                                    .financeFor(student.id);
                                final bytes = await ReportService.buildReceiptPdf(
                                  payment: payment,
                                  student: student,
                                  summary: summary,
                                );
                                await Printing.sharePdf(
                                  bytes: bytes,
                                  filename: '${payment.receiptNo.replaceAll('/', '-')}.pdf',
                                );
                              },
                              child: const Text('PDF'),
                            ),
                            if (payment.mode == PaymentMode.cheque) ...[
                              TextButton(
                                onPressed: () => ref
                                    .read(appControllerProvider.notifier)
                                    .updateChequeStatus(payment.id, ChequeStatus.cleared),
                                child: const Text('Clear'),
                              ),
                              TextButton(
                                onPressed: () => ref
                                    .read(appControllerProvider.notifier)
                                    .updateChequeStatus(payment.id, ChequeStatus.bounced),
                                child: const Text('Bounce'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
