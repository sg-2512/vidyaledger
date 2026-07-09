import 'package:go_router/go_router.dart';

import '../screens/concessions_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/fee_engine_screen.dart';
import '../screens/login_screen.dart';
import '../screens/payments_screen.dart';
import '../screens/reconciliation_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/shell_screen.dart';
import '../screens/student_profile_screen.dart';
import '../screens/students_screen.dart';
import '../widgets/role_gate.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) =>
              const RoleGate(path: '/dashboard', child: DashboardScreen()),
        ),
        GoRoute(
          path: '/students',
          builder: (context, state) =>
              const RoleGate(path: '/students', child: StudentsScreen()),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => RoleGate(
                path: '/students/${state.pathParameters['id']!}',
                child: StudentProfileScreen(
                  studentId: state.pathParameters['id']!,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/fees',
          builder: (context, state) =>
              const RoleGate(path: '/fees', child: FeeEngineScreen()),
        ),
        GoRoute(
          path: '/concessions',
          builder: (context, state) =>
              const RoleGate(path: '/concessions', child: ConcessionsScreen()),
        ),
        GoRoute(
          path: '/payments',
          builder: (context, state) =>
              const RoleGate(path: '/payments', child: PaymentsScreen()),
        ),
        GoRoute(
          path: '/reconciliation',
          builder: (context, state) => const RoleGate(
            path: '/reconciliation',
            child: ReconciliationScreen(),
          ),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) =>
              const RoleGate(path: '/reports', child: ReportsScreen()),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) =>
              const RoleGate(path: '/settings', child: SettingsScreen()),
        ),
      ],
    ),
  ],
);
