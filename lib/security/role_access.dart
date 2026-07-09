import '../models/models.dart';

const staffRoles = {
  UserRole.admin,
  UserRole.principal,
  UserRole.accountant,
  UserRole.clerk,
};

const accountingRoles = {
  UserRole.admin,
  UserRole.principal,
  UserRole.accountant,
};

const adminOnlyRoles = {UserRole.admin};

const setupRoles = {UserRole.admin, UserRole.principal};

bool canAccessRoute(UserRole role, String path) {
  if (path.startsWith('/students/')) {
    return role == UserRole.parent || staffRoles.contains(role);
  }

  return switch (path) {
    '/dashboard' => role == UserRole.parent || staffRoles.contains(role),
    '/students' => role == UserRole.parent || staffRoles.contains(role),
    '/fees' => accountingRoles.contains(role),
    '/concessions' => accountingRoles.contains(role),
    '/payments' => staffRoles.contains(role),
    '/reconciliation' => accountingRoles.contains(role),
    '/reports' => accountingRoles.contains(role),
    '/settings' => setupRoles.contains(role),
    _ => false,
  };
}

String defaultRouteForRole(UserRole role) {
  return switch (role) {
    UserRole.parent => '/dashboard',
    UserRole.clerk => '/payments',
    _ => '/dashboard',
  };
}

String accessMessageForPath(String path) {
  return switch (path) {
    '/dashboard' => 'The school-wide dashboard is available to staff roles.',
    '/fees' =>
      'Fee configuration is available to admin, principal, and accountant roles.',
    '/concessions' =>
      'Concession approvals are available to admin, principal, and accountant roles.',
    '/reconciliation' =>
      'Settlement reconciliation is available to admin, principal, and accountant roles.',
    '/reports' =>
      'Finance reports are available to admin, principal, and accountant roles.',
    '/settings' =>
      'School settings are available to admin and principal roles.',
    _ => 'This role does not have access to this workspace.',
  };
}
