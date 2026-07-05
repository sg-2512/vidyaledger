import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/supabase_bootstrap.dart';
import '../services/supabase_finance_service.dart';

final supabaseFinanceServiceProvider = Provider<SupabaseFinanceService?>((ref) {
  if (!SupabaseBootstrap.isConfigured) return null;
  return SupabaseFinanceService();
});

final supabaseFinanceSnapshotProvider =
    FutureProvider<FinanceSnapshot?>((ref) async {
  final service = ref.watch(supabaseFinanceServiceProvider);
  if (service == null) return null;
  return service.loadSnapshot();
});
