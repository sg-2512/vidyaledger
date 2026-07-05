import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';

class ConcessionsScreen extends ConsumerStatefulWidget {
  const ConcessionsScreen({super.key});

  @override
  ConsumerState<ConcessionsScreen> createState() => _ConcessionsScreenState();
}

class _ConcessionsScreenState extends ConsumerState<ConcessionsScreen> {
  String? studentId;
  String category = 'EWS';
  String fundingSource = 'School waiver';
  final amountController = TextEditingController(text: '5000');
  final reasonController = TextEditingController(text: 'Verified document and principal review required.');

  @override
  void dispose() {
    amountController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    studentId ??= state.students.first.id;
    const categories = ['RTE', 'EWS', 'SC', 'ST', 'OBC', 'Minority', 'Girl Child', 'PwD', 'Sibling', 'Staff Child'];
    const fundingSources = ['School waiver', 'Government reimbursement', 'Scholarship receivable', 'Sponsor', 'Trust fund'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Exemption & Concession Engine',
          subtitle: 'Configurable Indian-school support workflows with approval and audit trail.',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 410,
              child: SectionCard(
                title: 'Submit Concession Request',
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: studentId,
                      decoration: const InputDecoration(labelText: 'Student'),
                      items: state.students
                          .map((student) => DropdownMenuItem(value: student.id, child: Text('${student.name} (${student.category})')))
                          .toList(),
                      onChanged: (value) => setState(() => studentId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Concession category'),
                      items: categories
                          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                          .toList(),
                      onChanged: (value) => setState(() => category = value ?? category),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: fundingSource,
                      decoration: const InputDecoration(labelText: 'Funding source'),
                      items: fundingSources
                          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                          .toList(),
                      onChanged: (value) => setState(() => fundingSource = value ?? fundingSource),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Reason / document note'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          ref.read(appControllerProvider.notifier).submitConcession(
                                studentId: studentId!,
                                category: category,
                                concessionType: '$category fee support',
                                amount: double.tryParse(amountController.text) ?? 0,
                                fundingSource: fundingSource,
                                reason: reasonController.text.trim(),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Concession request submitted.')),
                          );
                        },
                        icon: const Icon(Icons.verified_user),
                        label: const Text('Submit Request'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: SectionCard(
                title: 'Approval Queue',
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Student')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Funding')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: state.concessions.map((item) {
                    final student = state.students.firstWhere((s) => s.id == item.studentId);
                    return DataRow(cells: [
                      DataCell(Text(student.name)),
                      DataCell(Text(item.category)),
                      DataCell(Text(item.fundingSource)),
                      DataCell(Text(moneyFormat.format(item.amount))),
                      DataCell(StatusPill(label: item.status.label, color: statusColor(item.status.label))),
                      DataCell(
                        Wrap(
                          spacing: 4,
                          children: [
                            TextButton(
                              onPressed: item.status == ConcessionStatus.approved
                                  ? null
                                  : () => ref
                                      .read(appControllerProvider.notifier)
                                      .updateConcessionStatus(item.id, ConcessionStatus.approved),
                              child: const Text('Approve'),
                            ),
                            TextButton(
                              onPressed: item.status == ConcessionStatus.rejected
                                  ? null
                                  : () => ref
                                      .read(appControllerProvider.notifier)
                                      .updateConcessionStatus(item.id, ConcessionStatus.rejected),
                              child: const Text('Reject'),
                            ),
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
