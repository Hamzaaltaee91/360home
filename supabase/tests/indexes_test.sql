-- Test: verify the performance indexes from 20260908_005_indexes.sql exist.
-- Run with: supabase db test  (or psql -f supabase/tests/indexes_test.sql)
--
-- Each assertion raises an exception if the expected index is missing,
-- so a clean run means all indexes were created successfully.

DO $$
DECLARE
  expected_indexes TEXT[] := ARRAY[
    'idx_users_auth_id_role',
    'idx_realtors_user_id_verified_at',
    'idx_property_requests_status_category_created_at',
    'idx_property_requests_status_city',
    'idx_property_requests_buyer_id_status',
    'idx_property_requests_price_range',
    'idx_realtor_offers_request_id_status',
    'idx_realtor_offers_realtor_id_status',
    'idx_realtor_offers_pending_expires_at',
    'idx_realtor_offers_buyer_response_request_id',
    'idx_offer_interactions_realtor_id_created_at',
    'idx_offer_interactions_buyer_id_created_at',
    'idx_notifications_user_id_is_read_created_at',
    'idx_verifications_status_created_at',
    'idx_realtor_verifications_status_created_at',
    'idx_property_photos_request_id_display_order',
    'idx_property_photos_offer_id_display_order'
  ];
  idx TEXT;
  found BOOLEAN;
BEGIN
  FOR idx IN SELECT unnest(expected_indexes) LOOP
    SELECT EXISTS (
      SELECT 1
      FROM pg_indexes
      WHERE schemaname = 'public'
        AND indexname = idx
    ) INTO found;

    IF NOT found THEN
      RAISE EXCEPTION 'Missing expected index: %', idx;
    END IF;
  END LOOP;

  RAISE NOTICE 'All % expected indexes are present.', array_length(expected_indexes, 1);
END;
$$;
