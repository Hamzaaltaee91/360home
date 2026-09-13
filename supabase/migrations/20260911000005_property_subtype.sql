-- Add property_subtype to public.property_requests.
-- Additive only: no changes to RLS, roles, functions, or existing columns.

alter table public.property_requests
  drop constraint if exists property_requests_property_subtype_check;

alter table public.property_requests
  add column if not exists property_subtype text;

alter table public.property_requests
  add constraint property_requests_property_subtype_check
  check (
    category <> 'residential'
    or property_subtype in ('apartment', 'house', 'villa', 'duplex')
  );
