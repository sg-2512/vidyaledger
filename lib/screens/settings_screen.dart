import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/supabase_providers.dart';
import '../widgets/common.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final nameController = TextEditingController();
  final boardController = TextEditingController();
  final typeController = TextEditingController();
  final academicYearController = TextEditingController();
  final districtController = TextEditingController();
  final stateController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final logoController = TextEditingController();

  final classController = TextEditingController();
  final sectionController = TextEditingController();
  final teacherController = TextEditingController();
  final roomController = TextEditingController();
  final capacityController = TextEditingController(text: '45');

  bool seededControllers = false;
  bool savingProfile = false;
  bool savingClassSection = false;
  String? togglingSectionId;

  @override
  void dispose() {
    nameController.dispose();
    boardController.dispose();
    typeController.dispose();
    academicYearController.dispose();
    districtController.dispose();
    stateController.dispose();
    addressController.dispose();
    emailController.dispose();
    phoneController.dispose();
    logoController.dispose();
    classController.dispose();
    sectionController.dispose();
    teacherController.dispose();
    roomController.dispose();
    capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    _seedControllers(state.school);
    final activeSections = state.classSections.where((item) => item.active);
    final capacity = activeSections.fold<int>(
      0,
      (sum, item) => sum + item.capacity,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'School Settings',
          subtitle:
              'Tenant profile, academic year, class-section master, and operational capacity.',
          trailing: FilledButton.icon(
            onPressed: savingProfile ? null : _saveSchoolProfile,
            icon: savingProfile
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(savingProfile ? 'Saving...' : 'Save Profile'),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricTile(
              label: 'Active sections',
              value: activeSections.length.toString(),
              icon: Icons.grid_view,
            ),
            _MetricTile(
              label: 'Student capacity',
              value: capacity.toString(),
              icon: Icons.event_seat_outlined,
            ),
            _MetricTile(
              label: 'Enrolled students',
              value: state.students.length.toString(),
              icon: Icons.groups_outlined,
            ),
            _MetricTile(
              label: 'Academic year',
              value: state.school.academicYear,
              icon: Icons.calendar_month_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'School Profile',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final twoColumn = constraints.maxWidth > 760;
              final fieldWidth = twoColumn
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _field(nameController, 'School name', fieldWidth),
                  _field(boardController, 'Board', fieldWidth),
                  _field(typeController, 'School type', fieldWidth),
                  _field(academicYearController, 'Academic year', fieldWidth),
                  _field(districtController, 'District', fieldWidth),
                  _field(stateController, 'State', fieldWidth),
                  _field(emailController, 'Contact email', fieldWidth),
                  _field(phoneController, 'Contact phone', fieldWidth),
                  _field(addressController, 'Address', constraints.maxWidth),
                  _field(logoController, 'Logo URL', constraints.maxWidth),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Class & Section Master',
          trailing: FilledButton.icon(
            onPressed: savingClassSection ? null : _addClassSection,
            icon: savingClassSection
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add),
            label: Text(savingClassSection ? 'Saving...' : 'Add Section'),
          ),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final compact = width < 760;
                  final smallWidth = compact ? width : 130.0;
                  final mediumWidth = compact ? width : 190.0;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _field(classController, 'Class', smallWidth),
                      _field(sectionController, 'Section', smallWidth),
                      _field(teacherController, 'Class teacher', mediumWidth),
                      _field(roomController, 'Room', mediumWidth),
                      _field(
                        capacityController,
                        'Capacity',
                        smallWidth,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              _ClassSectionTable(
                classSections: state.classSections,
                students: state.students,
                togglingSectionId: togglingSectionId,
                onToggle: _setClassSectionActive,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _seedControllers(SchoolProfile school) {
    if (seededControllers) return;
    seededControllers = true;
    nameController.text = school.name;
    boardController.text = school.board;
    typeController.text = school.schoolType;
    academicYearController.text = school.academicYear;
    districtController.text = school.district;
    stateController.text = school.state;
    addressController.text = school.address;
    emailController.text = school.contactEmail;
    phoneController.text = school.contactPhone;
    logoController.text = school.logoUrl;
  }

  Widget _field(
    TextEditingController controller,
    String label,
    double width, {
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Future<void> _saveSchoolProfile() async {
    final current = ref.read(appControllerProvider).school;
    final required = [
      nameController.text,
      boardController.text,
      typeController.text,
      academicYearController.text,
      districtController.text,
      stateController.text,
    ];
    if (required.any((value) => value.trim().isEmpty)) {
      _showMessage(
        'Fill school name, board, type, academic year, district, and state.',
      );
      return;
    }

    final nextSchool = current.copyWith(
      name: nameController.text.trim(),
      board: boardController.text.trim(),
      schoolType: typeController.text.trim(),
      academicYear: academicYearController.text.trim(),
      district: districtController.text.trim(),
      state: stateController.text.trim(),
      address: addressController.text.trim(),
      contactEmail: emailController.text.trim(),
      contactPhone: phoneController.text.trim(),
      logoUrl: logoController.text.trim(),
    );

    setState(() => savingProfile = true);
    try {
      final service = ref.read(supabaseFinanceServiceProvider);
      if (service == null) {
        ref
            .read(appControllerProvider.notifier)
            .updateSchoolProfile(nextSchool);
      } else {
        await service.updateSchoolProfile(nextSchool);
        await refreshAppStateFromSupabase(
          ref,
          currentUser: ref.read(appControllerProvider).currentUser,
        );
      }
      _showMessage('School profile saved.');
    } catch (error) {
      _showMessage('School profile save failed: $error');
    } finally {
      if (mounted) setState(() => savingProfile = false);
    }
  }

  Future<void> _addClassSection() async {
    final capacity = int.tryParse(capacityController.text.trim()) ?? 0;
    final required = [
      classController.text,
      sectionController.text,
      teacherController.text,
      roomController.text,
    ];
    if (required.any((value) => value.trim().isEmpty) || capacity <= 0) {
      _showMessage('Fill class, section, teacher, room, and capacity.');
      return;
    }

    setState(() => savingClassSection = true);
    try {
      final service = ref.read(supabaseFinanceServiceProvider);
      if (service == null) {
        ref
            .read(appControllerProvider.notifier)
            .addClassSection(
              className: classController.text,
              section: sectionController.text,
              classTeacher: teacherController.text.trim(),
              roomLabel: roomController.text.trim(),
              capacity: capacity,
            );
      } else {
        await service.addClassSection(
          className: classController.text,
          section: sectionController.text,
          classTeacher: teacherController.text,
          roomLabel: roomController.text,
          capacity: capacity,
        );
        await refreshAppStateFromSupabase(
          ref,
          currentUser: ref.read(appControllerProvider).currentUser,
        );
      }
      classController.clear();
      sectionController.clear();
      teacherController.clear();
      roomController.clear();
      capacityController.text = '45';
      _showMessage('Class section saved.');
    } catch (error) {
      _showMessage('Class section save failed: $error');
    } finally {
      if (mounted) setState(() => savingClassSection = false);
    }
  }

  Future<void> _setClassSectionActive(
    String classSectionId,
    bool active,
  ) async {
    setState(() => togglingSectionId = classSectionId);
    try {
      final service = ref.read(supabaseFinanceServiceProvider);
      if (service == null) {
        ref
            .read(appControllerProvider.notifier)
            .setClassSectionActive(classSectionId, active);
      } else {
        await service.setClassSectionActive(classSectionId, active);
        await refreshAppStateFromSupabase(
          ref,
          currentUser: ref.read(appControllerProvider).currentUser,
        );
      }
      _showMessage(
        active ? 'Class section activated.' : 'Class section archived.',
      );
    } catch (error) {
      _showMessage('Class section update failed: $error');
    } finally {
      if (mounted) setState(() => togglingSectionId = null);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
      width: 196,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _ClassSectionTable extends StatelessWidget {
  const _ClassSectionTable({
    required this.classSections,
    required this.students,
    required this.togglingSectionId,
    required this.onToggle,
  });

  final List<ClassSection> classSections;
  final List<Student> students;
  final String? togglingSectionId;
  final Future<void> Function(String classSectionId, bool active) onToggle;

  @override
  Widget build(BuildContext context) {
    final rows = [...classSections]..sort((a, b) => a.label.compareTo(b.label));
    if (rows.isEmpty) {
      return const EmptyState(message: 'No class sections configured yet.');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Class-Section')),
          DataColumn(label: Text('Teacher')),
          DataColumn(label: Text('Room')),
          DataColumn(label: Text('Students')),
          DataColumn(label: Text('Capacity')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Action')),
        ],
        rows: rows.map((item) {
          final studentCount = students
              .where(
                (student) =>
                    student.className == item.className &&
                    student.section == item.section,
              )
              .length;
          final isBusy = togglingSectionId == item.id;
          return DataRow(
            cells: [
              DataCell(Text(item.label)),
              DataCell(
                Text(item.classTeacher.isEmpty ? '-' : item.classTeacher),
              ),
              DataCell(Text(item.roomLabel.isEmpty ? '-' : item.roomLabel)),
              DataCell(Text(studentCount.toString())),
              DataCell(Text(item.capacity.toString())),
              DataCell(
                StatusPill(
                  label: item.active ? 'Active' : 'Archived',
                  color: statusColor(item.active ? 'active' : 'archived'),
                ),
              ),
              DataCell(
                TextButton.icon(
                  onPressed: isBusy
                      ? null
                      : () => onToggle(item.id, !item.active),
                  icon: isBusy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          item.active
                              ? Icons.archive_outlined
                              : Icons.unarchive_outlined,
                        ),
                  label: Text(item.active ? 'Archive' : 'Activate'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
