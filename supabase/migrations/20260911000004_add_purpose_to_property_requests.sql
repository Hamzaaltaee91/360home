-- Add purpose to property_requests
--
-- Distinguishes rent from buy requests. Additive migration; does not modify
-- any previously applied migration. Existing rows are backfilled to 'rent'
-- before the NOT NULL constraint is applied, and no DB-level default is set
-- going forward.

alter table public.property_requests
  add column if not exists purpose text;

update public.property_requests
  set purpose = 'rent'
  where purpose is null;

alter table public.property_requests
  alter column purpose set not null;

alter table public.property_requests
  drop constraint if exists property_requests_purpose_check;

alter table public.property_requests
  add constraint property_requests_purpose_check
  check (purpose in ('rent', 'buy'));
