-- pgTAP tests for Phase 2 RPC functions
-- Run with: supabase test db

BEGIN;

SELECT plan(8);

-- ============================================
-- Function existence checks
-- ============================================

SELECT has_function(
  'public', 'match_offers',
  ARRAY['uuid', 'text', 'integer'],
  'match_offers function exists'
);

SELECT has_function(
  'public', 'search_requests',
  ARRAY['text', 'text', 'numeric', 'numeric', 'integer', 'integer',
        'numeric', 'numeric', 'numeric', 'integer', 'integer'],
  'search_requests function exists'
);

SELECT has_function(
  'public', 'get_realtor_stats',
  ARRAY['uuid'],
  'get_realtor_stats function exists'
);

SELECT has_function(
  'public', 'get_buyer_stats',
  ARRAY['uuid'],
  'get_buyer_stats function exists'
);

-- ============================================
-- Behavioral checks
-- ============================================

-- get_buyer_stats returns a single row with zeroed stats for unknown buyer
SELECT is(
  (SELECT total_offers FROM public.get_buyer_stats(
    '00000000-0000-0000-0000-000000000000'::uuid)),
  0,
  'get_buyer_stats returns 0 total offers for unknown buyer'
);

-- get_realtor_stats returns a single row with zeroed stats for unknown realtor
SELECT is(
  (SELECT total_offers FROM public.get_realtor_stats(
    '00000000-0000-0000-0000-000000000000'::uuid)),
  0,
  'get_realtor_stats returns 0 total offers for unknown realtor'
);

-- search_requests returns no rows when no active requests exist for a city
SELECT is(
  (SELECT COUNT(*)::int FROM public.search_requests(
    p_city => '__nonexistent_city__')),
  0,
  'search_requests returns no rows for nonexistent city'
);

-- match_offers returns no rows for a nonexistent category
SELECT is(
  (SELECT COUNT(*)::int FROM public.match_offers(
    p_realtor_id => '00000000-0000-0000-0000-000000000000'::uuid,
    p_category => '__nonexistent_category__')),
  0,
  'match_offers returns no rows for nonexistent category'
);

SELECT * FROM finish();

ROLLBACK;
