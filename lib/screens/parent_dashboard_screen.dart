import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart' show GoRouterHelper;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/finance_providers.dart';
import '../providers/supabase_providers.dart';
import '../services/report_service.dart';
import '../widgets/common.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _StudentInfoHeader extends StatelessWidget {
  const _StudentInfoHeader({
    required this.student,
    required this.school,
  });

  final Student student;
  final SchoolProfile school;

  @override
  Widget build(BuildContext context) {
    final String initials = _getInitials(student.name);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF0F766E),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Admission No: ${student.admissionNo}',
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Class: ${student.classLabel}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Academic Session: ${school.academicYear}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final List<String> parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts[0].length >= 2) {
      return '${parts[0][0]}${parts[0][1]}'.toUpperCase();
    } else {
      return parts[0][0].toUpperCase();
    }
  }
}
class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  final concessionAmountController = TextEditingController(text: '3000');
  final concessionReasonController = TextEditingController();
  final upiRefController = TextEditingController();
  final paymentAmountController = TextEditingController();

  String concessionCategory = 'EWS';
  bool submittingWaiver = false;
  bool processingPayment = false;

  @override
  void dispose() {
    concessionAmountController.dispose();
    concessionReasonController.dispose();
    upiRefController.dispose();
    paymentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final linkedStudents = _linkedStudentsForParent(state);
    final student = _selectedStudent(state, linkedStudents);

    if (student == null) {
      return const EmptyState(
        message: 'No linked student profile is available for this parent.',
      );
    }

    final summary = ref.watch(financeSummaryProvider(student.id));
    final demands =
        state.feeDemands
            .where((demand) => demand.studentId == student.id)
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final concessions =
        state.concessions
            .where((concession) => concession.studentId == student.id)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final payments =
        state.payments
            .where((payment) => payment.studentId == student.id)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1080;
        final topPanels = [
          _QuickLinksPanel(
            onStudentProfile: () => context.go('/students/${student.id}'),
            onPayFees: () =>
                _openPaymentDialog(context, student, summary.pending),
            onRequestWaiver: () => _openWaiverDialog(context, student),
            onLatestReceipt: () => _shareLatestReceipt(
              context: context,
              student: student,
              summary: summary,
              payments: payments,
              school: state.school,
            ),
          ),
          _FinanceOverviewPanel(summary: summary),
          _DueDatesPanel(demands: demands),
        ];

        final middlePanels = [
          _FeeDuesPanel(summary: summary),
          _StudentActivityPanel(
            demands: demands,
            concessions: concessions,
            payments: payments,
            summary: summary,
          ),
        ];

        final lowerPanels = [
          _ConcessionStatusPanel(concessions: concessions),
          _ReceiptPanel(
            payments: payments,
            student: student,
            summary: summary,
            school: state.school,
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StudentInfoHeader(student: student, school: state.school),
            const SizedBox(height: 16),
            _PanelRow(wide: wide, children: topPanels),
            const SizedBox(height: 14),
            _PanelRow(wide: wide, flexes: const [3, 5], children: middlePanels),
            const SizedBox(height: 14),
            _PanelRow(wide: wide, flexes: const [3, 5], children: lowerPanels),
            const SizedBox(height: 14),
            _DashboardPanel(
              title: 'Fee Ledger Timeline',
              trailing: _PanelBadge(label: '${payments.length} payments'),
              child: _FeeTimeline(
                demands: demands,
                concessions: concessions,
                payments: payments,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareLatestReceipt({
    required BuildContext context,
    required Student student,
    required StudentFinanceSummary summary,
    required List<Payment> payments,
    required SchoolProfile school,
  }) async {
    final completedPayments =
        payments
            .where((payment) => payment.status == PaymentStatus.completed)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    if (completedPayments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No completed receipt is available yet.')),
      );
      return;
    }

    final payment = completedPayments.first;
    final bytes = await ReportService.buildReceiptPdf(
      payment: payment,
      student: student,
      summary: summary,
      school: school,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${payment.receiptNo.replaceAll('/', '-')}.pdf',
    );
  }

  void _openPaymentDialog(
    BuildContext context,
    Student student,
    double pendingAmount,
  ) {
    if (pendingAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No outstanding balance to pay.')),
      );
      return;
    }
    paymentAmountController.text = pendingAmount.toStringAsFixed(0);
    upiRefController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pay Outstanding Fees'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Scan the UPI QR code to simulate the transaction',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 100,
                            color: const Color(
                              0xFF0F766E,
                            ).withValues(alpha: 0.85),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'VIDYALEDGER@UPI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: paymentAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (Rs)',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: upiRefController,
                    decoration: const InputDecoration(
                      labelText: 'UPI Transaction Reference Number',
                      hintText: 'e.g. UPI8832049281',
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: processingPayment
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: processingPayment
                  ? null
                  : () async {
                      final amount =
                          double.tryParse(paymentAmountController.text) ?? 0;
                      final refNo = upiRefController.text.trim();
                      if (amount <= 0 || refNo.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a valid amount and transaction reference.',
                            ),
                          ),
                        );
                        return;
                      }
                      setDialogState(() => processingPayment = true);
                      try {
                        final service = ref.read(
                          supabaseFinanceServiceProvider,
                        );
                        if (service == null) {
                          ref
                              .read(appControllerProvider.notifier)
                              .recordPayment(
                                studentId: student.id,
                                amount: amount,
                                mode: PaymentMode.upi,
                                referenceNo: refNo,
                                note: 'Self-paid online via Parent Portal',
                              );
                        } else {
                          await service.recordPayment(
                            studentId: student.id,
                            amount: amount,
                            mode: PaymentMode.upi,
                            referenceNo: refNo,
                            note: 'Self-paid online via Parent Portal',
                          );
                          await refreshAppStateFromSupabase(
                            ref,
                            currentUser: ref
                                .read(appControllerProvider)
                                .currentUser,
                          );
                        }
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'UPI payment completed successfully.',
                            ),
                          ),
                        );
                      } catch (err) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Payment failed: $err')),
                        );
                      } finally {
                        setDialogState(() => processingPayment = false);
                      }
                    },
              icon: processingPayment
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(
                processingPayment ? 'Confirming...' : 'Submit Payment',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openWaiverDialog(BuildContext context, Student student) {
    concessionReasonController.clear();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Request Exemption / Concession'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: concessionCategory,
                  decoration: const InputDecoration(
                    labelText: 'Exemption Category',
                  ),
                  items:
                      [
                        'EWS',
                        'RTE',
                        'SC',
                        'ST',
                        'Minority',
                        'Girl Child',
                        'Sibling',
                      ].map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                  onChanged: (val) => setDialogState(
                    () => concessionCategory = val ?? concessionCategory,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: concessionAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Requested Concession Amount (Rs)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: concessionReasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason & Support note',
                    hintText:
                        'Describe necessity or certificate number details...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submittingWaiver
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: submittingWaiver
                  ? null
                  : () async {
                      final amount =
                          double.tryParse(concessionAmountController.text) ?? 0;
                      final reason = concessionReasonController.text.trim();
                      if (amount <= 0 || reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please specify a valid amount and reasoning note.',
                            ),
                          ),
                        );
                        return;
                      }
                      setDialogState(() => submittingWaiver = true);
                      try {
                        final service = ref.read(
                          supabaseFinanceServiceProvider,
                        );
                        if (service == null) {
                          ref
                              .read(appControllerProvider.notifier)
                              .submitConcession(
                                studentId: student.id,
                                category: concessionCategory,
                                concessionType: '$concessionCategory support',
                                amount: amount,
                                fundingSource: 'School waiver',
                                reason: reason,
                              );
                        } else {
                          await service.submitConcession(
                            studentId: student.id,
                            category: concessionCategory,
                            concessionType: '$concessionCategory support',
                            amount: amount,
                            fundingSource: 'School waiver',
                            reason: reason,
                          );
                          await refreshAppStateFromSupabase(
                            ref,
                            currentUser: ref
                                .read(appControllerProvider)
                                .currentUser,
                          );
                        }
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Waiver request submitted for approval.',
                            ),
                          ),
                        );
                      } catch (err) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Submission failed: $err')),
                        );
                      } finally {
                        setDialogState(() => submittingWaiver = false);
                      }
                    },
              icon: submittingWaiver
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                submittingWaiver ? 'Submitting...' : 'Submit Request',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelRow extends StatelessWidget {
  const _PanelRow({required this.children, required this.wide, this.flexes});

  final List<Widget> children;
  final bool wide;
  final List<int>? flexes;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(flex: flexes?[i] ?? 1, child: children[i]),
        ],
      ],
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _QuickLinksPanel extends StatelessWidget {
  const _QuickLinksPanel({
    required this.onStudentProfile,
    required this.onPayFees,
    required this.onRequestWaiver,
    required this.onLatestReceipt,
  });

  final VoidCallback onStudentProfile;
  final VoidCallback onPayFees;
  final VoidCallback onRequestWaiver;
  final VoidCallback onLatestReceipt;

  @override
  Widget build(BuildContext context) {
    final links = [
      _QuickLinkItem(
        icon: Icons.badge_outlined,
        label: 'Student Profile',
        onTap: onStudentProfile,
      ),
      _QuickLinkItem(
        icon: Icons.payment,
        label: 'Fee Payment',
        onTap: onPayFees,
      ),
      _QuickLinkItem(
        icon: Icons.verified_user_outlined,
        label: 'Request Waiver',
        onTap: onRequestWaiver,
      ),
      _QuickLinkItem(
        icon: Icons.receipt_long_outlined,
        label: 'Latest Receipt',
        onTap: onLatestReceipt,
      ),
    ];

    return _DashboardPanel(
      title: 'Quick Links',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 360 ? 2 : 1;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 4.6 : 3.1,
            children: links
                .map((item) => _QuickLinkButton(item: item))
                .toList(),
          );
        },
      ),
    );
  }
}

