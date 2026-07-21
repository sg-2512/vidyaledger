import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/finance_providers.dart';
import '../widgets/common.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final user = state.currentUser;
    final student = state.students
        .firstWhere((s) {
          final ug = user?.guardianId;
          if (ug == null) return false;
          return ug == s.guardianId;
        },
        orElse: () => throw StateError('No student record found for current user'));

    final studentId = student.id;
    final summary = ref.watch(financeSummaryProvider(studentId));
    final demands = state.feeDemands
        .where((d) => d.studentId == studentId)
        .toList();
    final concessions = state.concessions
        .where((c) => c.studentId == studentId)
        .toList();
    final payments = state.payments
        .where((p) => p.studentId == studentId)
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
        // Student Welcome Hero Card
        _StudentHero(student: student, studentName: user?.name ?? 'Student'),
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
              title: 'Total Fees Due',
              value: moneyFormat.format(summary.totalDemand),
              icon: Icons.request_quote_outlined,
              accent: const Color(0xFF2563EB),
              footer: 'Academic year 2026-27 structure',
            ),
            StatCard(
              title: 'Total Paid',
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
              accent:
                  summary.pending > 0 ? const Color(0xFFB45309) : const Color(0xFF14B8A6),
              footer: summary.pending > 0
                  ? '${summary.overdueDays} days past due date'
                  : 'All fees settled',
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Core Portal content (Fee details)
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 920;
            final timelinePanel = SectionCard(
              title: 'Fee Ledger Timeline',
              child: _FeeTimeline(
                demands: demands,
                concessions: concessions,
                payments: payments,
              ),
            );
            final summaryPanel = SectionCard(
              title: 'Fee Summary',
              child: _FeeSummary(
                demands: demands,
                concessions: concessions,
                payments: payments,
                summary: summary,
              ),
            );

            return stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      timelinePanel,
                      const SizedBox(height: 18),
                      summaryPanel,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: timelinePanel),
                      const SizedBox(width: 18),
                      Expanded(flex: 2, child: summaryPanel),
                    ],
                  );
          },
        ),
      ],
    );
  }
}

// ─── Welcome Header ──────────────────────────────────────────────────────
class _StudentHero extends StatelessWidget {
  const _StudentHero({required this.student, required this.studentName});

  final Student student;
  final String studentName;

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
              border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.person_outline,
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
                  label: 'Student Portal Active',
                  color: Color(0xFF14B8A6),
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome, $studentName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Student: ${student.name} (${student.admissionNo}) | Class ${student.classLabel}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fee Summary ────────────────────────────────────────────────────────
class _FeeSummary extends StatelessWidget {
  const _FeeSummary({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fee Details Table
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Fee Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                  border: Border(
                    bottom: BorderSide(color: const Color(0xFFE2E8F0)),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Fee Type',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Paid',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Balance',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Fee Items
              ..._buildFeeItems(demands, concessions, payments),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Summary Message
        if (summary.pending > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _DueNotice(
              amountDue: summary.pending,
              overdueDays: summary.overdueDays,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const PaidInFullBanner(),
          ),
      ],
    );
  }

  List<Widget> _buildFeeItems(
      List<FeeDemand> demands, List<Concession> concessions, List<Payment> payments) {
    // Group demands by fee head for cleaner display
    final Map<String, double> demandByType = {};
    for (final demand in demands) {
      // In a real app, you'd look up the fee head name from feeHeadId
      // For demo, we'll use a simple mapping based on feeHeadId
      String feeHeadName = 'Fee';
      switch (demand.feeHeadId) {
        case 'fh-1':
          feeHeadName = 'Tuition Fee';
          break;
        case 'fh-2':
          feeHeadName = 'Transport Fee';
          break;
        case 'fh-3':
          feeHeadName = 'Exam Fee';
          break;
        case 'fh-4':
          feeHeadName = 'Caution Deposit';
          break;
        default:
          feeHeadName = 'Fee';
      }
      demandByType.update(
        feeHeadName,
        (value) => value + demand.amount,
        ifAbsent: () => demand.amount,
      );
    }

    // Calculate total concessions by type (simplified)
    final totalConcessions =
        concessions.where((c) => c.status == ConcessionStatus.approved)
            .fold<double>(0, (sum, c) => sum + c.amount);

    // Calculate total payments
    final totalPaid =
        payments.where((p) => p.status == PaymentStatus.completed)
            .fold<double>(0, (sum, p) => sum + p.amount);

    final totalDemand =
        demands.fold<double>(0, (sum, d) => sum + d.amount);

    return [
      // Tuition Fee Row
      _FeeItemRow(
        label: 'Tuition Fee',
        demand: demandByType['Tuition Fee'] ?? 0.0,
        paid: totalPaid * 0.7, // Simplified distribution
        concessions: totalConcessions * 0.7, // Simplified distribution
      ),
      // Transport Fee Row
      _FeeItemRow(
        label: 'Transport Fee',
        demand: demandByType['Transport Fee'] ?? 0.0,
        paid: totalPaid * 0.2, // Simplified distribution
        concessions: totalConcessions * 0.2, // Simplified distribution
      ),
      // Exam Fee Row
      _FeeItemRow(
        label: 'Exam Fee',
        demand: demandByType['Exam Fee'] ?? 0.0,
        paid: totalPaid * 0.1, // Simplified distribution
        concessions: totalConcessions * 0.1, // Simplified distribution
      ),
      // Total Row
      Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: const Color(0xFFE2E8F0)),
          ),
        ),
        child: _FeeItemRow(
          label: 'TOTAL',
          demand: totalDemand,
          paid: totalPaid,
          concessions: totalConcessions,
          isTotal: true,
        ),
      ),
    ];
  }
}

