import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/app_state.dart';
import '../widgets/common.dart';

class FeeEngineScreen extends ConsumerStatefulWidget {
  const FeeEngineScreen({super.key});

  @override
  ConsumerState<FeeEngineScreen> createState() => _FeeEngineScreenState();
}

class _FeeEngineScreenState extends ConsumerState<FeeEngineScreen> {
  final titleController = TextEditingController(text: 'Term Tuition Fee');
  final amountController = TextEditingController(text: '12000');
  final lateFeeController = TextEditingController(text: '500');
  String selectedClass = '7';
  String? selectedFeeHeadId;

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    lateFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    selectedFeeHeadId ??= state.feeHeads.first.id;
    final classNames = state.students.map((student) => student.className).toSet().toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Dynamic Fee Engine',
          subtitle: 'Create fee heads, rules, due dates, late fee policies, and class-wise demands.',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 390,
              child: SectionCard(
                title: 'Generate Fee Demand',
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Fee rule title'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedFeeHeadId,
                      decoration: const InputDecoration(labelText: 'Fee head'),
                      items: state.feeHeads
                          .map((head) => DropdownMenuItem(value: head.id, child: Text(head.name)))
                          .toList(),
                      onChanged: (value) => setState(() => selectedFeeHeadId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedClass,
                      decoration: const InputDecoration(labelText: 'Assign to class'),
                      items: classNames
                          .map((className) => DropdownMenuItem(value: className, child: Text('Class $className')))
                          .toList(),
                      onChanged: (value) => setState(() => selectedClass = value ?? selectedClass),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lateFeeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Late fee amount'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          ref.read(appControllerProvider.notifier).generateFeeDemand(
                                feeHeadId: selectedFeeHeadId!,
                                title: titleController.text.trim(),
                                amount: double.tryParse(amountController.text) ?? 0,
                                className: selectedClass,
                                dueDate: DateTime.now().add(const Duration(days: 14)),
                                lateFeeAmount: double.tryParse(lateFeeController.text) ?? 0,
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fee demand generated.')),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Generate Demand'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: SectionCard(
                title: 'Active Fee Rules',
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Rule')),
                    DataColumn(label: Text('Fee Head')),
                    DataColumn(label: Text('Scope')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Due')),
                  ],
                  rows: state.feeRules.map((rule) {
                    final head = state.feeHeads.firstWhere((item) => item.id == rule.feeHeadId);
                    return DataRow(cells: [
                      DataCell(Text(rule.title)),
                      DataCell(Text(head.name)),
                      DataCell(Text(rule.scopeLabel)),
                      DataCell(Text(moneyFormat.format(rule.amount))),
                      DataCell(Text(DateFormat.yMMMd().format(rule.dueDate))),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Fee Heads',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: state.feeHeads
                .map(
                  (head) => Chip(
                    avatar: Icon(head.refundable ? Icons.replay : Icons.receipt_long),
                    label: Text('${head.name} | ${head.ledger}'),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
