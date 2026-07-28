# VidyaLedger Final Submission Draft

Use this as the working draft while filling the Unstop submission form for the Smart School FinTech Innovation Challenge 2026.

Important date check: today is July 28, 2026. Earlier challenge material showed Round 2 final submission as July 21-23, 2026, so first confirm that the Unstop portal still accepts your submission or that you have an extension.

## Final Assets

- Project name: VidyaLedger
- Team name: Neophytes
- Team members: Sanchit Gupta, Rishabh Chaudhary
- GitHub repository: https://github.com/sg-2512/vidyaledger
- Last verified app-code commit before this submission draft: `9964ab5 Add student reminders and installment workflows`
- Recommended PPT upload: `outputs/vidyaledger-paperbuddy-pitch-v3.pptx`
- Backup PDF deck: `outputs/vidyaledger-paperbuddy-pitch-v3.pdf`
- Demo video URL: `[PASTE UNLISTED YOUTUBE / DRIVE LINK HERE]`
- Live demo URL: `[PASTE DEPLOYED URL HERE, OR WRITE "Not deployed; local setup provided in README"]`
- Documentation: `README.md`, `docs/supabase-setup.md`, `docs/payment-gateway-architecture.md`, `docs/demo-script.md`, `docs/deployment.md`

## Submission Checklist

1. Open GitHub repo and confirm the latest commit is visible on `main`.
2. Upload the PPT file: `outputs/vidyaledger-paperbuddy-pitch-v3.pptx`.
3. Record a 3-5 minute demo video using the script below.
4. Upload the demo video as Unlisted on YouTube or Drive with link access enabled.
5. If possible, deploy the Flutter web build and paste the live URL.
6. Paste the GitHub repo link.
7. Paste the project description and technical overview from this document.
8. Submit only original work; do not include real student personal data.

## Copy-Paste Project Summary

VidyaLedger is a Smart School FinTech OS for Indian educational institutions. It replaces scattered spreadsheets, manual receipts, disconnected fee collection, cheque follow-ups, concession paperwork, and bank reconciliation effort with one auditable digital finance workspace. The prototype supports dynamic fee creation, student onboarding, RTE/EWS/SC/ST-style concession workflows, UPI and hosted payment request links, cash/cheque/bank collection, receipt generation, settlement reconciliation, installment plans, parent reminders, role-based dashboards, PDF reports, and Supabase-backed multi-tenant data control.

## Problem Statement

Indian schools often manage fee collections through disconnected tools: spreadsheets for demand registers, paper receipts for counter payments, separate UPI screenshots, manual cheque follow-up, WhatsApp reminders, and delayed bank reconciliation. This creates leakage, slow reporting, poor parent experience, and weak audit trails. Administrators need a production-oriented finance system that can support online and offline payment workflows while staying practical for Indian school accounting operations.

## Proposed Solution

VidyaLedger provides one integrated platform for school fee setup, demand generation, student finance profiles, concessions, payment collection, payment requests, reminders, receipts, cheque lifecycle tracking, and reconciliation. Staff can configure fee heads, add students individually or through CSV import, generate fee demand, approve concessions, create UPI/gateway requests, record payments, print receipts, import settlement CSVs, and monitor defaulters. Parents and students see a simplified fee view with pending amount, receipt history, and payment links.

## Key Features

- Dynamic fee engine for tuition, transport, late fees, and custom heads.
- Student master register with class, section, category, guardian, and CSV import workflows.
- Indian-school concession handling for categories such as RTE, EWS, SC/ST, merit, and need-based support.
- UPI intent and hosted gateway request architecture for Razorpay, Cashfree, PhonePe, PayU, and provider-neutral expansion.
- Counter collection for UPI, cash, cheque, and bank transfer.
- Cheque lifecycle: received, deposited, cleared, bounced, with ledger and reconciliation impact.
- Settlement CSV import for bank/gateway reconciliation with matched, partial, duplicate, and overpaid decisions.
- Installment/EMI fee plans for parents who need structured payment schedules.
- WhatsApp/SMS reminder drafting and reminder audit log.
- PDF receipts, student register export, and collection reports.
- Role-based access for admin, parent, and student workspaces.
- Supabase/PostgreSQL schema with RLS, RPCs, audit logs, and seeded demo data.

## Technology Stack

- Frontend: Flutter Web, Dart
- State management: Riverpod
- Routing: GoRouter
- Backend: Supabase, PostgreSQL, Row Level Security
- Reports: PDF and Printing packages
- Formatting: Intl for Indian currency and date presentation
- Deployment target: Flutter Web build, deployable to Netlify, Vercel, or GitHub Pages

## Architecture Overview

