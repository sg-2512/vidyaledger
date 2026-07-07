import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/finance_providers.dart';
import '../providers/supabase_providers.dart';
import '../services/report_service.dart';
import '../widgets/common.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  String query = '';
  String classFilter = 'All';
  String sectionFilter = 'All';
  String categoryFilter = 'All';
  bool addingStudent = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final user = state.currentUser;
    final visibleStudents = ref.watch(visibleStudentsProvider);
    final classes = _options(
      visibleStudents.map((student) => student.className),
    );
    final sections = _options(
      visibleStudents.map((student) => student.section),
    );
    final categories = _options(
      visibleStudents.map((student) => student.category),
    );
    final students = visibleStudents.where((student) {
      final needle = query.toLowerCase();
      final matchesSearch =
          student.name.toLowerCase().contains(needle) ||
          student.admissionNo.toLowerCase().contains(needle) ||
          student.classLabel.toLowerCase().contains(needle) ||
          student.category.toLowerCase().contains(needle);
      final matchesClass =
          classFilter == 'All' || student.className == classFilter;
      final matchesSection =
          sectionFilter == 'All' || student.section == sectionFilter;
      final matchesCategory =
          categoryFilter == 'All' || student.category == categoryFilter;
      return matchesSearch && matchesClass && matchesSection && matchesCategory;
    }).toList();
    final canManageStudents = user != null && user.role != UserRole.parent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Student Master Register',
          subtitle:
              'Class-section segregation, guardian records, fee status, and exportable student details.',
          trailing: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: students.isEmpty
                    ? null
                    : () async {
                        final bytes =
                            await ReportService.buildStudentRegisterReport(
                              state: state,
                              students: students,
                            );
                        await Printing.sharePdf(
                          bytes: bytes,
                          filename: 'vidyaledger-student-register.pdf',
                        );
                      },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Export Register'),
              ),
              if (canManageStudents)
                FilledButton.icon(
                  onPressed: addingStudent ? null : _openAddStudentDialog,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add Student'),
                ),
            ],
          ),
        ),
        _ClassSectionSummary(students: students),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Segmentation',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search',
                    hintText: 'Student, admission, class, category',
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
              ),
              _FilterDropdown(
                label: 'Class',
                value: classFilter,
                values: classes,
                onChanged: (value) => setState(() => classFilter = value),
              ),
              _FilterDropdown(
                label: 'Section',
                value: sectionFilter,
                values: sections,
                onChanged: (value) => setState(() => sectionFilter = value),
              ),
              _FilterDropdown(
                label: 'Category',
                value: categoryFilter,
                values: categories,
                onChanged: (value) => setState(() => categoryFilter = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Student Finance Register (${students.length})',
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Admission No.')),
              DataColumn(label: Text('Student')),
              DataColumn(label: Text('Class')),
              DataColumn(label: Text('Section')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Guardian')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Pending')),
              DataColumn(label: Text('Action')),
            ],
            rows: students.map((student) {
              final summary = ref.watch(financeSummaryProvider(student.id));
              final guardian = _guardianFor(state, student.guardianId);
              return DataRow(
                cells: [
                  DataCell(Text(student.admissionNo)),
                  DataCell(Text(student.name)),
                  DataCell(Text('Class ${student.className}')),
                  DataCell(Text(student.section)),
                  DataCell(
                    StatusPill(
                      label: student.category,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                  DataCell(Text(guardian?.name ?? '-')),
                  DataCell(
                    Text(
                      student.phone.isNotEmpty
                          ? student.phone
                          : guardian?.phone ?? '-',
                    ),
                  ),
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

  List<String> _options(Iterable<String> values) {
    final sorted =
        values.where((value) => value.trim().isNotEmpty).toSet().toList()
          ..sort();
    return ['All', ...sorted];
  }

  Guardian? _guardianFor(AppState state, String guardianId) {
    for (final guardian in state.guardians) {
      if (guardian.id == guardianId) return guardian;
    }
    return null;
  }

  Future<void> _openAddStudentDialog() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _AddStudentDialog(saving: addingStudent, onSubmit: _addStudent),
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student added to the register.')),
      );
    }
  }

  Future<bool> _addStudent(_StudentFormData data) async {
    if (addingStudent) return false;
    setState(() => addingStudent = true);
    try {
      final service = ref.read(supabaseFinanceServiceProvider);
      if (service == null) {
        ref
            .read(appControllerProvider.notifier)
            .addStudentWithGuardian(
              admissionNo: data.admissionNo,
              studentName: data.studentName,
              className: data.className,
              section: data.section,
              category: data.category,
              studentPhone: data.studentPhone,
              guardianName: data.guardianName,
              guardianPhone: data.guardianPhone,
              guardianEmail: data.guardianEmail,
              guardianAddress: data.guardianAddress,
            );
      } else {
        await service.addStudentWithGuardian(
          admissionNo: data.admissionNo,
          studentName: data.studentName,
          className: data.className,
          section: data.section,
          category: data.category,
          studentPhone: data.studentPhone,
          guardianName: data.guardianName,
          guardianPhone: data.guardianPhone,
          guardianEmail: data.guardianEmail,
          guardianAddress: data.guardianAddress,
        );
        await refreshAppStateFromSupabase(
          ref,
          currentUser: ref.read(appControllerProvider).currentUser,
        );
      }
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Student add failed: $error')));
      }
      return false;
    } finally {
      if (mounted) setState(() => addingStudent = false);
    }
  }
}

class _ClassSectionSummary extends StatelessWidget {
  const _ClassSectionSummary({required this.students});

  final List<Student> students;

  @override
  Widget build(BuildContext context) {
    final groups = <String, int>{};
    for (final student in students) {
      groups.update(
        'Class ${student.className}-${student.section}',
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final entries = groups.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SegmentTile(
          label: 'Students',
          value: students.length.toString(),
          icon: Icons.groups_outlined,
        ),
        _SegmentTile(
          label: 'Class sections',
          value: groups.length.toString(),
          icon: Icons.grid_view,
        ),
        ...entries
            .take(6)
            .map(
              (entry) => _SegmentTile(
                label: entry.key,
                value: entry.value.toString(),
                icon: Icons.class_outlined,
              ),
            ),
      ],
    );
  }
}

class _SegmentTile extends StatelessWidget {
  const _SegmentTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0F766E)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: values
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (next) => onChanged(next ?? value),
      ),
    );
  }
}

