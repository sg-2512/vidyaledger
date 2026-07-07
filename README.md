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

For local Supabase mode on Windows, copy `.env.local.example` to
`.env.local`, add your project values, then run:

```powershell
.\scripts\run-local.ps1
```

If Chrome debug connection is flaky, force a fresh local port:

```powershell
.\scripts\run-local.ps1 -WebPort 59183
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

For a larger judge/demo database, run this optional file after the base seed:

```text
supabase/seed_verification_data.sql
```

It expands the dataset to at least 50 students and adds extra fee demands,
concessions, payments, receipts, reconciliation rows, ledger entries, and an
audit log entry. The final query returns row counts so you can verify the load
inside Supabase SQL Editor.

For existing Supabase projects, also run:

```text
supabase/upgrade_receipt_numbering.sql
supabase/upgrade_fee_generation.sql
supabase/upgrade_concession_workflow.sql
supabase/upgrade_reconciliation_workflow.sql
supabase/upgrade_student_register.sql
```

This adds database-issued receipt numbers, payment idempotency keys, atomic
receipt creation, persisted fee generation, concession approvals,
reconciliation rows, ledger posting, and audit logs for new payments, fee
demands, concessions, reconciliation decisions, and student-register additions
recorded from the app.

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

Role access is enforced in the Flutter UI:

- Admin, principal, and accountant can use finance configuration, concessions, reconciliation, and reports.
- Fee clerk can use student lookup and payment collection.
- Parent can only view linked student fee details and receipts.

The student register supports class, section, and category filters, complete
student-detail PDF export, and staff-only student creation inside the signed-in
school tenant.

In Supabase mode, the app also loads the signed-in school's profile from the
`schools` table and uses it in the workspace header and exported PDFs, so each
school sees its own name, board, location, and academic year.

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
