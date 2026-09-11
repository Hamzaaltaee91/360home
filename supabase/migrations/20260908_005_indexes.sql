-- Phase 2: Performance Indexes for Dabberli
-- Created: 2026-09-08
--
-- Adds composite / partial indexes for the hot query paths used by the
-- RPC functions (match_offers, search_requests, get_realtor_stats,
-- get_buyer_stats, expire_old_offers) and the RLS policies.
--
-- All statements use IF NOT EXISTS so this migration is idempotent and
-- safe to re-run against databases that already have the single-column
-- indexes created in 20260908_001_initial_schema.sql.

-- ============================================
-- USERS
-- ============================================

-- RLS helper: resolve auth.uid() -> public.users.id
CREATE INDEX IF NOT EXISTS idx_users_auth_id_role
  ON public.users(auth_id, role);

-- ============================================
-- REALTORS
-- ============================================

-- RLS: "is this user a verified realtor?" check used by
-- property_requests_select_active_for_realtor and
-- realtor_offers_insert_own.
CREATE INDEX IF NOT EXISTS idx_realtors_user_id_verified_at
  ON public.realtors(user_id, verified_at);

-- ============================================
-- PROPERTY REQUESTS
-- ============================================

-- match_offers / search_requests: filter by status + category, order by created_at.
CREATE INDEX IF NOT EXISTS idx_property_requests_status_category_created_at
  ON public.property_requests(status, category, created_at DESC);

-- search_requests: filter by status + city.
CREATE INDEX IF NOT EXISTS idx_property_requests_status_city
  ON public.property_requests(status, city);

-- Buyer dashboard: list own requests by status.
CREATE INDEX IF NOT EXISTS idx_property_requests_buyer_id_status
  ON public.property_requests(buyer_id, status);

-- search_requests: price range filtering.
CREATE INDEX IF NOT EXISTS idx_property_requests_price_range
  ON public.property_requests(min_price, max_price);

-- ============================================
-- REALTOR OFFERS
-- ============================================

-- Buyer view: offers on a request, filtered by status.
CREATE INDEX IF NOT EXISTS idx_realtor_offers_request_id_status
  ON public.realtor_offers(request_id, status);

-- Realtor dashboard: own offers by status.
CREATE INDEX IF NOT EXISTS idx_realtor_offers_realtor_id_status
  ON public.realtor_offers(realtor_id, status);

-- expire_old_offers: partial index over only the rows that can expire.
CREATE INDEX IF NOT EXISTS idx_realtor_offers_pending_expires_at
  ON public.realtor_offers(expires_at)
  WHERE status = 'pending';

-- get_buyer_offer_stats: count by buyer_response.
CREATE INDEX IF NOT EXISTS idx_realtor_offers_buyer_response_request_id
  ON public.realtor_offers(buyer_response, request_id);

-- ============================================
-- OFFER INTERACTIONS
-- ============================================

-- get_realtor_performance: interactions per realtor over time.
CREATE INDEX IF NOT EXISTS idx_offer_interactions_realtor_id_created_at
  ON public.offer_interactions(realtor_id, created_at DESC);

-- Buyer-side interaction history.
CREATE INDEX IF NOT EXISTS idx_offer_interactions_buyer_id_created_at
  ON public.offer_interactions(buyer_id, created_at DESC);

-- ============================================
-- NOTIFICATIONS
-- ============================================

-- Notification feed: unread first, newest first.
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_is_read_created_at
  ON public.notifications(user_id, is_read, created_at DESC);

-- ============================================
-- VERIFICATIONS
-- ============================================

-- Admin review queue: pending verifications, oldest first.
CREATE INDEX IF NOT EXISTS idx_verifications_status_created_at
  ON public.verifications(status, created_at);

-- ============================================
-- REALTOR VERIFICATIONS
-- ============================================

-- Admin review queue: pending realtor verifications, oldest first.
CREATE INDEX IF NOT EXISTS idx_realtor_verifications_status_created_at
  ON public.realtor_verifications(status, created_at);

-- ============================================
-- PROPERTY PHOTOS
-- ============================================

-- Ordered photo galleries per request / offer.
CREATE INDEX IF NOT EXISTS idx_property_photos_request_id_display_order
  ON public.property_photos(request_id, display_order);

CREATE INDEX IF NOT EXISTS idx_property_photos_offer_id_display_order
  ON public.property_photos(offer_id, display_order);
