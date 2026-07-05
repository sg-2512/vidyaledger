import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/app_state.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = [
      UserRole.admin,
      UserRole.principal,
      UserRole.accountant,
      UserRole.clerk,
      UserRole.parent,
    ];

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.account_balance, color: Colors.white),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'VidyaLedger',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF111827),
                            ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Smart school fee, exemption, reconciliation, and accounting management for Indian schools.',
                        style: TextStyle(fontSize: 17, color: Color(0xFF4B5563), height: 1.45),
                      ),
                      const SizedBox(height: 24),
                      const Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          Chip(label: Text('Dynamic Fee Engine')),
                          Chip(label: Text('RTE/EWS/SC/ST Concessions')),
                          Chip(label: Text('UPI/Cash/Cheque Tracking')),
                          Chip(label: Text('Receipts & Reports')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Demo Login',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose a role to test the hackathon prototype.',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 18),
                          ...roles.map(
                            (role) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: FilledButton.icon(
                                onPressed: () {
                                  ref.read(appControllerProvider.notifier).loginAs(role);
                                  context.go('/dashboard');
                                },
                                icon: Icon(_roleIcon(role)),
                                label: Text('Continue as ${role.label}'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Supabase Auth can be enabled with --dart-define keys after database setup.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _roleIcon(UserRole role) {
    return switch (role) {
      UserRole.admin => Icons.admin_panel_settings,
      UserRole.principal => Icons.school,
      UserRole.accountant => Icons.calculate,
      UserRole.clerk => Icons.receipt_long,
      UserRole.parent => Icons.family_restroom,
    };
  }
}
