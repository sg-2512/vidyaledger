import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final moneyFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: 'Rs ',
  decimalDigits: 0,
);

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    this.footer,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const Spacer(),
                const Icon(
                  Icons.trending_up,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            if (footer case final footer?) ...[
              const SizedBox(height: 6),
              Text(footer, style: const TextStyle(color: Color(0xFF6B7280))),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({required this.items, super.key});

  final Map<String, double> items;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    return Column(
      children: items.entries.map((entry) {
        final widthFactor = maxValue == 0 ? 0.0 : entry.value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: widthFactor,
                    minHeight: 16,
                    backgroundColor: const Color(0xFFE5E7EB),
                    color: const Color(0xFF0F766E),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 86,
                child: Text(
                  moneyFormat.format(entry.value),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}

Color statusColor(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('approved') ||
      lower.contains('completed') ||
      lower.contains('matched') ||
      lower.contains('active')) {
    return const Color(0xFF047857);
  }
  if (lower.contains('pending') ||
      lower.contains('submitted') ||
      lower.contains('partial')) {
    return const Color(0xFFB45309);
  }
  if (lower.contains('bounced') ||
      lower.contains('rejected') ||
      lower.contains('duplicate')) {
    return const Color(0xFFB91C1C);
  }
  return const Color(0xFF4B5563);
}

// ─── GlassCard ─────────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  const GlassCard({required this.child, this.padding, this.gradient, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ??
            LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─── AnimatedCounter ───────────────────────────────────────────────────────────

class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    required this.value,
    required this.style,
    this.prefix = '',
    this.duration,
    super.key,
  });

  final double value;
  final TextStyle style;
  final String prefix;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration ?? const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, val, _) => Text(
        '$prefix${NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0).format(val)}',
        style: style,
      ),
    );
  }
}
