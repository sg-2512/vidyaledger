import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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
    final user = state.currentUser;
    final parentGuardianId = user?.guardianId;

    // Find the linked child
    final student = state.students.firstWhere(
      (s) => s.guardianId == parentGuardianId,
      orElse: () => state.students.first,
    );

    final summary = ref.watch(financeSummaryProvider(student.id));
    final demands = state.feeDemands
        .where((d) => d.studentId == student.id)
        .toList();
    final concessions = state.concessions
        .where((c) => c.studentId == student.id)
        .toList();
    final payments = state.payments
        .where((p) => p.studentId == student.id)
        .toList();
    final paymentRequests = state.paymentRequests
        .where((request) => request.studentId == student.id)
        .toList();

    final width = MediaQuery.of(context).size.width;
    final statColumns = width > 1100
        ? 3
        : width > 720
        ? 2
        : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parent Welcome Hero Card
        _ParentHero(student: student, guardianName: user?.name ?? 'Parent'),
        const SizedBox(height: 18),

        // Metrics Grid
        GridView.count(
          crossAxisCount: statColumns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.6,
          children: [
            StatCard(
              title: 'Total Fees Demand',
              value: moneyFormat.format(summary.totalDemand),
              icon: Icons.request_quote_outlined,
              accent: const Color(0xFF2563EB),
              footer: 'Academic year 2026-27 structure',
            ),
            StatCard(
              title: 'Total Paid to Date',
              value: moneyFormat.format(summary.paid),
              icon: Icons.check_circle_outline,
              accent: const Color(0xFF047857),
              footer: '${payments.length} successful transactions',
            ),
            StatCard(
              title: 'Outstanding Balance',
              value: moneyFormat.format(summary.pending),
              icon: summary.pending > 0
                  ? Icons.warning_amber_rounded
                  : Icons.verified_user_rounded,
              accent: summary.pending > 0
                  ? const Color(0xFFB45309)
                  : const Color(0xFF14B8A6),
              footer: summary.pending > 0
                  ? '${summary.overdueDays} days past due date'
                  : 'All fees settled',
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Quick Actions Row
        _ParentQuickActions(
          pendingAmount: summary.pending,
          onPayNow: () => _openPaymentDialog(context, student, summary.pending),
          onRequestWaiver: () => _openWaiverDialog(context, student),
        ),
        const SizedBox(height: 18),
        if (paymentRequests.isNotEmpty) ...[
          _ParentPaymentRequests(requests: paymentRequests),
          const SizedBox(height: 18),
        ],

        // Core Portal content (Split columns)
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 920;
            final timelinePanel = SectionCard(
              title: 'Child Fee Ledger Timeline',
              child: _FeeTimeline(
                demands: demands,
                concessions: concessions,
                payments: payments,
              ),
            );
            final historyPanel = SectionCard(
              title: 'Recent Payments & Receipts',
              child: payments.isEmpty
                  ? const EmptyState(message: 'No payments recorded yet.')
                  : Column(
                      children: payments.map((payment) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    payment.receiptNo,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${DateFormat.yMMMd().format(payment.date)} | ${payment.mode.label}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                moneyFormat.format(payment.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: () async {
                                  final bytes =
                                      await ReportService.buildReceiptPdf(
                                        payment: payment,
                                        student: student,
                                        summary: summary,
                                        school: state.school,
                                      );
                                  await Printing.sharePdf(
                                    bytes: bytes,
                                    filename:
                                        '${payment.receiptNo.replaceAll('/', '-')}.pdf',
                                  );
                                },
                                icon: const Icon(Icons.picture_as_pdf),
                                color: const Color(0xFF0F766E),
                                tooltip: 'Download Receipt PDF',
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            );

            return stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      timelinePanel,
                      const SizedBox(height: 18),
                      historyPanel,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: timelinePanel),
                      const SizedBox(width: 18),
                      Expanded(flex: 2, child: historyPanel),
                    ],
                  );
          },
        ),
      ],
    );
  }

  // ─── Pay Dues Dialog ───────────────────────────────────────────────────────

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
                    'Scan the UPI QR Code to simulate transaction',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  // Mock QR code frame
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
                              'UPI Payment completed successfully!',
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

  // ─── Concession request popup ──────────────────────────────────────────────

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
                          ]
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
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

