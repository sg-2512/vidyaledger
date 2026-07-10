# Supabase Troubleshooting

## `type "user_role" already exists`

This means `supabase/schema.sql` has already been run in this Supabase
database. The base schema creates enum types, tables, functions, and policies;
it is not intended to be run repeatedly on the same project.

Do not keep rerunning the full schema file after this error.

## Check Whether The Base Schema Exists

Run:

```sql
select
  to_regtype('public.user_role') as user_role_type,
  to_regclass('public.schools') as schools_table,
  to_regclass('public.payments') as payments_table,
  to_regclass('public.payment_requests') as payment_requests_table;
```

If `schools_table` and `payments_table` are not null, the base schema exists.

## Correct Run Order

For a fresh Supabase project:

```text
1. supabase/schema.sql
2. supabase/seed.sql
3. Optional: supabase/seed_verification_data.sql
```

For a project where the base schema already exists:

```text
1. supabase/seed.sql, if demo data is missing
2. supabase/upgrade_receipt_numbering.sql
3. supabase/upgrade_fee_generation.sql
4. supabase/upgrade_concession_workflow.sql
5. supabase/upgrade_reconciliation_workflow.sql
6. supabase/upgrade_cheque_lifecycle.sql
7. supabase/upgrade_payment_requests.sql
8. supabase/upgrade_student_register.sql
9. supabase/upgrade_school_settings.sql
```

## If You Want A Clean Restart

Only do this in a disposable hackathon/demo Supabase project. It deletes all
public schema data and objects:

```sql
drop schema public cascade;
create schema public;
grant usage on schema public to postgres, anon, authenticated, service_role;
grant all on schema public to postgres, service_role;
alter default privileges in schema public
  grant all on tables to postgres, service_role;
alter default privileges in schema public
  grant all on functions to postgres, service_role;
alter default privileges in schema public
  grant all on sequences to postgres, service_role;
```

After that, rerun `supabase/schema.sql` and `supabase/seed.sql`.
