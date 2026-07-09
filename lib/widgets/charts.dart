import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _moneyFmt = NumberFormat.currency(
  locale: 'en_IN',
  symbol: 'Rs ',
  decimalDigits: 0,
);

// ─── 1. Revenue Donut Chart ────────────────────────────────────────────────────

class RevenueDonutChart extends StatelessWidget {
  const RevenueDonutChart({required this.data, super.key});

  final Map<String, double> data;

  static const _colors = <String, Color>{
    'UPI': Color(0xFF6366F1),
    'Cash': Color(0xFF14B8A6),
    'Cheque': Color(0xFFF59E0B),
    'Bank Transfer': Color(0xFF8B5CF6),
  };

  static const _fallbackColors = [
    Color(0xFF6366F1),
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF3B82F6),
  ];

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<double>(0, (s, v) => s + v);
    final entries = data.entries.toList();

    return SizedBox(
      height: 280,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: List.generate(entries.length, (i) {
                      final e = entries[i];
                      final color =
                          _colors[e.key] ??
                          _fallbackColors[i % _fallbackColors.length];
                      final pct =
                          total == 0 ? 0.0 : (e.value / total * 100);
                      return PieChartSectionData(
                        value: e.value,
                        title: '${pct.toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        color: color,
                        radius: 55,
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        showTitle: true,
                        titlePositionPercentageOffset: 0.55,
                      );
                    }),
                    borderData: FlBorderData(show: false),
                  ),
                ),
                // Center total
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _moneyFmt.format(total),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(entries.length, (i) {
              final e = entries[i];
              final color =
                  _colors[e.key] ??
                  _fallbackColors[i % _fallbackColors.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    e.key,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── 2. Class Pending Bar Chart ────────────────────────────────────────────────

class ClassPendingBarChart extends StatelessWidget {
  const ClassPendingBarChart({required this.items, super.key});

  final Map<String, double> items;

  @override
  Widget build(BuildContext context) {
    final entries = items.entries.toList();
    final maxY = entries.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    // Round up maxY to a nice number
    final ceilY = maxY == 0 ? 100.0 : (maxY * 1.2);

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          maxY: ceilY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = entries[group.x.toInt()].key;
                return BarTooltipItem(
                  '$label\n${_moneyFmt.format(rod.toY)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == meta.min) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    _moneyFmt.format(value),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      entries[idx].key,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ceilY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFFE5E7EB),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(entries.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value,
                  width: 28,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ─── 3. Collection Trend Chart ─────────────────────────────────────────────────

class CollectionTrendChart extends StatefulWidget {
  const CollectionTrendChart({
    required this.weeklyData,
    required this.labels,
    super.key,
  });

  final List<double> weeklyData;
  final List<String> labels;

  @override
  State<CollectionTrendChart> createState() => _CollectionTrendChartState();
}

class _CollectionTrendChartState extends State<CollectionTrendChart> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    // Trigger animation on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animate = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.weeklyData;
    final labels = widget.labels;
    final maxY = data.fold<double>(0, (m, v) => v > m ? v : m);
    final ceilY = maxY == 0 ? 100.0 : (maxY * 1.2);

    return SizedBox(
      height: 200,
      child: AnimatedOpacity(
        opacity: _animate ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 600),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: ceilY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((spot) {
                  return LineTooltipItem(
                    _moneyFmt.format(spot.y),
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: ceilY / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: const Color(0xFFE5E7EB),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max || value == meta.min) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      _moneyFmt.format(value),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        labels[idx],
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  data.length,
                  (i) => FlSpot(i.toDouble(), _animate ? data[i] : 0),
                ),
                isCurved: true,
                curveSmoothness: 0.35,
                color: const Color(0xFF14B8A6),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, pct, barData, idx) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFF14B8A6),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF14B8A6).withValues(alpha: 0.3),
                      const Color(0xFF14B8A6).withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        ),
      ),
    );
  }
}

// ─── 4. Concession Breakdown Chart ─────────────────────────────────────────────

class ConcessionBreakdownChart extends StatelessWidget {
  const ConcessionBreakdownChart({required this.data, super.key});

  final Map<String, double> data;

  static const _earthTones = [
    Color(0xFF92400E), // warm brown
    Color(0xFF78716C), // stone
    Color(0xFF7C3AED), // muted violet
    Color(0xFFB45309), // amber
    Color(0xFF0F766E), // teal
    Color(0xFF6D28D9), // deep purple
  ];

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final total = data.values.fold<double>(0, (s, v) => s + v);

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          // Pie chart
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: List.generate(entries.length, (i) {
                  final e = entries[i];
                  final color = _earthTones[i % _earthTones.length];
                  final pct = total == 0 ? 0.0 : (e.value / total * 100);
                  return PieChartSectionData(
                    value: e.value,
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    color: color,
                    radius: 45,
                    titlePositionPercentageOffset: 0.55,
                  );
                }),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Horizontal legend
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(entries.length, (i) {
                final e = entries[i];
                final color = _earthTones[i % _earthTones.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      Text(
                        _moneyFmt.format(e.value),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
