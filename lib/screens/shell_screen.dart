import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/supabase_providers.dart';
import '../security/role_access.dart';
import '../widgets/notifications_panel.dart';

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
      _NavItem('Settings', Icons.settings_outlined, '/settings'),
    ].where((item) => canAccessRoute(user.role, item.path)).toList();

    Future<void> logout() async {
      final service = ref.read(supabaseFinanceServiceProvider);
      if (service != null) {
        await service.signOut();
      }
      if (!context.mounted) return;
      ref.read(appControllerProvider.notifier).logout();
      context.go('/login');
    }

    if (user.role == UserRole.parent) {
      final linkedStudents = ref
          .read(appControllerProvider.notifier)
          .visibleStudents();
      final selectedStudent = _selectedStudentForParent(state, linkedStudents);

      return _ParentPortalShell(
        user: user,
        linkedStudents: linkedStudents,
        selectedStudent: selectedStudent,
        onLogout: logout,
        onSelectStudent: (studentId) {
          ref.read(appControllerProvider.notifier).selectStudent(studentId);
          context.go('/dashboard');
        },
        child: child,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('VidyaLedger'),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              actions: [
                const NotificationBell(),
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
                  school: state.school,
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
                width: 288,
                child: _NavigationPanel(
                  userName: user.name,
                  roleLabel: user.role.label,
                  school: state.school,
                  navItems: navItems,
                  onLogout: logout,
                ),
              ),
              Expanded(
                child: SafeArea(
                  child: Column(
                    children: [
                      _TopBar(
                        userName: user.name,
                        roleLabel: user.role.label,
                        school: state.school,
                        onLogout: logout,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: child,
                        ),
                      ),
                    ],
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

class _ParentPortalShell extends StatelessWidget {
  const _ParentPortalShell({
    required this.child,
    required this.user,
    required this.linkedStudents,
    required this.selectedStudent,
    required this.onLogout,
    required this.onSelectStudent,
  });

  final Widget child;
  final AppUser user;
  final List<Student> linkedStudents;
  final Student? selectedStudent;
  final VoidCallback onLogout;
  final ValueChanged<String> onSelectStudent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FAFA),
      endDrawer: _ParentProfileDrawer(
        user: user,
        linkedStudents: linkedStudents,
        selectedStudent: selectedStudent,
        onLogout: onLogout,
        onSelectStudent: onSelectStudent,
      ),
      body: Row(
        children: [
          _ParentRail(selectedStudent: selectedStudent, onLogout: onLogout),
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _ParentTopBar(user: user, selectedStudent: selectedStudent),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 26, 24),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentTopBar extends StatelessWidget {
  const _ParentTopBar({required this.user, required this.selectedStudent});

  final AppUser user;
  final Student? selectedStudent;

  @override
  Widget build(BuildContext context) {
    final student = selectedStudent;
    final title = student == null
        ? 'Parent Dashboard'
        : 'Dashboard For ${student.name} | (Adm No: ${student.admissionNo}; ${student.classLabel})';

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6EEF2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF16324A),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const NotificationBell(),
          const SizedBox(width: 6),
          Builder(
            builder: (context) {
              return Tooltip(
                message: 'Profile menu',
                child: InkWell(
                  onTap: () => Scaffold.of(context).openEndDrawer(),
                  borderRadius: BorderRadius.circular(999),
                  child: _AvatarInitial(name: user.name, size: 38),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ParentRail extends StatelessWidget {
  const _ParentRail({required this.selectedStudent, required this.onLogout});

  final Student? selectedStudent;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final profilePath = selectedStudent == null
        ? null
        : '/students/${selectedStudent!.id}';

    return Container(
      width: 58,
      color: const Color(0xFF25313D),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF8B420),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 26),
            _ParentRailAction(
              icon: Icons.dashboard_outlined,
              tooltip: 'Dashboard',
              active: currentPath == '/dashboard',
              onTap: () => context.go('/dashboard'),
            ),
            _ParentRailAction(
              icon: Icons.badge_outlined,
              tooltip: 'Student Profile',
              active: profilePath != null && currentPath == profilePath,
              onTap: profilePath == null ? null : () => context.go(profilePath),
            ),
            const Spacer(),
            _ParentRailAction(
              icon: Icons.logout,
              tooltip: 'Logout',
              active: false,
              onTap: onLogout,
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _ParentRailAction extends StatelessWidget {
  const _ParentRailAction({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: active ? const Color(0xFF40536A) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 44,
              height: 42,
              child: Icon(
                icon,
                color: onTap == null
                    ? const Color(0xFF718093)
                    : active
                    ? Colors.white
                    : const Color(0xFFCFD8E3),
                size: 23,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParentProfileDrawer extends StatelessWidget {
  const _ParentProfileDrawer({
    required this.user,
    required this.linkedStudents,
    required this.selectedStudent,
    required this.onLogout,
    required this.onSelectStudent,
  });

  final AppUser user;
  final List<Student> linkedStudents;
  final Student? selectedStudent;
  final VoidCallback onLogout;
  final ValueChanged<String> onSelectStudent;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 306,
      backgroundColor: const Color(0xFF2B3541),
      surfaceTintColor: const Color(0xFF2B3541),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Row(
                children: [
                  _AvatarInitial(name: user.name, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: const Color(0xFF2B3541),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2B3541),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF465463), height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text(
                'MENU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonFormField<String>(
                initialValue: selectedStudent?.id,
                dropdownColor: const Color(0xFF344150),
                iconEnabledColor: Colors.white,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF2B3541),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  prefixIcon: const Icon(Icons.swap_horiz, color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                hint: const Text(
                  'Switch Student',
                  style: TextStyle(color: Colors.white),
                ),
                items: linkedStudents.map((student) {
                  return DropdownMenuItem(
                    value: student.id,
                    child: Text(
                      '${student.name} (${student.classLabel})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: linkedStudents.length < 2
                    ? null
                    : (studentId) {
                        if (studentId == null) return;
                        onSelectStudent(studentId);
                        Navigator.of(context).pop();
                      },
              ),
            ),
            const SizedBox(height: 14),
            _ParentDrawerAction(
              icon: Icons.badge_outlined,
              label: 'Student Profile',
              onTap: selectedStudent == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      context.go('/students/${selectedStudent!.id}');
                    },
            ),
            _ParentDrawerAction(
              icon: Icons.dashboard_outlined,
              label: 'Fee Dashboard',
              onTap: () {
                Navigator.of(context).pop();
                context.go('/dashboard');
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: Divider(color: Color(0xFF465463), height: 1),
            ),
            _ParentDrawerAction(
              icon: Icons.power_settings_new,
              label: 'Logout',
              onTap: () {
                Navigator.of(context).pop();
                onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentDrawerAction extends StatelessWidget {
  const _ParentDrawerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: onTap != null,
      leading: Icon(icon, color: const Color(0xFFCFD8E3), size: 22),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF7E57C2),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

Student? _selectedStudentForParent(AppState state, List<Student> students) {
  if (students.isEmpty) return null;
  for (final student in students) {
    if (student.id == state.selectedStudentId) {
      return student;
    }
  }
  return students.first;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.userName,
    required this.roleLabel,
    required this.school,
    required this.onLogout,
  });

  final String userName;
  final String roleLabel;
  final SchoolProfile school;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        return Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              const Icon(Icons.school_outlined, color: Color(0xFF0F766E)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${school.board} | ${school.locationLabel} | AY ${school.academicYear}',
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
              if (!compact) ...[
                _StatusChip(
                  icon: Icons.dataset_outlined,
                  label: 'Demo Data',
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  icon: Icons.storage_outlined,
                  label: 'Supabase Ready',
                  color: const Color(0xFF0F766E),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '$userName - $roleLabel',
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              const NotificationBell(),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Logout',
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
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
  }
}

class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({
    required this.userName,
    required this.roleLabel,
    required this.school,
    required this.navItems,
    required this.onLogout,
  });

  final String userName;
  final String roleLabel;
  final SchoolProfile school;
  final List<_NavItem> navItems;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VidyaLedger',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'AY ${school.academicYear}',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        roleLabel,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Text(
              'Workspace',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: navItems.map((item) {
                final active =
                    currentPath == item.path ||
                    (item.path != '/dashboard' &&
                        currentPath.startsWith(item.path));
                return _NavTile(
                  item: item,
                  active: active,
                  onTap: () => context.go(item.path),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? Colors.white : const Color(0xFF475569);
    final background = active ? const Color(0xFF0F766E) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, color: foreground, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
                if (active)
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
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