The app uses a Flutter Web UI with Riverpod providers for computed finance state and workflow state. In demo mode, seeded Riverpod state powers the full prototype without credentials. In Supabase mode, the app loads tenant data from PostgreSQL tables protected by RLS policies. Critical finance actions are exposed as RPC workflows so receipt numbers, ledger entries, reconciliation records, cheque updates, payment requests, and audit logs can be posted consistently.

Core modules:

- `lib/models`: domain models for students, guardians, fee demands, payments, reminders, installments, and reconciliation.
- `lib/providers`: app state, finance summaries, and Supabase-backed loading.
- `lib/screens`: dashboards, student register, student profile, fee engine, concessions, payments, reconciliation, reports, and settings.
- `lib/widgets`: shared dialogs and UI components for reminders, installments, charts, gates, and common cards.
- `supabase`: schema, seed data, and upgrade SQL files.
- `docs`: setup, demo, deployment, payment architecture, and troubleshooting.

## APIs And Integrations

- Supabase Auth for signed-in user identity.
- Supabase PostgreSQL for school finance data.
- Supabase RPCs for production-style finance actions:
  - `record_payment_with_receipt`
  - `generate_fee_demands_for_class`
  - `submit_concession_request`
  - `update_concession_decision`
  - `update_reconciliation_status`
  - `update_cheque_status_with_ledger`
  - `create_payment_request`
  - `create_student_with_guardian`
- UPI intent URI support for zero-cost payment request demos.
- Hosted checkout placeholder architecture for Razorpay, Cashfree, PhonePe, and PayU.

## Indian Accounting And Compliance Positioning

VidyaLedger is designed around Indian school finance workflows: fee heads, concessions, receipt numbers, UPI, cheque clearing, bank transfer reconciliation, class-section registers, guardian communication, and category-aware reporting. The prototype avoids storing real student data in the demo and keeps payment, ledger, reconciliation, and audit records separated. State-specific fee regulations, data protection requirements, tax treatment, and payment-gateway production onboarding must be legally verified before real deployment.

## Business Impact

- Reduces manual fee register and receipt workload.
- Gives administrators real-time pending, collected, concession, and defaulter visibility.
- Improves parent experience through payment links, reminders, installments, and receipts.
- Reduces reconciliation errors by matching bank/gateway settlement CSVs against internal receipts.
- Improves auditability through immutable-style logs and role-based access.
- Creates a scalable foundation for school ERP, payment gateway, and accounting integrations.

## PPT Slide Draft

Use the existing deck if it already matches this structure. Otherwise, update it to this story:

1. Title: VidyaLedger - Smart School FinTech OS
2. Problem: School fee operations are fragmented across paper, spreadsheets, UPI screenshots, and bank statements.
3. User Pain: Admins, accountants, parents, and students all face different friction.
4. Solution: One finance cockpit for fee demand, collection, reminders, receipts, and reconciliation.
5. Product Demo Flow: Dashboard -> Student Register -> Fee Engine -> Payments -> Reconciliation -> Reports.
6. Key Features: Dynamic fee engine, concessions, UPI/gateway requests, CSV import, cheque lifecycle, settlement import, installments.
7. Architecture: Flutter Web + Riverpod + Supabase + PostgreSQL RLS + RPC workflows.
8. Indian Market Fit: UPI, cheque, RTE/EWS/SC/ST concessions, class-section registers, parent reminders, receipt audit trails.
9. Technical Excellence: Clean domain models, provider-driven state, test coverage, SQL upgrades, role gates, deployable web build.
10. Business Impact: Faster collections, fewer reconciliation errors, better parent experience, audit-ready reporting.
11. Future Scope: Real gateway webhooks, WhatsApp Business API, Tally/ERP export, AI anomaly detection, mobile app, multi-school SaaS.
12. Closing: VidyaLedger turns school fee management into one measurable, auditable, parent-friendly finance system.

## 3-5 Minute Demo Video Script

Target length: 4 minutes.

0:00-0:20 - Opening
Say: "Hi, we are Team Neophytes. Our project is VidyaLedger, a Smart School FinTech OS for Indian schools. It solves fragmented fee management, manual receipts, UPI follow-up, cheque tracking, concessions, and reconciliation."

0:20-0:50 - Problem And Dashboard
Show dashboard. Say: "Schools need to know total demand, collected amount, pending amount, concessions, and defaulters in real time. VidyaLedger gives admins a live finance cockpit."

0:50-1:25 - Student Register And CSV Import
Open Students. Show filters and Import CSV preview. Say: "Instead of manual spreadsheet registers, staff can manage class-section data, guardian details, pending balances, and bulk import students."

