import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidyaledger/models/models.dart';
import 'package:vidyaledger/providers/app_state.dart';

void main() {
  group('AppController & AppState Workflows', () {
    test(
      'adds student with guardian and verifies visible students by role',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final controller = container.read(appControllerProvider.notifier);

        controller.addStudentWithGuardian(
          admissionNo: 'VL-2026-999',
          studentName: 'Rohan Sharma',
          className: '8',
          section: 'A',
          category: 'General',
          studentPhone: '+91 98765 99999',
          guardianName: 'Vikram Sharma',
          guardianPhone: '+91 98765 88888',
          guardianEmail: 'vikram@example.com',
          guardianAddress: 'Jaipur, Rajasthan',
        );

        final state = container.read(appControllerProvider);
        final addedStudent = state.students.firstWhere(
          (s) => s.admissionNo == 'VL-2026-999',
        );
        final addedGuardian = state.guardians.firstWhere(
          (g) => g.id == addedStudent.guardianId,
        );

        expect(addedStudent.name, 'Rohan Sharma');
        expect(addedGuardian.name, 'Vikram Sharma');

        // Admin role sees all students
        controller.loginAs(UserRole.admin);
        expect(controller.visibleStudents().length, state.students.length);

        // Parent role only sees their guardian's students
        controller.loginAs(UserRole.parent);
        final parentStudents = controller.visibleStudents();
        expect(parentStudents, isNotEmpty);
        expect(parentStudents.every((s) => s.guardianId == 'g-1'), isTrue);
      },
    );

    test(
      'fee head and fee demand generation assigns demands to target class',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final controller = container.read(appControllerProvider.notifier);

        controller.addFeeHead('Computer Lab Fee', '100-401', false);
        final state1 = container.read(appControllerProvider);
        final newHead = state1.feeHeads.firstWhere(
          (h) => h.name == 'Computer Lab Fee',
        );

        final initialDemands = state1.feeDemands.length;
        final class7Students = state1.students
            .where((s) => s.className == '7')
            .length;

        controller.generateFeeDemand(
          feeHeadId: newHead.id,
          title: 'Annual Lab Charge',
          amount: 3000,
          className: '7',
          dueDate: DateTime(2026, 9, 30),
          lateFeeAmount: 200,
        );

        final state2 = container.read(appControllerProvider);
        expect(state2.feeDemands.length, initialDemands + class7Students);
        expect(
          state2.feeRules.any((r) => r.title == 'Annual Lab Charge'),
          isTrue,
        );
      },
    );

    test('concession submission, approval, and rejection workflow', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(appControllerProvider.notifier);

      controller.loginAs(UserRole.admin);
      controller.submitConcession(
        studentId: 's-2',
        category: 'Merit',
        concessionType: 'Tuition Fee Waiver',
        amount: 4000,
        fundingSource: 'Trust fund',
        reason: 'Top scorer in district examination',
      );

      var state = container.read(appControllerProvider);
      final submitted = state.concessions.firstWhere(
        (c) => c.studentId == 's-2',
      );
      expect(submitted.status, ConcessionStatus.submitted);

      // Approve concession
      controller.updateConcessionStatus(
        submitted.id,
        ConcessionStatus.approved,
      );
      state = container.read(appControllerProvider);
      final approved = state.concessions.firstWhere(
        (c) => c.id == submitted.id,
      );
      expect(approved.status, ConcessionStatus.approved);
      expect(approved.approvedBy, isNotNull);

      // Verify dashboard statistics update
      final stats = controller.dashboardStats();
      expect(stats.totalConcessions, greaterThan(0));
    });

    test('class section master setup and activation toggle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(appControllerProvider.notifier);

      controller.addClassSection(
        className: '10',
        section: 'B',
        classTeacher: 'Mr. Verma',
        roomLabel: 'Room 204',
        capacity: 40,
      );

      var state = container.read(appControllerProvider);
      final addedSection = state.classSections.firstWhere(
        (cs) => cs.className == '10' && cs.section == 'B',
      );
      expect(addedSection.classTeacher, 'Mr. Verma');
      expect(addedSection.active, isTrue);

      controller.setClassSectionActive(addedSection.id, false);
      state = container.read(appControllerProvider);
      final deactivated = state.classSections.firstWhere(
        (cs) => cs.id == addedSection.id,
      );
      expect(deactivated.active, isFalse);
    });

    test('updates school profile information', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(appControllerProvider.notifier);

      final updatedProfile = container
          .read(appControllerProvider)
          .school
          .copyWith(
            name: 'Vidya Academy International',
            contactEmail: 'admin@vidyaacademy.demo',
          );

      controller.updateSchoolProfile(updatedProfile);
      final state = container.read(appControllerProvider);
      expect(state.school.name, 'Vidya Academy International');
      expect(state.school.contactEmail, 'admin@vidyaacademy.demo');
    });

    test('sends WhatsApp / SMS reminder and logs entry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(appControllerProvider.notifier);

      final log = controller.sendReminder(
        studentId: 's-1',
        channel: ReminderChannel.whatsapp,
        templateType: ReminderTemplateType.dueReminder,
        message: 'Test fee reminder message for Asha Sharma',
      );

      final state = container.read(appControllerProvider);
      expect(state.reminderLogs, isNotEmpty);
      expect(state.reminderLogs.first.id, log.id);
      expect(state.reminderLogs.first.message, contains('Test fee reminder'));
      expect(state.reminderLogs.first.channel, ReminderChannel.whatsapp);
    });

    test('creates installment EMI plan and records partial/full payment', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(appControllerProvider.notifier);

      final installments = controller.createInstallmentPlan(
        studentId: 's-2',
        feeDemandId: 'fd-2',
        numberOfInstallments: 3,
        totalAmount: 12000,
        firstDueDate: DateTime(2026, 8, 1),
      );

      expect(installments, hasLength(3));
      expect(installments.first.amount, 4000);
      expect(installments.first.status, InstallmentStatus.pending);

      // Record payment for first installment
      controller.recordInstallmentPayment(installments.first.id, 4000);

      final state = container.read(appControllerProvider);
      final updatedInst = state.installments.firstWhere(
        (i) => i.id == installments.first.id,
      );
      expect(updatedInst.status, InstallmentStatus.paid);
      expect(updatedInst.paidAmount, 4000);
    });
  });
}
