import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_state.dart';
import '../widgets/common.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(appControllerProvider.notifier);
    final students = controller.visibleStudents().where((student) {
      final needle = query.toLowerCase();
      return student.name.toLowerCase().contains(needle) ||
          student.admissionNo.toLowerCase().contains(needle) ||
          student.classLabel.toLowerCase().contains(needle);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Students',
          subtitle: 'Search finance profiles, category support, payments, and pending dues.',
          trailing: SizedBox(
            width: 300,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search student or admission no.',
              ),
              onChanged: (value) => setState(() => query = value),
            ),
          ),
        ),
        SectionCard(
          title: 'Student Finance Register',
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Admission No.')),
              DataColumn(label: Text('Student')),
              DataColumn(label: Text('Class')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Pending')),
              DataColumn(label: Text('Action')),
            ],
            rows: students.map((student) {
              final summary = controller.financeFor(student.id);
              return DataRow(
                cells: [
                  DataCell(Text(student.admissionNo)),
                  DataCell(Text(student.name)),
                  DataCell(Text(student.classLabel)),
                  DataCell(StatusPill(label: student.category, color: const Color(0xFF0F766E))),
                  DataCell(Text(moneyFormat.format(summary.pending))),
                  DataCell(
                    TextButton.icon(
                      onPressed: () => context.go('/students/${student.id}'),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open'),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
