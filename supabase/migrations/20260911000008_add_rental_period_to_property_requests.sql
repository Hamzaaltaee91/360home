--
-- Adds an optional rental_period to public.property_requests.
-- NULL is intentional: a "buy" request must leave this column NULL;
-- only rental requests set one of the CHECK-allowed values below.
-- No DB-level DEFAULT on purpose.

ALTER TABLE public.property_requests
  ADD COLUMN IF NOT EXISTS rental_period TEXT
  CHECK (rental_period IN ('daily', 'weekly', 'monthly', 'yearly'));
