-- Fix: notify_realtor_on_application_decision() inserted type =
-- 'realtor_application', which isn't in notifications_type_check
-- (only 'new_offer', 'offer_response', 'new_request',
-- 'verification_status' are allowed) — every realtor-application
-- approve/reject by an admin failed outright with a check-constraint
-- violation, rolling back the whole approval/rejection. Found while
-- approving the realtor demo account's application.
--
-- 'verification_status' is the taxonomy's existing value for exactly
-- this event (matches supabase/functions/send-notification's
-- NotificationType enum) — reuse it instead of introducing a new type.

CREATE OR REPLACE FUNCTION public.notify_realtor_on_application_decision()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.verification_type = 'realtor_license'
     AND NEW.status IN ('approved', 'rejected')
     AND NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO public.notifications (user_id, type, title, message, data)
    VALUES (
      NEW.realtor_id,
      'verification_status',
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
