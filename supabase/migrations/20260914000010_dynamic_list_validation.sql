-- Replace static CHECK constraints on property_requests.category/purpose/
-- rental_period/governorate with a trigger that validates against the
-- admin-editable list_options/governorates tables instead. With a static
-- CHECK, an admin adding a new option via the admin panel (or disabling an
-- existing one) had no real effect — the constraint still only allowed the
-- original hardcoded set. This makes those admin edits actually take effect:
-- adding an active option makes it usable, disabling one blocks it.
--
-- property_subtype and status are intentionally left as static CHECK
-- constraints — they are not backed by an admin-editable list tonight.

CREATE OR REPLACE FUNCTION public.validate_property_request_lists()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.category IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.list_options
    WHERE list_name = 'category' AND code = NEW.category AND active
  ) THEN
    RAISE EXCEPTION 'Invalid or inactive category: %', NEW.category;
  END IF;

  IF NEW.purpose IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.list_options
    WHERE list_name = 'purpose' AND code = NEW.purpose AND active
  ) THEN
    RAISE EXCEPTION 'Invalid or inactive purpose: %', NEW.purpose;
  END IF;

  IF NEW.rental_period IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.list_options
    WHERE list_name = 'rental_period' AND code = NEW.rental_period AND active
  ) THEN
    RAISE EXCEPTION 'Invalid or inactive rental_period: %', NEW.rental_period;
  END IF;

  IF NEW.governorate IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.governorates
    WHERE slug = NEW.governorate AND active
  ) THEN
    RAISE EXCEPTION 'Invalid or inactive governorate: %', NEW.governorate;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

ALTER TABLE public.property_requests
  DROP CONSTRAINT IF EXISTS property_requests_category_check,
  DROP CONSTRAINT IF EXISTS property_requests_purpose_check,
  DROP CONSTRAINT IF EXISTS property_requests_rental_period_check,
  DROP CONSTRAINT IF EXISTS property_requests_governorate_check;

DROP TRIGGER IF EXISTS validate_property_request_lists_trigger
  ON public.property_requests;

CREATE TRIGGER validate_property_request_lists_trigger
  BEFORE INSERT OR UPDATE ON public.property_requests
  FOR EACH ROW EXECUTE FUNCTION public.validate_property_request_lists();
