-- pgTAP tests for PostGIS migration (20260908_005_postgis.sql)
-- Run with: supabase test db

BEGIN;

SELECT plan(6);

-- 1. PostGIS extension is installed
SELECT has_extension('postgis', 'PostGIS extension should be installed');

-- 2. earthdistance extension is installed
SELECT has_extension('earthdistance', 'earthdistance extension should be installed');

-- 3. location column exists on property_requests
SELECT has_column(
  'public', 'property_requests', 'location',
  'property_requests should have a location column'
);

-- 4. GiST index exists
SELECT has_index(
  'public', 'property_requests', 'idx_property_requests_location',
  'property_requests should have a GiST index on location'
);

-- 5. sync trigger exists
SELECT has_trigger(
  'public', 'property_requests', 'on_property_request_location_sync',
  'property_requests should have a location sync trigger'
);

-- 6. nearby_requests_postgis function exists
SELECT has_function(
  'public', 'nearby_requests_postgis', ARRAY['numeric', 'numeric', 'integer'],
  'nearby_requests_postgis function should exist'
);

SELECT * FROM finish();

ROLLBACK;
