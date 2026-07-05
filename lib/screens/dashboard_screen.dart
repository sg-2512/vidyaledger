import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/finance_providers.dart';
import '../widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final byClass = ref.watch(classPendingProvider);
    final modeTotals = ref.watch(paymentModeTotalsProvider);
    final defaulters = ref.watch(priorityDefaultersProvider);
    final width = MediaQuery.of(context).size.width;
    final statColumns = width > 1200 ? 4 : width > 760 ? 2 : 1;
    final collectionPercent = (stats.collectionRate * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardHero(
          collected: stats.totalCollected,
          pending: stats.totalPending,
          collectionRate: stats.collectionRate,
          collectionPercent: collectionPercent,
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: statColumns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.55,
          children: [
            StatCard(
              title: 'Total Demand',
              value: moneyFormat.format(stats.totalDemand),
              icon: Icons.request_quote_outlined,
              accent: const Color(0xFF2563EB),
              footer: 'Open academic year 2026-27',
            ),
            StatCard(
              title: 'Collected',
              value: moneyFormat.format(stats.totalCollected),
              icon: Icons.account_balance_wallet_outlined,
              accent: const Color(0xFF047857),
              footer: '$collectionPercent% collection rate',
            ),
            StatCard(
              title: 'Pending',
              value: moneyFormat.format(stats.totalPending),
              icon: Icons.pending_actions_outlined,
              accent: const Color(0xFFB45309),
              footer: '${stats.defaulters} overdue students',
            ),
            StatCard(
              title: 'Concessions',
              value: moneyFormat.format(stats.totalConcessions),
              icon: Icons.verified_outlined,
              accent: const Color(0xFF7C3AED),
              footer: 'EWS, SC, ST, minority support',
            ),
          ],
        ),
        const SizedBox(height: 18),
        _QuickActions(
          onPayment: () => context.go('/payments'),
          onFee: () => context.go('/fees'),
          onConcession: () => context.go('/concessions'),
          onReports: () => context.go('/reports'),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 920;
            final classPanel = SectionCard(
              title: 'Class-wise Pending Dues',
              child: SimpleBarChart(items: byClass),
            );
            final paymentPanel = SectionCard(
              title: 'Payment Mode Split',
              child: modeTotals.isEmpty
                  ? const EmptyState(message: 'No completed payments yet.')
                  : SimpleBarChart(items: modeTotals),
            );

            return stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      classPanel,
                      const SizedBox(height: 18),
                      paymentPanel,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: classPanel),
                      const SizedBox(width: 18),
                      Expanded(child: paymentPanel),
                    ],
                  );
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            final defaulterPanel = SectionCard(
              title: 'Priority Defaulters',
              child: defaulters.isEmpty
                  ? const EmptyState(
                      message: 'No overdue defaulters in current data.',
                    )
                  : _DefaulterList(defaulters: defaulters),
            );
            final auditPanel = SectionCard(
              title: 'Recent Audit Trail',
              child: Column(
                children: state.auditLogs.take(4).map((log) {
                  return _AuditItem(
                    actor: log.actor,
                    action: log.action,
                    objectType: log.objectType,
                  );
                }).toList(),
              ),
            );

            return stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      defaulterPanel,
                      const SizedBox(height: 18),
                      auditPanel,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: defaulterPanel),
                      const SizedBox(width: 18),
                      Expanded(flex: 2, child: auditPanel),
                    ],
                  );
          },
        ),
      ],
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.collected,
    required this.pending,
    required this.collectionRate,
    required this.collectionPercent,
  });

  final double collected;
  final double pending;
  final double collectionRate;
  final String collectionPercent;

  @override
  Widget build(BuildContext context) {
    final progress = collectionRate.clamp(0, 1).toDouble();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 800;
          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusPill(
                label: 'Live Demo Workspace',
                color: Color(0xFF14B8A6),
              ),
              const SizedBox(height: 16),
              Text(
                'Finance Command Center',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Revenue, concessions, cheque risk, and reconciliation in one school finance dashboard.',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  height: 1.45,
                ),
              ),
            ],
          );
          final right = Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Collection Health',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '$collectionPercent%',
                      style: const TextStyle(
                        color: Color(0xFF5EEAD4),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    color: const Color(0xFF14B8A6),
                    backgroundColor: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(
                        label: 'Collected',
                        value: moneyFormat.format(collected),
                        color: const Color(0xFF5EEAD4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeroMetric(
                        label: 'Pending',
                        value: moneyFormat.format(pending),
                        color: const Color(0xFFFBBF24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          return stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    left,
                    const SizedBox(height: 18),
                    right,
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 3, child: left),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: right),
                  ],
                );
        },
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8))),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onPayment,
    required this.onFee,
    required this.onConcession,
    required this.onReports,
  });

  final VoidCallback onPayment;
  final VoidCallback onFee;
  final VoidCallback onConcession;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Quick Actions',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _ActionButton(
            icon: Icons.payments_outlined,
            title: 'Record Payment',
            subtitle: 'UPI, cash, cheque',
            onTap: onPayment,
          ),
          _ActionButton(
            icon: Icons.tune,
            title: 'Generate Fee',
            subtitle: 'Class-wise demand',
            onTap: onFee,
          ),
          _ActionButton(
            icon: Icons.verified_user_outlined,
            title: 'Approve Concession',
            subtitle: 'RTE/EWS/SC/ST',
            onTap: onConcession,
          ),
          _ActionButton(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Export Reports',
            subtitle: 'Receipt and collection',
            onTap: onReports,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Material(
        color: const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF0F766E)),
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
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Color(0xFF0F766E)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaulterList extends ConsumerWidget {
  const _DefaulterList({required this.defaulters});

  final List<Student> defaulters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: defaulters.map((student) {
        final summary = ref.watch(financeSummaryProvider(student.id));
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  student.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(child: Text(student.classLabel)),
              Expanded(child: Text(moneyFormat.format(summary.pending))),
              Expanded(child: Text('${summary.overdueDays} days')),
              StatusPill(
                label: student.category,
                color: const Color(0xFF0F766E),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AuditItem extends StatelessWidget {
  const _AuditItem({
    required this.actor,
    required this.action,
    required this.objectType,
  });

  final String actor;
  final String action;
  final String objectType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.history,
              color: Color(0xFF0F766E),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '$actor - $objectType',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
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
