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
