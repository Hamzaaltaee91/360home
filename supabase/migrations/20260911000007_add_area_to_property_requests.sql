-- Adds a nullable `area` TEXT column to public.property_requests.
-- Holds the selected sub-area within a governorate, or free text when the
-- user picks "أخرى". The existing `area_name` column is left untouched.
--
-- Scope: schema change only. No RLS policies, no SQL functions, no role or
-- permission changes are made by this migration.

alter table public.property_requests
  add column if not exists area text;
