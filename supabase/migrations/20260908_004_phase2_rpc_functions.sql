-- Phase 2: RPC Functions and Triggers
-- Created: 2026-09-08

-- ============================================
-- FUNCTION: Get nearby property requests (Geospatial)
-- ============================================

CREATE OR REPLACE FUNCTION public.nearby_requests(
  lat DECIMAL,
  lng DECIMAL,
  radius_m INT
)
RETURNS TABLE (
  id UUID,
  buyer_id UUID,
  category TEXT,
  title TEXT,
  city TEXT,
  min_price DECIMAL,
  max_price DECIMAL,
  bedrooms INT,
  bathrooms INT,
  status TEXT,
  distance_m INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pr.id,
    pr.buyer_id,
    pr.category,
    pr.title,
    pr.city,
    pr.min_price,
    pr.max_price,
    pr.bedrooms,
    pr.bathrooms,
    pr.status,
    (earth_distance(ll_to_earth(pr.latitude, pr.longitude),
                    ll_to_earth(lat, lng)))::INT AS distance_m
  FROM public.property_requests pr
  WHERE pr.status = 'active'
    AND earth_distance(ll_to_earth(pr.latitude, pr.longitude),
                       ll_to_earth(lat, lng)) <= radius_m
  ORDER BY distance_m ASC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Get buyer's offer statistics
-- ============================================

CREATE OR REPLACE FUNCTION public.get_buyer_offer_stats(buyer_id_param UUID)
RETURNS TABLE (
  total_offers INT,
  accepted_offers INT,
  rejected_offers INT,
  pending_offers INT,
  response_rate DECIMAL
) AS $$
DECLARE
  v_total_offers INT;
  v_accepted INT;
  v_rejected INT;
  v_pending INT;
  v_responded INT;
BEGIN
  SELECT COUNT(*) INTO v_total_offers
  FROM public.realtor_offers
  WHERE request_id IN (
    SELECT id FROM public.property_requests WHERE buyer_id = buyer_id_param
  );

  SELECT COUNT(*) INTO v_accepted
  FROM public.realtor_offers
  WHERE buyer_response = 'interested'
    AND request_id IN (
      SELECT id FROM public.property_requests WHERE buyer_id = buyer_id_param
    );

  SELECT COUNT(*) INTO v_rejected
  FROM public.realtor_offers
  WHERE buyer_response = 'not_interested'
    AND request_id IN (
      SELECT id FROM public.property_requests WHERE buyer_id = buyer_id_param
    );

  SELECT COUNT(*) INTO v_pending
  FROM public.realtor_offers
  WHERE status = 'pending'
    AND request_id IN (
      SELECT id FROM public.property_requests WHERE buyer_id = buyer_id_param
    );

  SELECT COUNT(*) INTO v_responded
  FROM public.realtor_offers
  WHERE buyer_response IS NOT NULL
    AND request_id IN (
      SELECT id FROM public.property_requests WHERE buyer_id = buyer_id_param
    );

  v_total_offers := COALESCE(v_total_offers, 0);
  v_accepted := COALESCE(v_accepted, 0);
  v_rejected := COALESCE(v_rejected, 0);
  v_pending := COALESCE(v_pending, 0);
  v_responded := COALESCE(v_responded, 0);

  RETURN QUERY SELECT
    v_total_offers,
    v_accepted,
    v_rejected,
    v_pending,
    CASE WHEN v_total_offers = 0 THEN 0
         ELSE (v_responded::DECIMAL / v_total_offers * 100)::DECIMAL
    END;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Get realtor's performance metrics
-- ============================================

CREATE OR REPLACE FUNCTION public.get_realtor_performance(realtor_id_param UUID)
RETURNS TABLE (
  total_offers INT,
  accepted_offers INT,
  rejection_rate DECIMAL,
  average_days_to_response DECIMAL,
  total_interactions INT
) AS $$
DECLARE
  v_total INT;
  v_accepted INT;
  v_interactions INT;
  v_avg_days DECIMAL;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM public.realtor_offers
  WHERE realtor_id = realtor_id_param;

  SELECT COUNT(*) INTO v_accepted
  FROM public.realtor_offers
  WHERE realtor_id = realtor_id_param
    AND buyer_response = 'interested';

  SELECT COUNT(*) INTO v_interactions
  FROM public.offer_interactions
  WHERE realtor_id = realtor_id_param;

  -- حساب عدد الأيام المتوسط للرد
  SELECT AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 86400)::DECIMAL
  INTO v_avg_days
  FROM public.realtor_offers
  WHERE realtor_id = realtor_id_param
    AND updated_at > created_at;

  v_total := COALESCE(v_total, 0);
  v_accepted := COALESCE(v_accepted, 0);
  v_interactions := COALESCE(v_interactions, 0);
  v_avg_days := COALESCE(v_avg_days, 0);

  RETURN QUERY SELECT
    v_total,
    v_accepted,
    CASE WHEN v_total = 0 THEN 0
         ELSE ((v_total - v_accepted)::DECIMAL / v_total * 100)::DECIMAL
    END,
    v_avg_days,
    v_interactions;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Bulk update offer statuses
