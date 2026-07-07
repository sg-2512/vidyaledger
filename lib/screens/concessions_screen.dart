import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/supabase_providers.dart';
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
  bool submitting = false;
  String? updatingConcessionId;

  @override
  void dispose() {
    amountController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    if (state.students.isNotEmpty && studentId == null) {
      studentId = state.students.first.id;
    }
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
                        onPressed: submitting || studentId == null
                            ? null
                            : _submitConcession,
                        icon: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.verified_user),
                        label: Text(
                          submitting ? 'Submitting...' : 'Submit Request',
                        ),
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
                    final studentName = _studentName(state, item.studentId);
                    final updating = updatingConcessionId == item.id;
                    return DataRow(cells: [
                      DataCell(Text(studentName)),
                      DataCell(Text(item.category)),
                      DataCell(Text(item.fundingSource)),
                      DataCell(Text(moneyFormat.format(item.amount))),
                      DataCell(StatusPill(label: item.status.label, color: statusColor(item.status.label))),
                      DataCell(
                        Wrap(
                          spacing: 4,
                          children: [
                            TextButton(
                              onPressed: updating ||
                                      item.status == ConcessionStatus.approved
                                  ? null
                                  : () => _updateConcessionStatus(
                                        item.id,
                                        ConcessionStatus.approved,
                                      ),
                              child: Text(updating ? 'Saving' : 'Approve'),
                            ),
                            TextButton(
                              onPressed: updating ||
                                      item.status == ConcessionStatus.rejected
                                  ? null
                                  : () => _updateConcessionStatus(
                                        item.id,
                                        ConcessionStatus.rejected,
                                      ),
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

  Future<void> _submitConcession() async {
    final selectedStudentId = studentId;
    if (selectedStudentId == null || submitting) return;

    final amount = double.tryParse(amountController.text) ?? 0;
    final reason = reasonController.text.trim();
    if (amount <= 0 || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter an amount and document note before submitting.'),
        ),
      );
      return;
    }

    setState(() => submitting = true);
    try {
      final service = ref.read(supabaseFinanceServiceProvider);
      if (service == null) {
        ref.read(appControllerProvider.notifier).submitConcession(
              studentId: selectedStudentId,
              category: category,
              concessionType: '$category fee support',
              amount: amount,
              fundingSource: fundingSource,
              reason: reason,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo concession request submitted.')),
        );
        return;
      }

      await service.submitConcession(
        studentId: selectedStudentId,
        category: category,
        concessionType: '$category fee support',
        amount: amount,
        fundingSource: fundingSource,
        reason: reason,
      );
      await refreshAppStateFromSupabase(
        ref,
        currentUser: ref.read(appControllerProvider).currentUser,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backend concession request submitted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Concession submission failed: $error')),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> _updateConcessionStatus(
    String concessionId,
    ConcessionStatus status,
  ) async {
    if (updatingConcessionId != null) return;

    setState(() => updatingConcessionId = concessionId);
    try {
      final service = ref.read(supabaseFinanceServiceProvider);
      if (service == null) {
        ref
            .read(appControllerProvider.notifier)
            .updateConcessionStatus(concessionId, status);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Demo concession ${status.label}.')),
        );
        return;
      }

      await service.updateConcessionStatus(concessionId, status);
      await refreshAppStateFromSupabase(
        ref,
        currentUser: ref.read(appControllerProvider).currentUser,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backend concession ${status.label.toLowerCase()} and audited.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Concession update failed: $error')),
      );
    } finally {
      if (mounted) setState(() => updatingConcessionId = null);
    }
  }

  String _studentName(AppState state, String studentId) {
    for (final student in state.students) {
      if (student.id == studentId) return student.name;
    }
    return 'Unknown student';
  }
}
