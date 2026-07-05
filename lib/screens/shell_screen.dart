import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/app_state.dart';

class ShellScreen extends ConsumerWidget {
  const ShellScreen({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.currentUser;
    if (user == null) {
      return const _SignedOutFallback();
    }

    final navItems = [
      _NavItem('Dashboard', Icons.dashboard_outlined, '/dashboard'),
      _NavItem('Students', Icons.groups_outlined, '/students'),
      _NavItem('Fee Engine', Icons.tune, '/fees'),
      _NavItem('Concessions', Icons.verified_user_outlined, '/concessions'),
      _NavItem('Payments', Icons.payments_outlined, '/payments'),
      _NavItem('Reconciliation', Icons.fact_check_outlined, '/reconciliation'),
      _NavItem('Reports', Icons.picture_as_pdf_outlined, '/reports'),
    ];

    void logout() {
      ref.read(appControllerProvider.notifier).logout();
      context.go('/login');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('VidyaLedger'),
              actions: [
                IconButton(
                  tooltip: 'Logout',
                  onPressed: logout,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            drawer: Drawer(
              child: SafeArea(
                child: _NavigationPanel(
                  userName: user.name,
                  roleLabel: user.role.label,
                  navItems: navItems,
                  onLogout: logout,
                ),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 250,
                child: _NavigationPanel(
                  userName: user.name,
                  roleLabel: user.role.label,
                  navItems: navItems,
                  onLogout: logout,
                ),
              ),
              Expanded(
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({
    required this.userName,
    required this.roleLabel,
    required this.navItems,
    required this.onLogout,
  });

  final String userName;
  final String roleLabel;
  final List<_NavItem> navItems;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'VidyaLedger',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Text(
              '$userName\n$roleLabel',
              style: const TextStyle(color: Color(0xFFCBD5E1), height: 1.45),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: navItems.map((item) {
                final active = GoRouterState.of(context).uri.path == item.path;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    selected: active,
                    selectedTileColor: const Color(0xFF134E4A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    leading: Icon(
                      item.icon,
                      color: active ? Colors.white : const Color(0xFF94A3B8),
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: active ? Colors.white : const Color(0xFFCBD5E1),
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    onTap: () => context.go(item.path),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF334155)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedOutFallback extends StatelessWidget {
  const _SignedOutFallback();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/login'),
          child: const Text('Return to login'),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}