1:25-1:55 - Fee Engine And Concessions
Open Fee Engine and Concessions. Say: "The dynamic fee engine supports tuition, transport, late fees, and custom heads. Concession workflows support Indian school categories like EWS, RTE, SC/ST, merit, and need-based assistance."

1:55-2:35 - Payment Collection And Payment Requests
Open Payments. Create or show a UPI/gateway request. Copy reminder. Say: "Staff can record UPI, cash, cheque, or bank transfer payments, generate receipt numbers, and create UPI intent or hosted checkout requests. Parent-ready reminders can be copied for WhatsApp or SMS."

2:35-3:05 - Cheque And Reconciliation
Show cheque status and Reconciliation settlement CSV import. Say: "Offline workflows matter in India. VidyaLedger tracks cheque received, deposited, cleared, or bounced, and settlement CSV rows can be imported to mark receipts matched, partial, duplicate, or overpaid."

3:05-3:30 - Parent/Student View
Switch to parent/student workspace. Say: "Parents and students get a simplified experience with fee status, pending amount, receipt history, and payment visibility."

3:30-3:50 - Technical Architecture
Say: "The prototype is built with Flutter Web, Riverpod, GoRouter, Supabase, PostgreSQL RLS, RPC finance workflows, PDF reports, and seeded demo data."

3:50-4:00 - Closing
Say: "VidyaLedger helps Indian schools move from fragmented fee operations to one auditable, scalable, and parent-friendly finance system."

## YouTube / Drive Demo Video Draft

Title:
VidyaLedger - Smart School FinTech Innovation Challenge 2026 Demo

Description:
VidyaLedger by Team Neophytes is a Flutter Web and Supabase-based Smart School FinTech OS for Indian schools. It supports fee demand generation, student CSV onboarding, concessions, UPI/gateway payment requests, counter collections, cheque lifecycle tracking, settlement reconciliation, parent reminders, installment plans, PDF receipts, and finance dashboards.

GitHub: https://github.com/sg-2512/vidyaledger

## Unstop Form Copy

Project Title:
VidyaLedger - Smart School FinTech OS

Short Description:
VidyaLedger is a Flutter Web and Supabase-based school finance platform that digitizes fee setup, student registers, concessions, UPI/gateway payment requests, receipts, cheque tracking, reminders, installments, settlement reconciliation, and reports for Indian educational institutions.

Problem Solved:
Schools still rely on spreadsheets, paper receipts, UPI screenshots, manual reminders, cheque registers, and delayed bank reconciliation. VidyaLedger unifies these workflows into one auditable platform for administrators, parents, and students.

Innovation:
The solution combines school fee operations and fintech workflows in one product: dynamic fee engine, UPI intent links, hosted gateway abstraction, concession approvals, settlement CSV reconciliation, cheque lifecycle accounting, parent reminders, installment plans, and role-specific dashboards.

Technical Overview:
Built using Flutter Web, Riverpod, GoRouter, Supabase Auth, PostgreSQL, RLS policies, RPC-based finance workflows, PDF generation, and seeded Indian-school demo data. It supports demo mode without credentials and Supabase-backed mode for persistent multi-tenant workflows.

Repository:
https://github.com/sg-2512/vidyaledger

Live Demo:
[PASTE LIVE URL OR WRITE "Not deployed; local setup provided in README"]

Demo Video:
[PASTE VIDEO LINK]

## Final Local Verification Commands

Run these before recording the video or submitting:

```powershell
cd "C:\Users\Sanchit Gupta\PaperBuddy_Hackathon\vidyaledger"
git status -sb
flutter analyze
flutter test
flutter build web --release --no-tree-shake-icons
```

Expected result:

- `flutter analyze`: no issues
- `flutter test`: all tests passed
- `flutter build web --release --no-tree-shake-icons`: built `build\web`

## How To Submit On Unstop

1. Open the challenge page.
2. Click `View Details` or the active submission button for your registered team.
3. Fill project title and description using the copy above.
4. Upload the PPT from `outputs/vidyaledger-paperbuddy-pitch-v3.pptx`.
5. Paste the GitHub repository URL.
6. Paste the demo video URL.
7. Paste the live demo URL if deployed.
8. If there is a documentation field, paste the GitHub repo README link or mention:
   `Documentation is included in README.md and docs/ folder.`
9. Submit and take a screenshot of the confirmation page.

## What Not To Upload

- Do not upload real student data.
- Do not upload `.env.local`.
- Do not upload Supabase secret keys.
- Do not upload generated helper scripts unless the form specifically asks for them.
- Do not claim full legal compliance; say the prototype is designed for Indian workflows and requires legal/payment verification before production use.
