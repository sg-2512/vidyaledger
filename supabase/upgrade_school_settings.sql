alter table schools
  add column if not exists address text not null default '',
  add column if not exists contact_email text not null default '',
  add column if not exists contact_phone text not null default '',
  add column if not exists logo_url text not null default '';

create table if not exists class_sections (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  class_name text not null,
  section text not null,
  class_teacher text not null default '',
  room_label text not null default '',
  capacity integer not null default 45 check (capacity > 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (school_id, class_name, section)
);

insert into class_sections (
  school_id,
  class_name,
  section,
  class_teacher,
  room_label,
  capacity,
  active
)
select distinct
  school_id,
  class_name,
  section,
  'Class ' || class_name || '-' || section || ' Teacher',
  'Room ' || class_name || section,
  45,
  true
from students
where class_name is not null
  and section is not null
on conflict (school_id, class_name, section) do update set
  active = true;

alter table class_sections enable row level security;

drop policy if exists "setup roles can update own school" on schools;
create policy "setup roles can update own school"
on schools for update
using (id = current_user_school_id() and current_user_role() in ('admin', 'principal'))
with check (id = current_user_school_id() and current_user_role() in ('admin', 'principal'));

drop policy if exists "school members can read class sections" on class_sections;
create policy "school members can read class sections"
on class_sections for select
using (school_id = current_user_school_id());

drop policy if exists "setup roles can manage class sections" on class_sections;
create policy "setup roles can manage class sections"
on class_sections for all
using (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal'))
with check (school_id = current_user_school_id() and current_user_role() in ('admin', 'principal'));

select
  'school_settings_upgrade_ready' as status,
  (select count(*) from class_sections) as class_section_count;
