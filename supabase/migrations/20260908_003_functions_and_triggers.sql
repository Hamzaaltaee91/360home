-- Phase 1: Functions and Triggers for Dabberli
-- Created: 2026-09-08

-- ============================================
-- FUNCTION: Auto-create user profile on signup
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_role TEXT;
BEGIN
  v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'buyer');
  IF v_role NOT IN ('buyer', 'realtor', 'admin') THEN
    v_role := 'buyer';
  END IF;

  INSERT INTO public.users (auth_id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    v_role
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger: Create user profile when auth user is created
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- FUNCTION: Auto-log offer interactions
-- ============================================

CREATE OR REPLACE FUNCTION public.log_offer_interaction()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status != OLD.status OR NEW.buyer_response IS DISTINCT FROM OLD.buyer_response THEN
    INSERT INTO public.offer_interactions (
      offer_id,
      buyer_id,
      realtor_id,
      interaction_type,
      message_content
    )
    VALUES (
      NEW.id,
      (SELECT buyer_id FROM public.property_requests WHERE id = NEW.request_id),
      NEW.realtor_id,
      CASE
        WHEN NEW.status = 'accepted' THEN 'call_request'
        WHEN NEW.buyer_response = 'interested' THEN 'message'
        WHEN NEW.buyer_response = 'not_interested' THEN 'message'
        ELSE 'view'
      END,
      COALESCE(NEW.message_to_buyer, '')
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger: Log offer interactions on update
CREATE TRIGGER on_offer_update_log_interaction
  AFTER UPDATE ON public.realtor_offers
  FOR EACH ROW EXECUTE FUNCTION public.log_offer_interaction();

-- ============================================
-- FUNCTION: Update user timestamps
-- ============================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update users.updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger: Update realtors.updated_at
CREATE TRIGGER update_realtors_updated_at
  BEFORE UPDATE ON public.realtors
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger: Update property_requests.updated_at
CREATE TRIGGER update_property_requests_updated_at
  BEFORE UPDATE ON public.property_requests
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger: Update realtor_offers.updated_at
CREATE TRIGGER update_realtor_offers_updated_at
  BEFORE UPDATE ON public.realtor_offers
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- FUNCTION: Get user by auth ID
-- ============================================

CREATE OR REPLACE FUNCTION public.get_current_user()
RETURNS TABLE (
  id UUID,
  email TEXT,
  full_name TEXT,
  role TEXT,
  is_verified BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    users.id,
    users.email,
    users.full_name,
    users.role,
    users.is_verified
  FROM public.users
  WHERE auth_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================
-- FUNCTION: Count verified realtors
-- ============================================

CREATE OR REPLACE FUNCTION public.count_verified_realtors()
RETURNS INT AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM public.realtors
    WHERE verified_at IS NOT NULL
  );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Expire old offers automatically
-- ============================================

CREATE OR REPLACE FUNCTION public.expire_old_offers()
RETURNS INT AS $$
DECLARE
  rows_affected INT;
BEGIN
  UPDATE public.realtor_offers
  SET status = 'expired'
  WHERE status = 'pending'
    AND expires_at < NOW();

  GET DIAGNOSTICS rows_affected = ROW_COUNT;
  RETURN rows_affected;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Get matching offers for buyer request
-- ============================================

CREATE OR REPLACE FUNCTION public.get_matching_offers(request_id UUID)
RETURNS TABLE (
  id UUID,
  realtor_id UUID,
  property_title TEXT,
  offered_price DECIMAL,
  status TEXT,
  created_at TIMESTAMP,
  realtor_name TEXT,
  realtor_rating DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ro.id,
    ro.realtor_id,
    ro.property_title,
    ro.offered_price,
    ro.status,
    ro.created_at,
    u.full_name,
    r.average_rating
  FROM public.realtor_offers ro
  JOIN public.users u ON ro.realtor_id = u.id
  LEFT JOIN public.realtors r ON r.user_id = u.id
  WHERE ro.request_id = request_id
    AND ro.expires_at > NOW()
  ORDER BY ro.created_at DESC;
END;
$$ LANGUAGE plpgsql;