// ─── Welcome Header ──────────────────────────────────────────────────────────

class _ParentHero extends StatelessWidget {
  const _ParentHero({required this.student, required this.guardianName});

  final Student student;
  final String guardianName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.family_restroom_outlined,
              size: 32,
              color: Color(0xFF14B8A6),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill(
                  label: 'Parent Portal Active',
                  color: Color(0xFF14B8A6),
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome, $guardianName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Linked Ward: ${student.name} (${student.admissionNo}) | Class ${student.classLabel}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Action Stepper ───────────────────────────────────────────────────

class _ParentQuickActions extends StatelessWidget {
  const _ParentQuickActions({
    required this.pendingAmount,
    required this.onPayNow,
    required this.onRequestWaiver,
  });

  final double pendingAmount;
  final VoidCallback onPayNow;
  final VoidCallback onRequestWaiver;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Portal Quick Actions',
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          _ActionButton(
            icon: Icons.payment,
            title: 'Pay Outstanding Fees',
            subtitle: 'Outstanding: ${moneyFormat.format(pendingAmount)}',
            color: const Color(0xFF0F766E),
            onTap: onPayNow,
          ),
          _ActionButton(
            icon: Icons.verified_user_outlined,
            title: 'Submit Concession Request',
            subtitle: 'Apply for school EWS/SC/ST support',
            color: const Color(0xFF7C3AED),
            onTap: onRequestWaiver,
          ),
        ],
      ),
    );
  }
}

class _ParentPaymentRequests extends StatelessWidget {
  const _ParentPaymentRequests({required this.requests});

  final List<PaymentRequest> requests;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Online Payment Requests',
      child: Column(
        children: requests.take(3).map((request) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    request.provider == PaymentProvider.upiIntent
                        ? Icons.qr_code_2
                        : Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${request.provider.label} | ${moneyFormat.format(request.amount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        request.requestNo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  label: request.status.label,
                  color: statusColor(request.status.label),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Copy payment link',
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: request.payableLink),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment link copied.')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Card(
        color: const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Vertical Timeline Stepper ──────────────────────────────────────────────

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

    // 1. Add demands
    for (final d in demands) {
      timelineItems.add(
        _TimelineNode(
          date: d.dueDate,
          title: 'Fee Demand Generated',
          subtitle: 'Amount due: ${moneyFormat.format(d.amount)}',
          color: const Color(0xFF2563EB),
          icon: Icons.receipt_outlined,
        ),
      );
    }

    // 2. Add approved concessions
    for (final c in concessions) {
      if (c.status == ConcessionStatus.approved) {
        timelineItems.add(
          _TimelineNode(
            date: c.createdAt,
            title: 'Concession / Support Applied',
            subtitle: '${c.category} waiver: -${moneyFormat.format(c.amount)}',
            color: const Color(0xFF7C3AED),
            icon: Icons.verified_outlined,
          ),
        );
      }
    }

    // 3. Add payments
    for (final p in payments) {
      if (p.status == PaymentStatus.completed) {
        timelineItems.add(
          _TimelineNode(
            date: p.date,
            title: 'Payment Received',
            subtitle:
                'Receipt: ${p.receiptNo} | Amount: ${moneyFormat.format(p.amount)}',
            color: const Color(0xFF047857),
            icon: Icons.check_circle_outline,
          ),
        );
      }
    }

    // Sort items chronologically
    timelineItems.sort((a, b) => b.date.compareTo(a.date));

    if (timelineItems.isEmpty) {
      return const EmptyState(message: 'No ledger timeline activities.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: timelineItems.length,
      itemBuilder: (context, index) {
        final node = timelineItems[index];
        final isLast = index == timelineItems.length - 1;

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
                    height: 48,
                    color: const Color(0xFFE2E8F0),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          node.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat.yMMMd().format(node.date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      node.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
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
