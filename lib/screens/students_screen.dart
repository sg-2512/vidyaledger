import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/finance_providers.dart';
import '../providers/supabase_providers.dart';
import '../services/report_service.dart';
import '../utils/csv_utils.dart';
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
  bool importingStudents = false;

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
                OutlinedButton.icon(
                  onPressed: importingStudents || addingStudent
                      ? null
                      : _openStudentImportDialog,
                  icon: importingStudents
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(
                    importingStudents ? 'Importing...' : 'Import CSV',
                  ),
                ),
              if (canManageStudents)
                FilledButton.icon(
                  onPressed: addingStudent || importingStudents
                      ? null
                      : _openAddStudentDialog,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add Student'),
                ),
            ],
          ),
        ),
        _ClassSectionSummary(
          students: students,
          classSections: state.classSections,
        ),
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: summary.pending > 0
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          summary.pending > 0
                              ? moneyFormat.format(summary.pending)
                              : 'Paid',
                          style: TextStyle(
                            color: summary.pending > 0
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF065F46),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
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
        ),
      ],
    );
  }

  List<String> _options(Iterable<String> values) {
    final sorted = values
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();

    sorted.sort((a, b) {
      final aNum = int.tryParse(a);
      final bNum = int.tryParse(b);
      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      }
      return a.compareTo(b);
    });

    return ['All', ...sorted];
  }

  Guardian? _guardianFor(AppState state, String guardianId) {
    for (final guardian in state.guardians) {
      if (guardian.id == guardianId) return guardian;
    }
    return null;
  }

  Future<void> _openAddStudentDialog() async {
    final classSections =
        ref
            .read(appControllerProvider)
            .classSections
            .where((item) => item.active)
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label));
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => _AddStudentDialog(
        saving: addingStudent,
        classSections: classSections,
        onSubmit: _addStudent,
      ),
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

  Future<void> _openStudentImportDialog() async {
    final existingAdmissions = ref
        .read(appControllerProvider)
        .students
        .map((student) => student.admissionNo.toLowerCase())
        .toSet();
    final importRows = await showDialog<List<_StudentFormData>>(
      context: context,
      builder: (context) =>
          _StudentImportDialog(existingAdmissionNos: existingAdmissions),
    );
    if (importRows == null || importRows.isEmpty) return;

    setState(() => importingStudents = true);
    try {
      final service = ref.read(supabaseFinanceServiceProvider);
      if (service == null) {
        final controller = ref.read(appControllerProvider.notifier);
        for (final row in importRows) {
          controller.addStudentWithGuardian(
            admissionNo: row.admissionNo,
            studentName: row.studentName,
            className: row.className,
            section: row.section,
            category: row.category,
            studentPhone: row.studentPhone,
            guardianName: row.guardianName,
            guardianPhone: row.guardianPhone,
            guardianEmail: row.guardianEmail,
            guardianAddress: row.guardianAddress,
          );
        }
      } else {
        for (final row in importRows) {
          await service.addStudentWithGuardian(
            admissionNo: row.admissionNo,
            studentName: row.studentName,
            className: row.className,
            section: row.section,
            category: row.category,
            studentPhone: row.studentPhone,
            guardianName: row.guardianName,
            guardianPhone: row.guardianPhone,
            guardianEmail: row.guardianEmail,
            guardianAddress: row.guardianAddress,
          );
        }
        await refreshAppStateFromSupabase(
          ref,
          currentUser: ref.read(appControllerProvider).currentUser,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${importRows.length} students.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Student import failed: $error')));
    } finally {
      if (mounted) setState(() => importingStudents = false);
    }
  }
}

class _ClassSectionSummary extends StatelessWidget {
  const _ClassSectionSummary({
    required this.students,
    required this.classSections,
  });

  final List<Student> students;
  final List<ClassSection> classSections;

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
    final activeSections = classSections.where((item) => item.active).toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    final totalCapacity = activeSections.fold<int>(
      0,
      (sum, item) => sum + item.capacity,
    );

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
          value: activeSections.length.toString(),
          icon: Icons.grid_view,
        ),
        _SegmentTile(
          label: 'Capacity',
          value: totalCapacity.toString(),
          icon: Icons.event_seat_outlined,
        ),
        ...activeSections
            .take(6)
            .map(
              (section) => _SegmentTile(
                label: section.label,
                value: '${groups[section.label] ?? 0}/${section.capacity}',
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

class _StudentImportDraft {
  const _StudentImportDraft({
    required this.rowNumber,
    required this.errors,
    this.data,
  });

  final int rowNumber;
  final List<String> errors;
  final _StudentFormData? data;

  bool get isValid => data != null && errors.isEmpty;
}

class _StudentImportDialog extends StatefulWidget {
  const _StudentImportDialog({required this.existingAdmissionNos});

  final Set<String> existingAdmissionNos;

  @override
  State<_StudentImportDialog> createState() => _StudentImportDialogState();
}

class _StudentImportDialogState extends State<_StudentImportDialog> {
  final csvController = TextEditingController(text: _studentCsvSample);

  @override
  void dispose() {
    csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drafts = _parseStudentCsvDrafts(
      csvController.text,
      widget.existingAdmissionNos,
    );
    final validRows = drafts.where((draft) => draft.isValid).toList();
    final invalidRows = drafts.where((draft) => !draft.isValid).toList();

    return AlertDialog(
      title: const Text('Import Students from CSV'),
      content: SizedBox(
        width: 760,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: csvController,
                  minLines: 8,
                  maxLines: 12,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    labelText: 'CSV rows',
                    hintText:
                        'admission_no,student_name,class,section,guardian_name,guardian_phone',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(
                      label: '${validRows.length} ready',
                      color: const Color(0xFF0F766E),
                    ),
                    StatusPill(
                      label: '${invalidRows.length} needs fix',
                      color: invalidRows.isEmpty
                          ? const Color(0xFF0F766E)
                          : const Color(0xFFB45309),
                    ),
                  ],
                ),
                if (invalidRows.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...invalidRows
                      .take(5)
                      .map(
                        (draft) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Row ${draft.rowNumber}: ${draft.errors.join(', ')}',
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                ],
                if (validRows.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Preview',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  ...validRows.take(4).map((draft) {
                    final data = draft.data!;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE0F2F1),
                        child: Icon(
                          Icons.person_outline,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      title: Text('${data.studentName} (${data.admissionNo})'),
                      subtitle: Text(
                        'Class ${data.className}-${data.section} | ${data.guardianName}',
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: validRows.isEmpty
              ? null
              : () => Navigator.of(
                  context,
                ).pop(validRows.map((row) => row.data!).toList()),
          icon: const Icon(Icons.upload_file_outlined),
          label: Text('Import ${validRows.length}'),
        ),
      ],
    );
  }
}

const _studentCsvSample =
    'admission_no,student_name,class,section,category,student_phone,guardian_name,guardian_phone,guardian_email,guardian_address\n'
    'NEW-2026-001,Aarav Mehta,7,A,General,9876500101,Ritika Mehta,9876500100,parent1@example.com,Indore\n'
    'NEW-2026-002,Diya Shah,8,B,RTE,,Kunal Shah,9876500200,parent2@example.com,Bhopal';

List<_StudentImportDraft> _parseStudentCsvDrafts(
  String csv,
  Set<String> existingAdmissionNos,
) {
  final records = parseCsvRecords(csv);
  final seenAdmissionNos = <String>{};
  final drafts = <_StudentImportDraft>[];

  for (final record in records) {
    final admissionNo = record.firstValue(const [
      'admission_no',
      'admissionNo',
      'admission',
      'admission_number',
    ]);
    final studentName = record.firstValue(const [
      'student_name',
      'studentName',
      'student',
      'name',
    ]);
    final className = record.firstValue(const [
      'class',
      'class_name',
      'className',
      'grade',
    ]);
    final section = record.firstValue(const ['section', 'sec']);
    final category = record.firstValue(const ['category', 'quota']).isEmpty
        ? 'General'
        : record.firstValue(const ['category', 'quota']);
    final studentPhone = record.firstValue(const [
      'student_phone',
      'studentPhone',
      'phone',
    ]);
    final guardianName = record.firstValue(const [
      'guardian_name',
      'guardianName',
      'parent_name',
      'parentName',
    ]);
    final guardianPhone = record.firstValue(const [
      'guardian_phone',
      'guardianPhone',
      'parent_phone',
      'parentPhone',
      'mobile',
    ]);
    final guardianEmail = record.firstValue(const [
      'guardian_email',
      'guardianEmail',
      'parent_email',
      'parentEmail',
      'email',
    ]);
    final guardianAddress = record.firstValue(const [
      'guardian_address',
      'guardianAddress',
      'address',
    ]);

    final errors = <String>[];
    void requireValue(String value, String label) {
      if (value.trim().isEmpty) errors.add('$label missing');
    }

    requireValue(admissionNo, 'admission no.');
    requireValue(studentName, 'student name');
    requireValue(className, 'class');
    requireValue(section, 'section');
    requireValue(guardianName, 'guardian name');
    requireValue(guardianPhone, 'guardian phone');

    final normalizedAdmission = admissionNo.toLowerCase();
    if (normalizedAdmission.isNotEmpty) {
      if (existingAdmissionNos.contains(normalizedAdmission)) {
        errors.add('admission already exists');
      }
      if (!seenAdmissionNos.add(normalizedAdmission)) {
        errors.add('duplicate admission in CSV');
      }
    }

    drafts.add(
      _StudentImportDraft(
        rowNumber: record.rowNumber,
        errors: errors,
        data: errors.isEmpty
            ? _StudentFormData(
                admissionNo: admissionNo,
                studentName: studentName,
                className: className,
                section: section.toUpperCase(),
                category: category,
                studentPhone: studentPhone,
                guardianName: guardianName,
                guardianPhone: guardianPhone,
                guardianEmail: guardianEmail,
                guardianAddress: guardianAddress,
              )
            : null,
      ),
    );
  }

  return drafts;
}

class _AddStudentDialog extends StatefulWidget {
  const _AddStudentDialog({
    required this.saving,
    required this.classSections,
    required this.onSubmit,
  });

  final bool saving;
  final List<ClassSection> classSections;
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
  String? selectedClassSectionId;

  @override
  void initState() {
    super.initState();
    if (widget.classSections.isNotEmpty) {
      selectedClassSectionId = widget.classSections.first.id;
      _applyClassSection(widget.classSections.first);
    }
  }

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
              if (widget.classSections.isEmpty)
                Row(
                  children: [
                    Expanded(child: _field(classController, 'Class')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(sectionController, 'Section')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(categoryController, 'Category')),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedClassSectionId,
                        decoration: const InputDecoration(
                          labelText: 'Class-section',
                        ),
                        items: widget.classSections
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final selected = widget.classSections.firstWhere(
                            (item) => item.id == value,
                          );
                          setState(() {
                            selectedClassSectionId = selected.id;
                            _applyClassSection(selected);
                          });
                        },
                      ),
                    ),
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

  void _applyClassSection(ClassSection classSection) {
    classController.text = classSection.className;
    sectionController.text = classSection.section;
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
