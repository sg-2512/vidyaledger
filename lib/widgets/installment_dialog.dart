import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import 'common.dart';

class InstallmentDialog extends ConsumerStatefulWidget {
  const InstallmentDialog({required this.student, this.feeDemand, super.key});

  final Student student;
  final FeeDemand? feeDemand;

  @override
  ConsumerState<InstallmentDialog> createState() => _InstallmentDialogState();
}

class _InstallmentDialogState extends ConsumerState<InstallmentDialog> {
  int numberOfInstallments = 3;
  late TextEditingController totalAmountController;
  DateTime firstDueDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    final defaultAmount = widget.feeDemand?.amount ?? 12000.0;
    totalAmountController = TextEditingController(
      text: defaultAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    totalAmountController.dispose();
    super.dispose();
  }

  void _createPlan() {
    final totalAmount = double.tryParse(totalAmountController.text.trim()) ?? 0;
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid total fee amount.')),
      );
      return;
    }

    final demandId = widget.feeDemand?.id ?? 'fd-custom';
    ref
        .read(appControllerProvider.notifier)
        .createInstallmentPlan(
          studentId: widget.student.id,
          feeDemandId: demandId,
          numberOfInstallments: numberOfInstallments,
          totalAmount: totalAmount,
          firstDueDate: firstDueDate,
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Created $numberOfInstallments EMI installment plan for ${widget.student.name}.',
        ),
        backgroundColor: const Color(0xFF0F766E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = double.tryParse(totalAmountController.text.trim()) ?? 0;
    final perInstallment = numberOfInstallments > 0
        ? (totalAmount / numberOfInstallments).roundToDouble()
        : 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Installment EMI Plan',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Split fee demand into flexible payments for ${widget.student.name}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: totalAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Fee Demand Amount (INR)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: numberOfInstallments,
                      decoration: const InputDecoration(
                        labelText: 'Number of Installments',
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 2,
                          child: Text('2 Installments'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('3 Installments (Quarterly)'),
                        ),
                        DropdownMenuItem(
                          value: 4,
                          child: Text('4 Installments'),
                        ),
                        DropdownMenuItem(
                          value: 6,
                          child: Text('6 Installments (Bi-monthly)'),
                        ),
                        DropdownMenuItem(
                          value: 10,
                          child: Text('10 Installments (Monthly)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => numberOfInstallments = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: firstDueDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 30),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setState(() => firstDueDate = picked);
                        }
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        'First Due Date: ${DateFormat('dd MMM yyyy').format(firstDueDate)}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Installment Schedule Breakdown Preview:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: numberOfInstallments,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  itemBuilder: (context, index) {
                    final isLast = index == numberOfInstallments - 1;
                    final amt = isLast
                        ? totalAmount -
                              (perInstallment * (numberOfInstallments - 1))
                        : perInstallment;
                    final dueDate = DateTime(
                      firstDueDate.year,
                      firstDueDate.month + index,
                      firstDueDate.day,
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundColor: const Color(0xFFDDD6FE),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6D28D9),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Installment ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            moneyFormat.format(amt),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                          Text(
                            'Due: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _createPlan,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                    ),
                    icon: const Icon(Icons.add_task),
                    label: const Text('Generate Installment Plan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
