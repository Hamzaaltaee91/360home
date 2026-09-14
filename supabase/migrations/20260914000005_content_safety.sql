-- User-generated-content safety: report + block.
--
-- Required for App Store Guideline 1.2 (Safety — User Generated Content)
-- and Google Play's User Generated Content policy, both of which apply
-- now that the app has buyer<->realtor messaging: apps with UGC must let
-- users report objectionable content/users and block abusive users, and
-- the developer must be able to act on reports.
--
-- Written by hand (not by the autonomous pilot): new table + RLS + SQL
-- functions, forbidden to the pilot per CONVENTIONS.md §5.

-- ============================================
-- TABLE: reports
-- ============================================

CREATE TABLE public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  reported_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  message_id UUID REFERENCES public.messages(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  details TEXT,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'reviewed', 'dismissed')),
  created_at TIMESTAMP DEFAULT NOW(),
  reviewed_at TIMESTAMP,
  reviewed_by UUID REFERENCES public.users(id)
);

CREATE INDEX idx_reports_status ON public.reports(status);
CREATE INDEX idx_reports_reported_user_id ON public.reports(reported_user_id);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Admins review all reports; nobody else can read this table directly.
-- No INSERT/UPDATE policy on purpose — writes go through the RPCs below.
CREATE POLICY "reports_select_admin" ON public.reports
  FOR SELECT USING (public.is_admin());

-- ============================================
-- TABLE: blocked_users
-- ============================================

CREATE TABLE public.blocked_users (
  blocker_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (blocker_id, blocked_id),
  CHECK (blocker_id <> blocked_id)
);

ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

-- A user may see who they've blocked; nobody else can see it, and no
-- direct write policy exists — writes go through the RPCs below.
CREATE POLICY "blocked_users_select_own" ON public.blocked_users
  FOR SELECT USING (blocker_id = public.current_user_id());

-- ============================================
-- FUNCTION: report a user and/or one of their messages
-- ============================================

CREATE OR REPLACE FUNCTION public.report_content(
  p_reported_user_id UUID,
  p_message_id UUID,
  p_reason TEXT,
  p_details TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reporter_id UUID;
BEGIN
  v_reporter_id := public.current_user_id();

  IF v_reporter_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_reason IS NULL OR btrim(p_reason) = '' THEN
    RAISE EXCEPTION 'A reason is required';
  END IF;

  IF p_reported_user_id IS NULL AND p_message_id IS NULL THEN
    RAISE EXCEPTION 'Must report a user, a message, or both';
  END IF;

  IF p_reported_user_id = v_reporter_id THEN
    RAISE EXCEPTION 'Cannot report yourself';
  END IF;

  INSERT INTO public.reports (reporter_id, reported_user_id, message_id, reason, details)
  VALUES (v_reporter_id, p_reported_user_id, p_message_id, btrim(p_reason), NULLIF(btrim(COALESCE(p_details, '')), ''));
END;
$$;

-- ============================================
-- FUNCTION: block / unblock a user
-- ============================================

CREATE OR REPLACE FUNCTION public.block_user(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_blocker_id UUID;
BEGIN
  v_blocker_id := public.current_user_id();

  IF v_blocker_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_user_id IS NULL OR p_user_id = v_blocker_id THEN
    RAISE EXCEPTION 'Invalid user to block';
  END IF;

  INSERT INTO public.blocked_users (blocker_id, blocked_id)
  VALUES (v_blocker_id, p_user_id)
  ON CONFLICT DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION public.unblock_user(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.blocked_users
  WHERE blocker_id = public.current_user_id()
    AND blocked_id = p_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_blocked_users()
RETURNS TABLE (
  blocked_id UUID,
  full_name TEXT,
  created_at TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT bu.blocked_id, u.full_name, bu.created_at
  FROM public.blocked_users bu
  JOIN public.users u ON u.id = bu.blocked_id
  WHERE bu.blocker_id = public.current_user_id()
  ORDER BY bu.created_at DESC;
END;
$$;

-- ============================================
-- FUNCTION: admin — list open reports
-- ============================================

CREATE OR REPLACE FUNCTION public.list_open_reports()
RETURNS TABLE (
  report_id UUID,
  reporter_name TEXT,
  reported_user_name TEXT,
  message_body TEXT,
  reason TEXT,
  details TEXT,
  created_at TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admins only';
  END IF;

  RETURN QUERY
  SELECT
    r.id,
    reporter.full_name,
    reported.full_name,
    m.body,
    r.reason,
    r.details,
    r.created_at
  FROM public.reports r
  JOIN public.users reporter ON reporter.id = r.reporter_id
  LEFT JOIN public.users reported ON reported.id = r.reported_user_id
  LEFT JOIN public.messages m ON m.id = r.message_id
  WHERE r.status = 'open'
  ORDER BY r.created_at ASC;
END;
$$;

-- ============================================
-- FUNCTION: admin — resolve a report
-- ============================================

CREATE OR REPLACE FUNCTION public.resolve_report(
  p_report_id UUID,
  p_status TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID;
BEGIN
  v_admin_id := public.current_user_id();

  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admins only';
  END IF;

  IF p_status NOT IN ('reviewed', 'dismissed') THEN
    RAISE EXCEPTION 'Invalid status: %', p_status;
  END IF;

  UPDATE public.reports
  SET status = p_status,
      reviewed_at = NOW(),
      reviewed_by = v_admin_id
  WHERE id = p_report_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Report not found';
  END IF;
END;
$$;

-- ============================================
-- Enforce blocking in messaging: a blocked party cannot message the
-- other. send_message() is redefined (not altered) to add this one check
-- on top of everything it already validated.
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

  IF EXISTS (
    SELECT 1 FROM public.blocked_users
    WHERE (blocker_id = v_recipient_id AND blocked_id = v_sender_id)
       OR (blocker_id = v_sender_id AND blocked_id = v_recipient_id)
  ) THEN
    RAISE EXCEPTION 'Cannot message a blocked user';
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
