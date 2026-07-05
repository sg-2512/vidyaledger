# Supabase Setup

1. Create a Supabase project.
2. Open SQL Editor and run `supabase/schema.sql`.
3. Run `supabase/seed.sql` for demo data.
4. Create demo users in Supabase Auth using these emails:
   - `admin@vidyaledger.demo`
   - `principal@vidyaledger.demo`
   - `accounts@vidyaledger.demo`
   - `clerk@vidyaledger.demo`
   - `parent@vidyaledger.demo`
5. Insert matching rows in `public.users` with each auth user UUID.
6. Copy the Project URL and publishable key from Supabase.
7. Run Flutter with:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_your_key
```

The current app defaults to local demo mode. The schema and RLS are ready for the real backend connection layer.

## Current Integration Status

The Flutter app now has a Supabase data adapter in
`lib/services/supabase_finance_service.dart`.

It can read these tables and map rows into app models:

- `users`
- `guardians`
- `students`
- `fee_heads`
- `fee_rules`
- `fee_demands`
- `concessions`
- `payments`
- `reconciliation_items`
- `audit_logs`

Riverpod providers for the backend adapter live in
`lib/providers/supabase_providers.dart`.

Important: the UI still uses the seeded demo controller by default. The next
backend task is to replace screens gradually with Supabase-backed providers once
the real project URL, publishable key, Auth users, and `public.users` rows exist.

## Recommended Wiring Order

1. Create Supabase project.
2. Run `schema.sql`.
3. Create demo Auth users.
4. Insert matching `public.users` rows with the Auth UUIDs.
5. Run `seed.sql` to create demo users, students, fee rules, demands,
   concessions, payments, reconciliation rows, and the starter audit log.
6. Start Flutter with `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`.
7. Use `supabaseFinanceSnapshotProvider` to verify data loading.
8. Replace one screen at a time, starting with Students, then Dashboard, then
   Payments.
