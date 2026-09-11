-- Schema verification test for 20260908_001_initial_schema.sql
-- Verifies that all required tables exist.
-- Run with: supabase test db

BEGIN;

DO $$
DECLARE
  required_tables TEXT[] := ARRAY[
    'users',
    'property_requests',
    'realtor_offers',
    'notifications',
    'realtor_verifications',
    'property_photos'
  ];
  tbl TEXT;
  missing TEXT[] := '{}';
BEGIN
  FOREACH tbl IN ARRAY required_tables LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name = tbl
    ) THEN
      missing := array_append(missing, tbl);
    END IF;
  END LOOP;

  IF array_length(missing, 1) > 0 THEN
    RAISE EXCEPTION 'Missing required tables: %', array_to_string(missing, ', ');
  END IF;

  RAISE NOTICE 'All required tables exist.';
END $$;

ROLLBACK;
