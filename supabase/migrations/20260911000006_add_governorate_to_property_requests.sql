-- Migration: add `governorate` to public.property_requests.
-- Stores an Iraq governorate as a lowercase English slug
-- (e.g. 'baghdad', 'basra', 'nineveh') - never Arabic text.
-- The existing `city` column is intentionally left untouched.

alter table public.property_requests
  add column governorate text;

comment on column public.property_requests.governorate is
  'Iraq governorate slug: baghdad, basra, nineveh, erbil, sulaymaniyah, duhok, kirkuk, anbar, babil, karbala, najaf, diyala, wasit, maysan, dhi_qar, muthanna, qadisiyyah, saladin';

alter table public.property_requests
  add constraint property_requests_governorate_check
  check (
    governorate is null
    or governorate in (
      'baghdad', 'basra', 'nineveh', 'erbil', 'sulaymaniyah', 'duhok',
      'kirkuk', 'anbar', 'babil', 'karbala', 'najaf', 'diyala', 'wasit',
      'maysan', 'dhi_qar', 'muthanna', 'qadisiyyah', 'saladin'
    )
  );