class _StudentFormData {
  const _StudentFormData({
    required this.admissionNo,
    required this.studentName,
    required this.className,
    required this.section,
    required this.category,
    required this.studentPhone,
    required this.guardianName,
    required this.guardianPhone,
    required this.guardianEmail,
    required this.guardianAddress,
  });

  final String admissionNo;
  final String studentName;
  final String className;
  final String section;
  final String category;
  final String studentPhone;
  final String guardianName;
  final String guardianPhone;
  final String guardianEmail;
  final String guardianAddress;
}

class _AddStudentDialog extends StatefulWidget {
  const _AddStudentDialog({required this.saving, required this.onSubmit});

  final bool saving;
  final Future<bool> Function(_StudentFormData data) onSubmit;

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final admissionController = TextEditingController();
  final studentNameController = TextEditingController();
  final classController = TextEditingController(text: '7');
  final sectionController = TextEditingController(text: 'A');
  final categoryController = TextEditingController(text: 'General');
  final studentPhoneController = TextEditingController();
  final guardianNameController = TextEditingController();
  final guardianPhoneController = TextEditingController();
  final guardianEmailController = TextEditingController();
  final guardianAddressController = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    admissionController.dispose();
    studentNameController.dispose();
    classController.dispose();
    sectionController.dispose();
    categoryController.dispose();
    studentPhoneController.dispose();
    guardianNameController.dispose();
    guardianPhoneController.dispose();
    guardianEmailController.dispose();
    guardianAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Student'),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _field(admissionController, 'Admission no.')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(studentNameController, 'Student name'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(classController, 'Class')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(sectionController, 'Section')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(categoryController, 'Category')),
                ],
              ),
              const SizedBox(height: 12),
              _field(studentPhoneController, 'Student phone'),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _field(guardianNameController, 'Guardian name'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(guardianPhoneController, 'Guardian phone'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(guardianEmailController, 'Guardian email'),
              const SizedBox(height: 12),
              _field(guardianAddressController, 'Guardian address'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: saving ? null : _submit,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.person_add_alt_1),
          label: Text(saving ? 'Saving...' : 'Add Student'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _submit() async {
    final required = [
      admissionController.text,
      studentNameController.text,
      classController.text,
      sectionController.text,
      guardianNameController.text,
      guardianPhoneController.text,
    ];
    if (required.any((value) => value.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fill admission, student, class, section, guardian, and phone.',
          ),
        ),
      );
      return;
    }

    setState(() => saving = true);
    final ok = await widget.onSubmit(
      _StudentFormData(
        admissionNo: admissionController.text.trim(),
        studentName: studentNameController.text.trim(),
        className: classController.text.trim(),
        section: sectionController.text.trim().toUpperCase(),
        category: categoryController.text.trim(),
        studentPhone: studentPhoneController.text.trim(),
        guardianName: guardianNameController.text.trim(),
        guardianPhone: guardianPhoneController.text.trim(),
        guardianEmail: guardianEmailController.text.trim(),
        guardianAddress: guardianAddressController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) Navigator.of(context).pop(true);
  }
}
