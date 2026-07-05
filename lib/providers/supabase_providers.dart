import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/supabase_bootstrap.dart';
import '../services/supabase_finance_service.dart';
import 'app_state.dart';

final supabaseFinanceServiceProvider = Provider<SupabaseFinanceService?>((ref) {
  if (!SupabaseBootstrap.isConfigured) return null;
  return SupabaseFinanceService();
});

final supabaseFinanceSnapshotProvider = FutureProvider<FinanceSnapshot?>((
  ref,
) async {
  final service = ref.watch(supabaseFinanceServiceProvider);
  if (service == null) return null;
  return service.loadSnapshot();
});

Future<AppUser?> refreshAppStateFromSupabase(
  WidgetRef ref, {
  AppUser? currentUser,
}) async {
  final service = ref.read(supabaseFinanceServiceProvider);
  if (service == null) return null;

  final user = currentUser ?? await service.loadCurrentAppUser();
  final snapshot = await service.loadSnapshot();
  ref
      .read(appControllerProvider.notifier)
      .replaceState(snapshot.toAppState(currentUser: user));
  return user;
}
