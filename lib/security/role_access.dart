import '../models/models.dart';

const staffRoles = {UserRole.admin};

const accountingRoles = {UserRole.admin};

const adminOnlyRoles = {UserRole.admin};

const setupRoles = {UserRole.admin};

bool canAccessRoute(UserRole role, String path) {
  if (path.startsWith('/students/')) {
    // Parents can view their children's data, students can only view their own
    return role == UserRole.parent;
  }

  return switch (path) {
    '/dashboard' => role == UserRole.admin || role == UserRole.parent,
    '/fees' => role == UserRole.admin,
    '/concessions' => role == UserRole.admin,
    '/payments' => role == UserRole.admin,
    '/reports' => role == UserRole.admin,
    '/settings' => role == UserRole.admin,
    _ => role == UserRole.parent || role == UserRole.student,
  };
}

String defaultRouteForRole(UserRole role) {
  return switch (role) {
    UserRole.parent => '/dashboard',
    UserRole.student => '/dashboard',
    _ => '/dashboard',
  };
}

String accessMessageForPath(String path) {
  return switch (path) {
    '/dashboard' => 'The school-wide dashboard is available to staff and parents.',
    '/fees' =>
      'Fee configuration is available to admin role.',
    '/concessions' =>
      'Concession approvals are available to admin role.',
    '/reconciliation' =>
      'Settlement reconciliation is available to admin role.',
    '/reports' =>
      'Finance reports are available to admin role.',
    '/settings' =>
      'School settings are available to admin role.',
    '/students' => 'Student information is available to parents.',
    _ => 'This role does not have access to this workspace.',
  };
}
