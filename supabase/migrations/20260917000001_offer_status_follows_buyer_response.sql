-- Bug found in QA testing (2026-09-17): realtor_offers.status could never
-- reach 'accepted'. Buyers are (correctly) blocked from touching status
-- directly by enforce_offer_buyer_response_only, and nothing else set it,
-- so submit_realtor_review() always raised "Offer must be accepted before
-- it can be reviewed" — the review feature was unreachable end to end.
--
-- Fix: when a buyer updates buyer_response, derive status server-side
-- instead of comparing it to the client-sent value.
CREATE OR REPLACE FUNCTION public.enforce_offer_buyer_response_only()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
BEGIN
  IF public.current_user_id() = OLD.realtor_id OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.buyer_response IS DISTINCT FROM OLD.buyer_response THEN
    NEW.status := CASE NEW.buyer_response
      WHEN 'interested' THEN 'accepted'
      WHEN 'not_interested' THEN 'rejected'
      ELSE OLD.status
    END;
  ELSE
    NEW.status := OLD.status;
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
     OR NEW.realtor_id        IS DISTINCT FROM OLD.realtor_id
     OR NEW.request_id        IS DISTINCT FROM OLD.request_id
     OR NEW.message_to_buyer  IS DISTINCT FROM OLD.message_to_buyer
     OR NEW.expires_at        IS DISTINCT FROM OLD.expires_at
  THEN
    RAISE EXCEPTION 'buyers may only update buyer_response on an offer';
  END IF;

  RETURN NEW;
END;
$function$;
