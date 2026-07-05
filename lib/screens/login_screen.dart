import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/supabase_providers.dart';

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
      backgroundColor: const Color(0xFFF2F6F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 960;
            final productPanel = const _ProductPanel();
            final rolePanel = _RolePanel(roles: roles);

            return SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 18 : 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            productPanel,
                            const SizedBox(height: 18),
                            rolePanel,
                          ],
                        )
                      : IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Expanded(flex: 6, child: _ProductPanel()),
                              const SizedBox(width: 22),
                              Expanded(flex: 5, child: rolePanel),
                            ],
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProductPanel extends StatelessWidget {
  const _ProductPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VidyaLedger',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Smart School Finance OS',
                      style: TextStyle(color: Color(0xFF99F6E4)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF134E4A),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'PaperBuddy Smart School FinTech 2026',
              style: TextStyle(
                color: Color(0xFFCCFBF1),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'One auditable finance cockpit for Indian schools.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Manage fee demands, concessions, UPI/cash/cheque payments, reconciliation, defaulters, receipts, and reports from one role-based dashboard.',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 16,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ProofPoint(
                icon: Icons.payments_outlined,
                label: 'Omnichannel collection',
              ),
              _ProofPoint(
                icon: Icons.verified_user_outlined,
                label: 'Configurable concessions',
              ),
              _ProofPoint(
                icon: Icons.fact_check_outlined,
                label: 'Cheque and bank reconciliation',
              ),
              _ProofPoint(
                icon: Icons.receipt_long_outlined,
                label: 'PDF receipts and audit logs',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _MetricsStrip(),
        ],
      ),
    );
  }
}

class _RolePanel extends ConsumerStatefulWidget {
  const _RolePanel({required this.roles});

  final List<UserRole> roles;

  @override
  ConsumerState<_RolePanel> createState() => _RolePanelState();
}

class _RolePanelState extends ConsumerState<_RolePanel> {
  final emailController = TextEditingController(text: 'admin@vidyaledger.demo');
  final passwordController = TextEditingController(text: 'VidyaLedger@2026');
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backendEnabled = ref.watch(supabaseFinanceServiceProvider) != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              backendEnabled ? 'Sign In To Supabase' : 'Open Demo Workspace',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              backendEnabled
                  ? 'Use the demo Auth users you created in Supabase. Role cards can fill the email for faster testing.'
                  : 'Choose a role to view the same finance system through different school workflows.',
              style: const TextStyle(color: Color(0xFF6B7280), height: 1.4),
            ),
            const SizedBox(height: 18),
            if (backendEnabled) ...[
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: loading ? null : _signInWithSupabase,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(loading ? 'Signing in...' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 18),
            ],
            ...widget.roles.map(
              (role) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RoleTile(
                  role: role,
                  icon: _roleIcon(role),
                  onTap: () {
                    if (backendEnabled) {
                      emailController.text = _roleEmail(role);
                    } else {
                      ref.read(appControllerProvider.notifier).loginAs(role);
                      context.go('/dashboard');
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.storage_outlined, color: Color(0xFF0F766E)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      backendEnabled
                          ? 'Backend mode is active. Login loads students, fees, payments, concessions, reconciliation, and audit logs from Supabase.'
                          : 'Demo mode is active. Add Supabase dart-defines to enable real backend login.',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithSupabase() async {
    final service = ref.read(supabaseFinanceServiceProvider);
    if (service == null) return;

    setState(() => loading = true);
    try {
      await service.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      final user = await refreshAppStateFromSupabase(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signed in as ${user?.name ?? 'Supabase user'}'),
        ),
      );
      context.go('/dashboard');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backend login failed: $error')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
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

  String _roleEmail(UserRole role) {
    return switch (role) {
      UserRole.admin => 'admin@vidyaledger.demo',
      UserRole.principal => 'principal@vidyaledger.demo',
      UserRole.accountant => 'accounts@vidyaledger.demo',
      UserRole.clerk => 'clerk@vidyaledger.demo',
      UserRole.parent => 'parent@vidyaledger.demo',
    };
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.icon,
    required this.onTap,
  });

  final UserRole role;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFFFF),
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
                width: 42,
                height: 42,
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
                      role.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _roleDescription(role),
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
    );
  }

  String _roleDescription(UserRole role) {
    return switch (role) {
      UserRole.admin => 'Full dashboard, fees, users, and reports',
      UserRole.principal => 'Approvals, risk, concessions, and reports',
      UserRole.accountant => 'Payments, ledgers, and reconciliation',
      UserRole.clerk => 'Student search and counter collection',
      UserRole.parent => 'Linked child dues and receipts',
    };
  }
}

class _ProofPoint extends StatelessWidget {
  const _ProofPoint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111C31),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF26364F)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5EEAD4), size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsStrip extends StatelessWidget {
  const _MetricsStrip();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Metric(label: 'Roles', value: '5'),
        _Metric(label: 'Payment Modes', value: '4'),
        _Metric(label: 'Core Flows', value: '8'),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
