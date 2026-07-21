import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/finance_providers.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'parent_dashboard_screen.dart';
import 'student_dashboard_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.currentUser;
    if (user != null && user.role == UserRole.parent) {
      return const ParentDashboardScreen();
    }
    if (user != null && user.role == UserRole.student) {
      return const StudentDashboardScreen();
    }

    final stats = ref.watch(dashboardStatsProvider);
    final byClass = ref.watch(classPendingProvider);
    final modeTotals = ref.watch(paymentModeTotalsProvider);
    final defaulters = ref.watch(priorityDefaultersProvider);
    final width = MediaQuery.of(context).size.width;
    final statColumns = width > 1200
        ? 4
        : width > 760
        ? 2
        : 1;
    final collectionPercent = (stats.collectionRate * 100).toStringAsFixed(1);

    // Build collection trend from payments
    final trendData = _buildTrendData(state.payments);

    // Build concession breakdown
    final concessionBreakdown = <String, double>{};
    for (final c in state.concessions) {
      if (c.status == ConcessionStatus.approved) {
        concessionBreakdown.update(
          c.category,
          (v) => v + c.amount,
          ifAbsent: () => c.amount,
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardHero(
          collected: stats.totalCollected,
          pending: stats.totalPending,
          demand: stats.totalDemand,
          collectionRate: stats.collectionRate,
          collectionPercent: collectionPercent,
          defaulters: stats.defaulters,
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
            _AnimatedStatCard(
              title: 'Total Demand',
              value: stats.totalDemand,
              icon: Icons.request_quote_outlined,
              accent: const Color(0xFF2563EB),
              footer: 'Open academic year 2026-27',
            ),
            _AnimatedStatCard(
              title: 'Collected',
              value: stats.totalCollected,
              icon: Icons.account_balance_wallet_outlined,
              accent: const Color(0xFF047857),
              footer: '$collectionPercent% collection rate',
            ),
            _AnimatedStatCard(
              title: 'Pending',
              value: stats.totalPending,
              icon: Icons.pending_actions_outlined,
              accent: const Color(0xFFB45309),
              footer: '${stats.defaulters} overdue students',
            ),
            _AnimatedStatCard(
              title: 'Concessions',
              value: stats.totalConcessions,
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
              child: byClass.isEmpty
                  ? const EmptyState(message: 'No class data available.')
                  : ClassPendingBarChart(items: byClass),
            );
            final paymentPanel = SectionCard(
              title: 'Payment Mode Split',
              child: modeTotals.isEmpty
                  ? const EmptyState(message: 'No completed payments yet.')
                  : RevenueDonutChart(data: modeTotals),
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
            final stacked = constraints.maxWidth < 920;
            final trendPanel = SectionCard(
              title: 'Collection Trend (Last 7 Days)',
              child: trendData.values.every((v) => v == 0)
                  ? const EmptyState(message: 'No recent collection data.')
                  : CollectionTrendChart(
                      weeklyData: trendData.values.toList(),
                      labels: trendData.keys.toList(),
                    ),
            );
            final concessionPanel = SectionCard(
              title: 'Concession Breakdown',
              child: concessionBreakdown.isEmpty
                  ? const EmptyState(message: 'No approved concessions yet.')
                  : ConcessionBreakdownChart(data: concessionBreakdown),
            );

            return stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      trendPanel,
                      const SizedBox(height: 18),
                      concessionPanel,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: trendPanel),
                      const SizedBox(width: 18),
                      Expanded(child: concessionPanel),
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

  Map<String, double> _buildTrendData(List<Payment> payments) {
    final now = DateTime.now();
    final dayFmt = DateFormat('E');
    final trend = <String, double>{};
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      trend[dayFmt.format(day)] = 0;
    }
    for (final p in payments) {
      if (p.status == PaymentStatus.completed) {
        final diff = now.difference(p.date).inDays;
        if (diff >= 0 && diff < 7) {
          final key = dayFmt.format(p.date);
          if (trend.containsKey(key)) {
            trend[key] = trend[key]! + p.amount;
          }
        }
      }
    }
    return trend;
  }
}

// ─── Glassmorphism Hero ──────────────────────────────────────────────────────

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.collected,
    required this.pending,
    required this.demand,
    required this.collectionRate,
    required this.collectionPercent,
    required this.defaulters,
  });

  final double collected;
  final double pending;
  final double demand;
  final double collectionRate;
  final String collectionPercent;
  final int defaulters;

  @override
  Widget build(BuildContext context) {
    final progress = collectionRate.clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
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
            color: const Color(0xFF0F172A).withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 800;
          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: Color(0xFF14B8A6),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Live Demo Workspace',
                      style: TextStyle(
                        color: Color(0xFF14B8A6),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
                style: TextStyle(color: Color(0xFFCBD5E1), height: 1.45),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _HeroPill(
                    icon: Icons.trending_up,
                    label: '$collectionPercent% collected',
                    color: const Color(0xFF14B8A6),
                  ),
                  _HeroPill(
                    icon: Icons.warning_amber_rounded,
                    label: '$defaulters defaulters',
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ],
          );

          final right = GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.speed, color: Color(0xFF14B8A6), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Collection Health',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) {
                      return SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: val,
                                strokeWidth: 8,
                                strokeCap: StrokeCap.round,
                                backgroundColor: const Color(0xFF334155),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF14B8A6),
                                ),
                              ),
                            ),
                            Text(
                              '${(val * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Color(0xFF5EEAD4),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Collected',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedCounter(
                            value: collected,
                            style: const TextStyle(
                              color: Color(0xFF5EEAD4),
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pending',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedCounter(
                            value: pending,
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                        ],
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
                  children: [left, const SizedBox(height: 18), right],
                )
              : Row(
                  children: [
                    Expanded(flex: 3, child: left),
                    const SizedBox(width: 28),
                    Expanded(flex: 2, child: right),
                  ],
                );
        },
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated Stat Cards ────────────────────────────────────────────────────

class _AnimatedStatCard extends StatefulWidget {
  const _AnimatedStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    this.footer,
  });

  final String title;
  final double value;
  final IconData icon;
  final Color accent;
  final String? footer;

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: _hovered
            ? Matrix4.translationValues(0, -4, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? widget.accent.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: widget.accent, size: 22),
                ),
                const Spacer(),
                Icon(
                  Icons.trending_up,
                  color: widget.accent.withValues(alpha: 0.4),
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedCounter(
              value: widget.value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.title,
              style: TextStyle(
                color: widget.accent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            if (widget.footer != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.footer!,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Quick Actions ───────────────────────────────────────────────────────────

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

class _ActionButton extends StatefulWidget {
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
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 250,
        transform: _hovered
            ? Matrix4.diagonal3Values(1.02, 1.02, 1)
            : Matrix4.identity(),
        child: Material(
          color: _hovered ? const Color(0xFFE0F2F1) : const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: _hovered
                  ? const Color(0xFF0F766E).withValues(alpha: 0.3)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _hovered
                          ? const Color(0xFF0F766E)
                          : const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      color: _hovered
                          ? Colors.white
                          : const Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: _hovered
                        ? const Color(0xFF0F766E)
                        : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Defaulter List ──────────────────────────────────────────────────────────

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

// ─── Audit Trail Item ────────────────────────────────────────────────────────

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
