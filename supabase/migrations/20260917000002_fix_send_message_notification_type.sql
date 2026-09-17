-- Fix: send_message() inserts type = 'new_message', which isn't in
-- notifications_type_check (only 'new_offer', 'offer_response',
-- 'new_request', 'verification_status' were allowed) — every chat
-- message send failed outright with a check-constraint violation,
-- rolling back the whole message insert. Found via QA testing
-- (buyer -> realtor chat on an offer).
ALTER TABLE public.notifications DROP CONSTRAINT notifications_type_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_type_check
  CHECK (type = ANY (ARRAY['new_offer', 'offer_response', 'new_request', 'verification_status', 'new_message']));
