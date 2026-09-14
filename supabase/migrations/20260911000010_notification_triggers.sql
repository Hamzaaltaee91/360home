-- Auto-create notifications for the two events users actually wait on.
--
-- Written by hand (not by the autonomous pilot): CONVENTIONS.md §5 forbids
-- the pilot from ever writing or editing a SQL function or trigger. These
-- triggers are SECURITY DEFINER so they can insert into public.notifications
-- even though no client-facing INSERT policy exists there (by design —
-- notifications must only ever be created by trusted server-side logic).

-- ============================================
-- TRIGGER: notify the buyer when a realtor submits an offer
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_buyer_on_new_offer()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_buyer_id UUID;
BEGIN
  SELECT buyer_id INTO v_buyer_id
  FROM public.property_requests
  WHERE id = NEW.request_id;

  IF v_buyer_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, type, title, message, data)
    VALUES (
      v_buyer_id,
      'new_offer',
      'عرض جديد على طلبك',
      NEW.property_title,
      jsonb_build_object('offer_id', NEW.id, 'request_id', NEW.request_id)
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_realtor_offer_created ON public.realtor_offers;
CREATE TRIGGER on_realtor_offer_created
  AFTER INSERT ON public.realtor_offers
  FOR EACH ROW EXECUTE FUNCTION public.notify_buyer_on_new_offer();

-- ============================================
-- TRIGGER: notify the realtor when the buyer responds to their offer
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_realtor_on_buyer_response()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.buyer_response IS NOT NULL
     AND NEW.buyer_response IS DISTINCT FROM OLD.buyer_response THEN
    INSERT INTO public.notifications (user_id, type, title, message, data)
    VALUES (
      NEW.realtor_id,
      'offer_response',
      CASE NEW.buyer_response
        WHEN 'interested' THEN 'المشتري مهتم بعرضك'
        ELSE 'رد المشتري على عرضك'
      END,
      NEW.property_title,
      jsonb_build_object('offer_id', NEW.id, 'request_id', NEW.request_id)
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_offer_buyer_response ON public.realtor_offers;
CREATE TRIGGER on_offer_buyer_response
  AFTER UPDATE ON public.realtor_offers
  FOR EACH ROW EXECUTE FUNCTION public.notify_realtor_on_buyer_response();

-- ============================================
-- TRIGGER: notify the realtor when their application is approved/rejected
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_realtor_on_application_decision()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.verification_type = 'realtor_license'
     AND NEW.status IN ('approved', 'rejected')
     AND NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO public.notifications (user_id, type, title, message, data)
    VALUES (
      NEW.realtor_id,
      'realtor_application',
      CASE NEW.status
        WHEN 'approved' THEN 'تم قبول طلب التوثيق'
        ELSE 'تم رفض طلب التوثيق'
      END,
      COALESCE(NEW.rejection_reason, ''),
      jsonb_build_object('verification_id', NEW.id)
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_realtor_application_decision ON public.realtor_verifications;
CREATE TRIGGER on_realtor_application_decision
  AFTER UPDATE ON public.realtor_verifications
  FOR EACH ROW EXECUTE FUNCTION public.notify_realtor_on_application_decision();