-- ============================================

CREATE OR REPLACE FUNCTION public.bulk_update_offer_responses(
  p_request_id UUID,
  p_responses JSONB
)
RETURNS TABLE (
  updated_count INT,
  success BOOLEAN
) AS $$
DECLARE
  v_updated INT;
BEGIN
  UPDATE public.realtor_offers ro
  SET buyer_response = p_responses ->> ro.id::TEXT
  WHERE ro.request_id = p_request_id
    AND ro.buyer_response IS NULL;

  GET DIAGNOSTICS v_updated = ROW_COUNT;

  RETURN QUERY SELECT v_updated, true;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Auto-expire old offers
-- ============================================

CREATE OR REPLACE FUNCTION public.auto_expire_offers()
RETURNS TABLE (
  expired_count INT,
  success BOOLEAN
) AS $$
DECLARE
  v_expired INT;
BEGIN
  UPDATE public.realtor_offers
  SET status = 'expired'
  WHERE status = 'pending'
    AND expires_at < NOW();

  GET DIAGNOSTICS v_expired = ROW_COUNT;

  RETURN QUERY SELECT v_expired, true;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGER: Update realtor stats on offer change
-- ============================================

CREATE OR REPLACE FUNCTION public.update_realtor_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.realtors
  SET total_offers = (
    SELECT COUNT(*) FROM public.realtor_offers WHERE realtor_id = NEW.realtor_id
  )
  WHERE user_id = NEW.realtor_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_offer_created_update_stats
  AFTER INSERT ON public.realtor_offers
  FOR EACH ROW EXECUTE FUNCTION public.update_realtor_stats();

-- ============================================
-- TRIGGER: Verify user is realtor before creating offer
-- ============================================

CREATE OR REPLACE FUNCTION public.check_realtor_verified()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.realtors
    WHERE user_id = NEW.realtor_id AND verified_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'Realtor must be verified to create offers';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_offer_insert_check_realtor
  BEFORE INSERT ON public.realtor_offers
  FOR EACH ROW EXECUTE FUNCTION public.check_realtor_verified();

-- ============================================
-- FUNCTION: Calculate match score
-- ============================================

CREATE OR REPLACE FUNCTION public.calculate_match_score(
  p_request_id UUID,
  p_offer_id UUID
)
RETURNS DECIMAL AS $$
DECLARE
  v_score DECIMAL := 50;
  v_price_match DECIMAL;
  v_area_match DECIMAL;
  v_bedroom_match BOOLEAN;
BEGIN
  -- احصل على بيانات الطلب والعرض
  WITH request_data AS (
    SELECT min_price, max_price, min_area_sqft, max_area_sqft, bedrooms, bathrooms
    FROM property_requests WHERE id = p_request_id
  ),
  offer_data AS (
    SELECT offered_price, area_sqft, bedrooms, bathrooms
    FROM realtor_offers WHERE id = p_offer_id
  )
  SELECT
    CASE WHEN rd.min_price IS NULL OR rd.max_price IS NULL THEN 1
         WHEN od.offered_price BETWEEN rd.min_price AND rd.max_price THEN 1.2
         ELSE 0.8
    END,
    CASE WHEN rd.min_area_sqft IS NULL AND rd.max_area_sqft IS NULL THEN 1
         WHEN od.area_sqft BETWEEN COALESCE(rd.min_area_sqft, 0)
                               AND COALESCE(rd.max_area_sqft, 2147483647) THEN 1.1
         ELSE 0.9
    END,
    (od.bedrooms = rd.bedrooms)
  INTO v_price_match, v_area_match, v_bedroom_match
  FROM request_data rd, offer_data od;

  v_score := v_score * v_price_match;
  v_score := v_score * v_area_match;
  IF v_bedroom_match THEN v_score := v_score * 1.1; END IF;

  RETURN ROUND(v_score, 2);
END;
$$ LANGUAGE plpgsql;