class _QuickLinkButton extends StatelessWidget {
  const _QuickLinkButton({required this.item});

  final _QuickLinkItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0F2F7),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(item.icon, color: const Color(0xFF304866), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF304866),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLinkItem {
  const _QuickLinkItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _FinanceOverviewPanel extends StatelessWidget {
  const _FinanceOverviewPanel({required this.summary});

  final StudentFinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final settled = summary.paid + summary.approvedConcessions;
    final progress = summary.totalDemand == 0
        ? 0.0
        : (settled / summary.totalDemand).clamp(0.0, 1.0);

    return _DashboardPanel(
      title: 'Finance Status',
      trailing: const _PanelBadge(label: '2026-27'),
      child: Row(
        children: [
          SizedBox(
            width: 114,
            height: 114,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  backgroundColor: const Color(0xFFE8EDF2),
                  color: const Color(0xFF16ADC2),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Settled',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Wrap(
              spacing: 24,
              runSpacing: 18,
              children: [
                _MiniMetric(
                  value: moneyFormat.format(summary.totalDemand),
                  label: 'Demand',
                ),
                _MiniMetric(
                  value: moneyFormat.format(summary.paid),
                  label: 'Paid',
                ),
                _MiniMetric(
                  value: moneyFormat.format(summary.approvedConcessions),
                  label: 'Concession',
                ),
                _MiniMetric(
                  value: moneyFormat.format(summary.pending),
                  label: 'Balance',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DueDatesPanel extends StatelessWidget {
  const _DueDatesPanel({required this.demands});

  final List<FeeDemand> demands;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final visibleDemands = demands.take(3).toList();

    return _DashboardPanel(
      title: 'Due Dates',
      trailing: const _PanelBadge(label: 'Fees'),
      child: visibleDemands.isEmpty
          ? const EmptyState(message: 'No due dates found.')
          : Column(
              children: visibleDemands.map((demand) {
                final days = demand.dueDate.difference(now).inDays;
                final overdue = days < 0;
                final label = overdue
                    ? '${days.abs()} days overdue'
                    : days == 0
                    ? 'Due today'
                    : 'Due in $days days';
                final color = overdue
                    ? const Color(0xFFB45309)
                    : const Color(0xFF0F766E);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_month_outlined,
                          color: color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              moneyFormat.format(demand.amount),
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              DateFormat('MMM d, yyyy').format(demand.dueDate),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _FeeDuesPanel extends StatelessWidget {
  const _FeeDuesPanel({required this.summary});

  final StudentFinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final paidProgress = summary.totalDemand == 0
        ? 0.0
        : (summary.paid / summary.totalDemand).clamp(0.0, 1.0);

    return _DashboardPanel(
      title: 'Fee Dues',
      trailing: const _PanelBadge(label: '2026-2027'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MoneyLegend(
                  color: const Color(0xFFF2C027),
                  value: moneyFormat.format(summary.totalDemand),
                  label: 'Annual Due',
                ),
                const SizedBox(height: 14),
                _MoneyLegend(
                  color: const Color(0xFF2BB99A),
                  value: moneyFormat.format(summary.paid),
                  label: 'Fees Paid',
                ),
                const SizedBox(height: 26),
                Text(
                  'Due as on date ${moneyFormat.format(summary.pending)}',
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 112,
            height: 112,
            child: CircularProgressIndicator(
              value: paidProgress,
              strokeWidth: 7,
              backgroundColor: const Color(0xFFF2C027),
              color: const Color(0xFF2BB99A),
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentActivityPanel extends StatelessWidget {
  const _StudentActivityPanel({
    required this.demands,
    required this.concessions,
    required this.payments,
    required this.summary,
  });

  final List<FeeDemand> demands;
  final List<Concession> concessions;
  final List<Payment> payments;
  final StudentFinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final completedPayments = payments
        .where((payment) => payment.status == PaymentStatus.completed)
        .toList();
    final approvedConcessions = concessions
        .where((concession) => concession.status == ConcessionStatus.approved)
        .toList();

    final rows = [
      _ActivityMetric(
        label: 'Fee demands',
        count: '${demands.length}',
        amount: summary.totalDemand,
        status: demands.isEmpty ? 'No demand' : 'Open',
      ),
      _ActivityMetric(
        label: 'Payments completed',
        count: '${completedPayments.length}',
        amount: summary.paid,
        status: completedPayments.isEmpty ? 'Pending' : 'Completed',
      ),
      _ActivityMetric(
        label: 'Concessions approved',
        count: '${approvedConcessions.length}',
        amount: summary.approvedConcessions,
        status: approvedConcessions.isEmpty ? 'None' : 'Approved',
      ),
      _ActivityMetric(
        label: 'Outstanding balance',
        count: summary.overdueDays > 0 ? '${summary.overdueDays}d' : '-',
        amount: summary.pending,
        status: summary.pending > 0 ? 'Pending' : 'Settled',
      ),
    ];

    return _DashboardPanel(
      title: 'Student Activity',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF1F5F9),
                ),
                border: TableBorder.all(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                columns: const [
                  DataColumn(label: Text('Activity')),
                  DataColumn(label: Text('Count')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Status')),
                ],
                rows: rows.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(Text(row.label)),
                      DataCell(Text(row.count)),
                      DataCell(Text(moneyFormat.format(row.amount))),
                      DataCell(
                        StatusPill(
                          label: row.status,
                          color: statusColor(row.status),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConcessionStatusPanel extends StatelessWidget {
  const _ConcessionStatusPanel({required this.concessions});

  final List<Concession> concessions;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Concession Requests',
      child: concessions.isEmpty
          ? const EmptyState(message: 'No concession requests submitted yet.')
          : Column(
              children: concessions.map((concession) {
                return _CompactListRow(
                  icon: Icons.verified_user_outlined,
                  title: concession.concessionType,
                  subtitle:
                      '${moneyFormat.format(concession.amount)} | ${DateFormat.yMMMd().format(concession.createdAt)}',
                  trailing: StatusPill(
                    label: concession.status.label,
                    color: statusColor(concession.status.label),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _ReceiptPanel extends StatelessWidget {
  const _ReceiptPanel({
    required this.payments,
    required this.student,
    required this.summary,
    required this.school,
  });

  final List<Payment> payments;
  final Student student;
  final StudentFinanceSummary summary;
  final SchoolProfile school;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Recent Payments and Receipts',
      child: payments.isEmpty
          ? const EmptyState(message: 'No payments recorded yet.')
          : Column(
              children: payments.map((payment) {
                return _CompactListRow(
                  icon: Icons.receipt_long_outlined,
                  title: payment.receiptNo,
                  subtitle:
                      '${DateFormat.yMMMd().format(payment.date)} | ${payment.mode.label}',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        moneyFormat.format(payment.amount),
                        style: const TextStyle(
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Download Receipt PDF',
                        onPressed: payment.status == PaymentStatus.completed
                            ? () async {
                                final bytes =
                                    await ReportService.buildReceiptPdf(
                                      payment: payment,
                                      student: student,
                                      summary: summary,
                                      school: school,
                                    );
                                await Printing.sharePdf(
                                  bytes: bytes,
                                  filename:
                                      '${payment.receiptNo.replaceAll('/', '-')}.pdf',
                                );
                              }
                            : null,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _FeeTimeline extends StatelessWidget {
  const _FeeTimeline({
    required this.demands,
    required this.concessions,
    required this.payments,
  });

  final List<FeeDemand> demands;
  final List<Concession> concessions;
  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    final timelineItems = <_TimelineNode>[];

    for (final demand in demands) {
      timelineItems.add(
        _TimelineNode(
          date: demand.dueDate,
          title: 'Fee Demand Generated',
          subtitle: 'Amount due: ${moneyFormat.format(demand.amount)}',
          color: const Color(0xFF2563EB),
          icon: Icons.receipt_outlined,
        ),
      );
    }

    for (final concession in concessions) {
      timelineItems.add(
        _TimelineNode(
          date: concession.createdAt,
          title: 'Concession ${concession.status.label}',
          subtitle:
              '${concession.category} support: ${moneyFormat.format(concession.amount)}',
          color: statusColor(concession.status.label),
          icon: Icons.verified_outlined,
        ),
      );
    }

    for (final payment in payments) {
      timelineItems.add(
        _TimelineNode(
          date: payment.date,
          title: 'Payment ${payment.status.label}',
          subtitle:
              '${payment.receiptNo} | ${moneyFormat.format(payment.amount)}',
          color: statusColor(payment.status.label),
          icon: Icons.payments_outlined,
        ),
      );
    }

    timelineItems.sort((a, b) => b.date.compareTo(a.date));

    if (timelineItems.isEmpty) {
      return const EmptyState(message: 'No ledger timeline activities.');
    }

    return Column(
      children: timelineItems.map((node) {
        final isLast = node == timelineItems.last;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: node.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: node.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(node.icon, size: 16, color: node.color),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 44,
                    color: const Color(0xFFE2E8F0),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node.title,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            node.subtitle,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat.yMMMd().format(node.date),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _CompactListRow extends StatelessWidget {
  const _CompactListRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF0F766E), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyLegend extends StatelessWidget {
  const _MoneyLegend({
    required this.color,
    required this.value,
    required this.label,
  });

  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelBadge extends StatelessWidget {
  const _PanelBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActivityMetric {
  const _ActivityMetric({
    required this.label,
    required this.count,
    required this.amount,
    required this.status,
  });

  final String label;
  final String count;
  final double amount;
  final String status;
}

class _TimelineNode {
  const _TimelineNode({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
}

List<Student> _linkedStudentsForParent(AppState state) {
  final guardianId = state.currentUser?.guardianId;
  if (guardianId == null) return const [];
  return state.students
      .where((student) => student.guardianId == guardianId)
      .toList();
}

Student? _selectedStudent(AppState state, List<Student> linkedStudents) {
  if (linkedStudents.isEmpty) return null;
  for (final student in linkedStudents) {
    if (student.id == state.selectedStudentId) {
      return student;
    }
  }
  return linkedStudents.first;
}
