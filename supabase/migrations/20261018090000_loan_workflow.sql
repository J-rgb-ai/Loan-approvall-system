-- ClearPath loan application workflow schema. Apply once to a fresh Supabase project.
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(full_name) between 1 and 120),
  role text not null default 'applicant' check (role in ('applicant','reviewer')),
  created_at timestamptz not null default now()
);
create table public.loan_applications (
  id uuid primary key default gen_random_uuid(),
  applicant_id uuid not null references auth.users(id) on delete cascade,
  applicant_name text not null check (char_length(applicant_name) between 1 and 120),
  email text not null,
  phone text not null,
  employment_status text not null check (employment_status in ('employed','self_employed','unemployed','student','other')),
  monthly_income numeric(12,2) not null check (monthly_income >= 0),
  requested_amount numeric(12,2) not null check (requested_amount > 0),
  loan_purpose text not null check (char_length(loan_purpose) between 5 and 1000),
  repayment_months integer not null check (repayment_months between 1 and 120),
  status text not null default 'submitted' check (status in ('submitted','under_review','approved','rejected','withdrawn')),
  reviewer_notes text,
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.application_events (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.loan_applications(id) on delete cascade,
  actor_id uuid not null references auth.users(id),
  event_type text not null check (event_type in ('submitted','status_changed','note_added','withdrawn')),
  previous_status text,
  new_status text,
  note text,
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
alter table public.loan_applications enable row level security;
alter table public.application_events enable row level security;
create policy "Applicants can view own profile and reviewers can view profiles" on public.profiles for select to authenticated using (id=(select auth.uid()) or (select auth.jwt()->'app_metadata'->>'role')='reviewer');
create policy "Users create own applicant profile" on public.profiles for insert to authenticated with check (id=(select auth.uid()) and role='applicant');
create policy "Users update own applicant profile" on public.profiles for update to authenticated using (id=(select auth.uid()) and role='applicant') with check (id=(select auth.uid()) and role='applicant');
create policy "Applicants view own applications; reviewers view all" on public.loan_applications for select to authenticated using (applicant_id=(select auth.uid()) or (select auth.jwt()->'app_metadata'->>'role')='reviewer');
create policy "Applicants submit own applications" on public.loan_applications for insert to authenticated with check (applicant_id=(select auth.uid()) and status='submitted');
create policy "Applicants withdraw or reviewers update applications" on public.loan_applications for update to authenticated
using ((applicant_id=(select auth.uid()) and status in ('submitted','under_review')) or (select auth.jwt()->'app_metadata'->>'role')='reviewer')
with check ((applicant_id=(select auth.uid()) and status='withdrawn') or (select auth.jwt()->'app_metadata'->>'role')='reviewer');
create or replace function public.guard_loan_application_update()
returns trigger language plpgsql set search_path=public,pg_temp as $
begin
  if (select auth.jwt()->'app_metadata'->>'role')='reviewer' then return new; end if;
  if old.applicant_id is distinct from (select auth.uid())
    or old.status not in ('submitted','under_review') or new.status <> 'withdrawn'
    or new.applicant_id is distinct from old.applicant_id
    or new.applicant_name is distinct from old.applicant_name
    or new.email is distinct from old.email or new.phone is distinct from old.phone
    or new.employment_status is distinct from old.employment_status
    or new.monthly_income is distinct from old.monthly_income
    or new.requested_amount is distinct from old.requested_amount
    or new.loan_purpose is distinct from old.loan_purpose
    or new.repayment_months is distinct from old.repayment_months
    or new.reviewer_notes is distinct from old.reviewer_notes
    or new.reviewed_by is distinct from old.reviewed_by
    or new.reviewed_at is distinct from old.reviewed_at
    or new.created_at is distinct from old.created_at then
    raise exception 'Applicants may only withdraw their own open applications.' using errcode='42501';
  end if;
  return new;
end;
$;
revoke all on function public.guard_loan_application_update() from public,anon,authenticated;
create trigger guard_loan_application_update before update on public.loan_applications
for each row execute function public.guard_loan_application_update();
create policy "Applicants view own events; reviewers view all" on public.application_events for select to authenticated using (exists (select 1 from public.loan_applications a where a.id=application_events.application_id and (a.applicant_id=(select auth.uid()) or (select auth.jwt()->'app_metadata'->>'role')='reviewer')));
create policy "Actors add valid application events" on public.application_events for insert to authenticated with check (
 actor_id=(select auth.uid()) and (
  ((select auth.jwt()->'app_metadata'->>'role')='reviewer' and event_type in ('status_changed','note_added') and exists (select 1 from public.loan_applications a where a.id=application_events.application_id))
  or
  (coalesce((select auth.jwt()->'app_metadata'->>'role'),'applicant')<>'reviewer' and event_type in ('submitted','withdrawn') and exists (select 1 from public.loan_applications a where a.id=application_events.application_id and a.applicant_id=(select auth.uid())))
 )
);
grant select,insert,update on public.profiles,public.loan_applications to authenticated;
grant select,insert on public.application_events to authenticated;
create index loan_applications_applicant_id_created_at_idx on public.loan_applications(applicant_id,created_at desc);
create index loan_applications_reviewed_by_idx on public.loan_applications(reviewed_by);
create index application_events_application_id_created_at_idx on public.application_events(application_id,created_at desc);
create index application_events_actor_id_idx on public.application_events(actor_id);
