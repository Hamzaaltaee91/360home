-- Buyer <-> realtor messaging, scoped to one offer.
--
-- Written by hand (not by the autonomous pilot): CONVENTIONS.md §5 forbids
-- the pilot from ever writing RLS policies or SQL functions. A message
-- belongs to one realtor_offers row, exchanged only between that offer's
-- buyer (via property_requests.buyer_id) and its realtor. All party
-- validation, the paired offer_interactions audit row, and the
-- recipient notification happen inside send_message() (SECURITY
-- DEFINER); no direct INSERT policy exists on messages, by design —
-- matching the pattern already used for notifications and reviews.

-- ============================================
-- TABLE
-- ============================================

CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  offer_id UUID NOT NULL REFERENCES public.realtor_offers(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_messages_offer_id ON public.messages(offer_id);
CREATE INDEX idx_messages_recipient_id ON public.messages(recipient_id);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Only the two parties to a message may see it. No INSERT/UPDATE policy
-- is defined on purpose: writes go through the RPCs below only, so
-- Realtime subscriptions filtered by offer_id still work (Realtime
-- honors this SELECT policy) without opening a direct write path.
CREATE POLICY "messages_select_involved" ON public.messages
  FOR SELECT USING (
    sender_id = public.current_user_id()
    OR recipient_id = public.current_user_id()
  );

-- ============================================
-- FUNCTION: send a message on an offer
-- ============================================

CREATE OR REPLACE FUNCTION public.send_message(
  p_offer_id UUID,
  p_body TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sender_id UUID;
  v_realtor_id UUID;
  v_buyer_id UUID;
  v_recipient_id UUID;
  v_message_id UUID;
BEGIN
  v_sender_id := public.current_user_id();

  IF v_sender_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_body IS NULL OR btrim(p_body) = '' THEN
    RAISE EXCEPTION 'Message body is required';
  END IF;

  SELECT ro.realtor_id, pr.buyer_id
    INTO v_realtor_id, v_buyer_id
  FROM public.realtor_offers ro
  JOIN public.property_requests pr ON pr.id = ro.request_id
  WHERE ro.id = p_offer_id;

  IF v_realtor_id IS NULL THEN
    RAISE EXCEPTION 'Offer not found';
  END IF;

  IF v_sender_id = v_buyer_id THEN
    v_recipient_id := v_realtor_id;
  ELSIF v_sender_id = v_realtor_id THEN
    v_recipient_id := v_buyer_id;
  ELSE
    RAISE EXCEPTION 'Only the buyer or realtor on this offer may message';
  END IF;

  INSERT INTO public.messages (offer_id, sender_id, recipient_id, body)
  VALUES (p_offer_id, v_sender_id, v_recipient_id, btrim(p_body))
  RETURNING id INTO v_message_id;

  INSERT INTO public.offer_interactions (offer_id, buyer_id, realtor_id, interaction_type, message_content)
  VALUES (p_offer_id, v_buyer_id, v_realtor_id, 'message', btrim(p_body));

  INSERT INTO public.notifications (user_id, type, title, message, data)
  VALUES (
    v_recipient_id,
    'new_message',
    'رسالة جديدة',
    left(btrim(p_body), 200),
    jsonb_build_object('offer_id', p_offer_id, 'message_id', v_message_id)
  );

  RETURN v_message_id;
END;
$$;

-- ============================================
-- FUNCTION: list messages for one offer, oldest first
-- ============================================

CREATE OR REPLACE FUNCTION public.list_messages(p_offer_id UUID)
RETURNS TABLE (
  id UUID,
  sender_id UUID,
  recipient_id UUID,
  body TEXT,
  is_read BOOLEAN,
  created_at TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := public.current_user_id();

  RETURN QUERY
  SELECT m.id, m.sender_id, m.recipient_id, m.body, m.is_read, m.created_at
  FROM public.messages m
  WHERE m.offer_id = p_offer_id
    AND (m.sender_id = v_user_id OR m.recipient_id = v_user_id)
  ORDER BY m.created_at ASC;
END;
$$;

-- ============================================
-- FUNCTION: mark all of the current user's unread messages on one offer
-- as read
-- ============================================

CREATE OR REPLACE FUNCTION public.mark_messages_read(p_offer_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.messages
  SET is_read = true
  WHERE offer_id = p_offer_id
    AND recipient_id = public.current_user_id()
    AND is_read = false;
END;
$$;

-- ============================================
-- FUNCTION: total unread message count for the current user
-- ============================================

CREATE OR REPLACE FUNCTION public.unread_message_count()
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM public.messages
  WHERE recipient_id = public.current_user_id()
    AND is_read = false;

  RETURN v_count;
END;
$$;
