-- Security review fixes (2026-09-15).
-- Additive, same convention as 20260911000000_rls_privilege_escalation_audit.sql:
-- does not modify already-applied migrations, only drops/recreates the
-- specific policies/functions that need tightening and adds triggers
-- where a WITH-CHECK-only fix isn't expressive enough (Postgres RLS can't
-- compare NEW to OLD column-by-column in a bare WITH CHECK; a BEFORE
-- UPDATE trigger is the standard tool for that).
--
-- Fixes:
--   1. realtor_offers_update_buyer_response let a buyer's UPDATE change
--      ANY column on the offer, not just buyer_response — a buyer could
--      rewrite a realtor's price/status/title/photos.
--   2. realtors_insert_own / realtors_update_own never restricted
--      verified_at — an unverified realtor could self-grant verified
--      status, bypassing the admin approval workflow.
--   3. users_update_own (hardened in 20260911000000, but only for `role`)
--      never restricted is_verified — any user could self-set the
--      "verified" trust badge shown in the UI.
--   4. get_matching_offers (SECURITY DEFINER) never checked that the
--      caller owns the request, bypassing RLS — any authenticated user
--      could read any buyer's offers on any request_id.

-- ---------------------------------------------------------------------------
-- 1. realtor_offers: buyers may only ever change buyer_response (and the
--    updated_at bookkeeping column) via realtor_offers_update_buyer_response.
--    The realtor's own full-access policy (realtor_offers_update_own) and
--    admin access (realtor_offers_admin_all) are untouched by this trigger.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.enforce_offer_buyer_response_only()
RETURNS TRIGGER AS $$
BEGIN
  IF public.current_user_id() = OLD.realtor_id OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.property_title      IS DISTINCT FROM OLD.property_title
     OR NEW.property_description IS DISTINCT FROM OLD.property_description
     OR NEW.property_address IS DISTINCT FROM OLD.property_address
     OR NEW.latitude          IS DISTINCT FROM OLD.latitude
     OR NEW.longitude         IS DISTINCT FROM OLD.longitude
     OR NEW.offered_price     IS DISTINCT FROM OLD.offered_price
     OR NEW.currency          IS DISTINCT FROM OLD.currency
     OR NEW.lease_type        IS DISTINCT FROM OLD.lease_type
     OR NEW.lease_duration_months IS DISTINCT FROM OLD.lease_duration_months
     OR NEW.area_sqft         IS DISTINCT FROM OLD.area_sqft
     OR NEW.bedrooms          IS DISTINCT FROM OLD.bedrooms
     OR NEW.bathrooms         IS DISTINCT FROM OLD.bathrooms
     OR NEW.furnished         IS DISTINCT FROM OLD.furnished
     OR NEW.photo_urls        IS DISTINCT FROM OLD.photo_urls
     OR NEW.document_urls     IS DISTINCT FROM OLD.document_urls
     OR NEW.status            IS DISTINCT FROM OLD.status
     OR NEW.realtor_id        IS DISTINCT FROM OLD.realtor_id
     OR NEW.request_id        IS DISTINCT FROM OLD.request_id
     OR NEW.message_to_buyer  IS DISTINCT FROM OLD.message_to_buyer
     OR NEW.expires_at        IS DISTINCT FROM OLD.expires_at
  THEN
    RAISE EXCEPTION 'buyers may only update buyer_response on an offer';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog;

DROP TRIGGER IF EXISTS trg_enforce_offer_buyer_response_only ON public.realtor_offers;

CREATE TRIGGER trg_enforce_offer_buyer_response_only
  BEFORE UPDATE ON public.realtor_offers
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_offer_buyer_response_only();

-- ---------------------------------------------------------------------------
-- 2. realtors: verified_at may only ever be set by an admin (or the
--    approve_realtor_application RPC, which is SECURITY DEFINER and runs
--    as the database owner, unaffected by this trigger's is_admin() check
--    only in the sense that it never goes through a client-driven UPDATE
--    with the caller's own row-level identity in the first place).
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "realtors_insert_own" ON public.realtors;

CREATE POLICY "realtors_insert_own" ON public.realtors
  FOR INSERT WITH CHECK (
    public.current_user_id() = user_id
    AND verified_at IS NULL
  );

CREATE OR REPLACE FUNCTION public.enforce_realtor_verified_at_admin_only()
RETURNS TRIGGER AS $$
BEGIN
  IF public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.verified_at IS DISTINCT FROM OLD.verified_at THEN
    RAISE EXCEPTION 'verified_at can only be set by an admin';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog;

DROP TRIGGER IF EXISTS trg_enforce_realtor_verified_at_admin_only ON public.realtors;

CREATE TRIGGER trg_enforce_realtor_verified_at_admin_only
  BEFORE UPDATE ON public.realtors
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_realtor_verified_at_admin_only();

-- ---------------------------------------------------------------------------
-- 3. users: is_verified may only ever be changed by an admin. Extends
--    users_update_own (which already locks `role`, from 20260911000000)
--    rather than duplicating it, since a policy can only be defined once.
--    admins_update_users (also from 20260911000000) is untouched.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "users_update_own" ON public.users;

CREATE POLICY "users_update_own"
  ON public.users
  FOR UPDATE
  USING (auth.uid() = auth_id)
  WITH CHECK (
    auth.uid() = auth_id
    AND role = public.current_user_role()
    AND is_verified = (SELECT is_verified FROM public.users WHERE auth_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- 4. get_matching_offers: add an ownership guard. Signature/body below
--    match the function as it currently exists live (verified via
--    pg_get_functiondef before writing this migration — the version in
--    20260908000003_functions_and_triggers.sql had already drifted from
--    what's actually deployed), so this CREATE OR REPLACE only adds the
--    guard at the top; the query itself is unchanged.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_matching_offers(p_request_id uuid)
 RETURNS TABLE(offer_id uuid, offer_realtor_id uuid, offer_property_title text, offer_offered_price numeric, offer_status text, offer_created_at timestamp without time zone, realtor_name text, realtor_rating numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- NEW — the only change: refuse unless the caller owns the request (or
  -- is an admin). Previously any authenticated user could pass an
  -- arbitrary request_id and read that buyer's offers.
  IF NOT EXISTS (
    SELECT 1 FROM public.property_requests
    WHERE property_requests.id = p_request_id
      AND (property_requests.buyer_id = public.current_user_id() OR public.is_admin())
  ) THEN
    RAISE EXCEPTION 'not authorized to view offers for this request';
  END IF;

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
  WHERE ro.request_id = p_request_id
    AND ro.status != 'expired'
    AND ro.expires_at > NOW()
  ORDER BY ro.created_at DESC;
END;
$function$;
