# VidyaLedger

VidyaLedger is a Flutter Web hackathon prototype for Indian school fee and finance management. It covers dynamic fee creation, concessions for categories such as RTE/EWS/SC/ST, payment recording, cheque tracking, reconciliation, dashboards, PDF receipts, and reports.

## Tech Stack

- Flutter Web and Dart
- Riverpod for app state
- GoRouter for navigation
- Supabase/PostgreSQL schema and RLS for backend
- PDF and Printing packages for receipts/reports
- Intl for Indian currency/date formatting

## Current Status

This repository contains a working Flutter Web app with demo-mode fallback and Supabase-backed login/data loading when credentials are provided at build time.

## Architecture Status

- Demo state: Riverpod `NotifierProvider` with seeded Indian-school finance data when Supabase keys are absent.
- Computed finance state: focused Riverpod providers for dashboard stats, visible students, concessions, payment-mode totals, and student finance summaries.
- Backend foundation: Supabase/PostgreSQL schema, seed data, Auth-backed login, backend snapshot loading, payment recording, cheque status updates, receipt rows, and audit-log inserts.
- Pending production work: real payment gateway callbacks, document storage for generated PDFs, SMS/WhatsApp messaging, Tally export, and stronger operational dashboards.

## Setup

Install Flutter, then run:

```bash
flutter pub get
flutter run -d chrome
```

To initialize a standard Flutter platform scaffold if needed:

```bash
flutter create . --platforms=web
flutter pub get
flutter run -d chrome
```

## Supabase

Run the SQL files in this order:

```text
supabase/schema.sql
supabase/seed.sql
```

Then start with credentials:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_your_key
```

## Demo Accounts

In demo mode, use the role buttons on the login screen. In Supabase mode, use the Auth users created in Supabase:

- `admin@vidyaledger.demo`
- `principal@vidyaledger.demo`
- `accounts@vidyaledger.demo`
- `clerk@vidyaledger.demo`
- `parent@vidyaledger.demo`

## Core Demo Flow

1. Login as Admin.
2. Open Dashboard.
3. View a student finance profile.
4. Generate a fee demand.
5. Submit and approve a concession.
6. Record a UPI/cash/cheque payment.
7. Generate receipt PDF.
8. Reconcile a payment.
9. Download collection report.

## Notes

- Do not use real student personal data in the hackathon demo.
- State-specific fee laws and category rules must be verified before real deployment.
- Real payment gateway, SMS/WhatsApp sending, and Tally integration are intentionally out of MVP scope.
