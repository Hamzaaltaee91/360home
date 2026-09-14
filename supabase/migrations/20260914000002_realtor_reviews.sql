-- Realtor ratings & reviews.
--
-- Written by hand (not by the autonomous pilot): CONVENTIONS.md §5 forbids
-- the pilot from ever writing RLS policies or SQL functions. Buyers rate a
-- realtor once per accepted offer via submit_realtor_review(); all
-- eligibility checks (must be the offer's buyer, offer must be accepted)
-- and the realtors.average_rating recompute happen inside that single
-- SECURITY DEFINER function. Client code only ever calls these RPCs — no
-- direct INSERT/UPDATE/DELETE policy exists on realtor_reviews, by design.

-- ============================================
-- TABLE
-- ============================================

CREATE TABLE public.realtor_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  offer_id UUID NOT NULL REFERENCES public.realtor_offers(id) ON DELETE CASCADE,
  realtor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  buyer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE (offer_id, buyer_id)
);

CREATE INDEX idx_realtor_reviews_realtor_id ON public.realtor_reviews(realtor_id);
CREATE INDEX idx_realtor_reviews_buyer_id ON public.realtor_reviews(buyer_id);

ALTER TABLE public.realtor_reviews ENABLE ROW LEVEL SECURITY;

-- Reviews are public testimonials: anyone signed in can read them.
-- No INSERT/UPDATE/DELETE policy is defined on purpose — all writes go
-- through submit_realtor_review() below.
CREATE POLICY "realtor_reviews_select_all" ON public.realtor_reviews
  FOR SELECT USING (true);

-- ============================================
-- FUNCTION: submit (or edit) a review for an accepted offer
-- ============================================

CREATE OR REPLACE FUNCTION public.submit_realtor_review(
  p_offer_id UUID,
  p_rating INT,
  p_comment TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_buyer_id UUID;
  v_realtor_id UUID;
  v_request_buyer_id UUID;
  v_offer_status TEXT;
BEGIN
  v_buyer_id := public.current_user_id();

  IF v_buyer_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_rating IS NULL OR p_rating < 1 OR p_rating > 5 THEN
    RAISE EXCEPTION 'Rating must be between 1 and 5';
  END IF;

  SELECT ro.realtor_id, ro.status, pr.buyer_id
    INTO v_realtor_id, v_offer_status, v_request_buyer_id
  FROM public.realtor_offers ro
  JOIN public.property_requests pr ON pr.id = ro.request_id
  WHERE ro.id = p_offer_id;

  IF v_realtor_id IS NULL THEN
    RAISE EXCEPTION 'Offer not found';
  END IF;

  IF v_request_buyer_id <> v_buyer_id THEN
    RAISE EXCEPTION 'Only the buyer on this offer''s request may review it';
  END IF;

  IF v_offer_status <> 'accepted' THEN
    RAISE EXCEPTION 'Offer must be accepted before it can be reviewed';
  END IF;

  INSERT INTO public.realtor_reviews (offer_id, realtor_id, buyer_id, rating, comment)
  VALUES (p_offer_id, v_realtor_id, v_buyer_id, p_rating, NULLIF(btrim(COALESCE(p_comment, '')), ''))
  ON CONFLICT (offer_id, buyer_id) DO UPDATE
  SET rating = EXCLUDED.rating,
      comment = EXCLUDED.comment,
      created_at = NOW();

  UPDATE public.realtors
  SET average_rating = COALESCE(
    (SELECT ROUND(AVG(rating)::numeric, 2) FROM public.realtor_reviews WHERE realtor_id = v_realtor_id),
    0
  )
  WHERE user_id = v_realtor_id;
END;
$$;

-- ============================================
-- FUNCTION: the current user's own review for one offer (to prefill edits)
-- ============================================

CREATE OR REPLACE FUNCTION public.get_my_review_for_offer(p_offer_id UUID)
RETURNS TABLE (
  rating INT,
  comment TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT rr.rating, rr.comment
  FROM public.realtor_reviews rr
  WHERE rr.offer_id = p_offer_id
    AND rr.buyer_id = public.current_user_id();
END;
$$;

-- ============================================
-- FUNCTION: a realtor's reviews, newest first, with the buyer's name
-- (a safe, minimal join — no direct client read of public.users needed)
-- ============================================

CREATE OR REPLACE FUNCTION public.list_realtor_reviews(p_realtor_id UUID)
RETURNS TABLE (
  review_id UUID,
  buyer_name TEXT,
  rating INT,
  comment TEXT,
  created_at TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT rr.id, u.full_name, rr.rating, rr.comment, rr.created_at
  FROM public.realtor_reviews rr
  JOIN public.users u ON u.id = rr.buyer_id
  WHERE rr.realtor_id = p_realtor_id
  ORDER BY rr.created_at DESC;
END;
$$;

-- ============================================
-- FUNCTION: a realtor's rating summary (avg + count)
-- ============================================

CREATE OR REPLACE FUNCTION public.get_realtor_rating_summary(p_realtor_id UUID)
RETURNS TABLE (
  average_rating NUMERIC,
  review_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT COALESCE(ROUND(AVG(rating)::numeric, 2), 0), COUNT(*)
  FROM public.realtor_reviews
  WHERE realtor_id = p_realtor_id;
END;
$$;