class _FeeItemRow extends StatelessWidget {
  const _FeeItemRow({
    required this.label,
    required this.demand,
    required this.paid,
    required this.concessions,
    this.isTotal = false,
  });

  final String label;
  final double demand;
  final double paid;
  final double concessions;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final balance = (demand - concessions - paid).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isTotal ? const Color(0xFFF8FAFC) : null,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                color: isTotal ? Color(0xFF111827) : Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              moneyFormat.format(demand),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                color: isTotal ? Color(0xFF111827) : Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              moneyFormat.format(paid),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                color: isTotal ? Color(0xFF111827) : Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              moneyFormat.format(balance),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                color: isTotal
                    ? Color(0xFF111827)
                    : balance > 0
                        ? Color(0xFFB45309)
                        : Color(0xFF047857),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Due Notice ────────────────────────────────────────────────────────
class _DueNotice extends StatelessWidget {
  const _DueNotice({
    required this.amountDue,
    required this.overdueDays,
  });

  final double amountDue;
  final int overdueDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Color(0xFFB45309)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount Due: ${moneyFormat.format(amountDue)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
                if (overdueDays > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$overdueDays days overdue',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Paid in Full Banner ────────────────────────────────────────────────
class PaidInFullBanner extends StatelessWidget {
  const PaidInFullBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF047857)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'All fees paid up to date!',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF047857),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vertical Timeline Stepper ─────────────────────────────────────────
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
      timelineItems.add(_TimelineNode(
        date: d.dueDate,
        title: 'Fee Due',
        subtitle: 'Amount due: ${moneyFormat.format(d.amount)}',
        color: const Color(0xFF2563EB),
        icon: Icons.receipt_outlined,
      ));
    }

    // 2. Add approved concessions
    for (final c in concessions) {
      if (c.status == ConcessionStatus.approved) {
        timelineItems.add(_TimelineNode(
          date: c.createdAt,
          title: 'Concession Applied',
          subtitle: '${c.category} waiver: -${moneyFormat.format(c.amount)}',
          color: const Color(0xFF7C3AED),
          icon: Icons.verified_outlined,
        ));
      }
    }

    // 3. Add payments
    for (final p in payments) {
      if (p.status == PaymentStatus.completed) {
        timelineItems.add(_TimelineNode(
          date: p.date,
          title: 'Payment Received',
          subtitle: 'Receipt: ${p.receiptNo} | Amount: ${moneyFormat.format(p.amount)}',
          color: const Color(0xFF047857),
          icon: Icons.check_circle_outline,
        ));
      }
    }

    // Sort items chronologically (newest first)
    timelineItems.sort((a, b) => b.date.compareTo(a.date));

    if (timelineItems.isEmpty) {
      return const Center(child: Text('No fee activity yet.'));
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
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: node.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: node.color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(node.icon, size: 14, color: node.color),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 24,
                    color: const Color(0xFFE2E8F0),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
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