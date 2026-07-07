import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_state.dart';
import '../security/role_access.dart';

class RoleGate extends ConsumerWidget {
  const RoleGate({
    required this.path,
    required this.child,
    super.key,
  });

  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appControllerProvider).currentUser;
    if (user == null) {
      return Center(
        child: FilledButton.icon(
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.login),
          label: const Text('Return to login'),
        ),
      );
    }

    if (canAccessRoute(user.role, path)) {
      return child;
    }

    return _AccessDenied(
      message: accessMessageForPath(path),
      fallbackPath: defaultRouteForRole(user.role),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied({
    required this.message,
    required this.fallbackPath,
  });

  final String message;
  final String fallbackPath;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFFC2410C),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Access limited',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => context.go(fallbackPath),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go to allowed workspace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
