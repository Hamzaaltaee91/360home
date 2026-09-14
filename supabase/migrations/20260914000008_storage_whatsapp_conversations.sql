-- Storage buckets + policies, WhatsApp number on realtor applications, and
-- a conversations-list RPC.
--
-- Written by hand (not by the autonomous pilot): CONVENTIONS.md §5 forbids
-- the pilot from ever writing storage/RLS policies or SQL functions, and
-- this migration is entirely that.
--
-- FINDING: no storage bucket has ever existed on this project (`select *
-- from storage.buckets` returned zero rows). lib/services/supabase_service.dart's
-- uploadPropertyPhoto()/uploadProfilePicture() already reference a
-- 'dabberli' bucket — both have been silently broken (bucket-not-found)
-- since they were written, independent of tonight's user-reported bugs.

-- ============================================
-- STORAGE: buckets
-- ============================================

-- 'dabberli' — property photos and profile pictures. Public read: these
-- are already meant to be shown to any buyer browsing offers / any user
-- viewing a profile, matching the getPublicUrl() calls already in
-- uploadPropertyPhoto()/uploadProfilePicture().
INSERT INTO storage.buckets (id, name, public)
VALUES ('dabberli', 'dabberli', true)
ON CONFLICT (id) DO NOTHING;

-- 'verification-documents' — realtor license/ID documents submitted with
-- submit_realtor_application(). Private, unlike 'dabberli': these are
-- sensitive personal/business documents, readable only by the uploading
-- user and admins (via a signed URL, not a public one).
INSERT INTO storage.buckets (id, name, public)
VALUES ('verification-documents', 'verification-documents', false)
ON CONFLICT (id) DO NOTHING;

-- Any authenticated user may upload into 'dabberli' (non-sensitive; which
-- request/profile an uploaded URL actually gets attached to is still
-- governed by RLS on property_requests/realtor_offers/users).
DROP POLICY IF EXISTS "dabberli_authenticated_insert" ON storage.objects;
CREATE POLICY "dabberli_authenticated_insert"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'dabberli');

-- verification-documents: the uploading user may write only under a path
-- prefixed with their own public.users.id, and may read their own
-- documents; admins may read any document in the bucket.
DROP POLICY IF EXISTS "verification_documents_owner_insert" ON storage.objects;
CREATE POLICY "verification_documents_owner_insert"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'verification-documents'
    AND (storage.foldername(name))[1] = public.current_user_id()::text
  );

DROP POLICY IF EXISTS "verification_documents_select" ON storage.objects;
CREATE POLICY "verification_documents_select"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'verification-documents'
    AND (
      (storage.foldername(name))[1] = public.current_user_id()::text
      OR public.is_admin()
    )
  );

-- ============================================
-- COLUMN: whatsapp_phone on the realtor application + synced profile
-- ============================================

ALTER TABLE public.realtor_verifications
  ADD COLUMN IF NOT EXISTS whatsapp_phone TEXT;

ALTER TABLE public.realtors
  ADD COLUMN IF NOT EXISTS whatsapp_phone TEXT;

-- submit_realtor_application() gains a required p_whatsapp_phone param so
-- buyers/admins have a way to reach an approved realtor. Same shape as
-- 20260911000009_realtor_application_approval.sql, replayed with the new
-- column and param added.
CREATE OR REPLACE FUNCTION public.submit_realtor_application(
  p_company_name TEXT,
  p_license_number TEXT,
  p_license_expiry DATE,
  p_document_url TEXT,
  p_whatsapp_phone TEXT
)
RETURNS TABLE (
  verification_id UUID,
  verification_status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_id UUID;
BEGIN
  v_user_id := public.current_user_id();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_company_name IS NULL OR btrim(p_company_name) = '' THEN
    RAISE EXCEPTION 'company_name is required';
  END IF;
  IF p_license_number IS NULL OR btrim(p_license_number) = '' THEN
    RAISE EXCEPTION 'license_number is required';
  END IF;
  IF p_license_expiry IS NULL THEN
    RAISE EXCEPTION 'license_expiry is required';
  END IF;
  IF p_document_url IS NULL OR btrim(p_document_url) = '' THEN
    RAISE EXCEPTION 'document_url is required';
  END IF;
  IF p_whatsapp_phone IS NULL OR btrim(p_whatsapp_phone) = '' THEN
    RAISE EXCEPTION 'whatsapp_phone is required';
  END IF;

  INSERT INTO public.realtor_verifications (
    realtor_id,
    document_url,
    verification_type,
    company_name,
    license_number,
    license_expiry,
    whatsapp_phone,
    status
  )
  VALUES (
    v_user_id,
    p_document_url,
    'realtor_license',
    btrim(p_company_name),
    btrim(p_license_number),
    p_license_expiry,
    btrim(p_whatsapp_phone),
    'pending'
  )
  RETURNING id INTO v_id;

  RETURN QUERY SELECT v_id, 'pending'::TEXT;
END;
$$;

-- approve_realtor_application() now also syncs whatsapp_phone onto
-- public.realtors. Replayed from 20260911000009 with that one addition.
CREATE OR REPLACE FUNCTION public.approve_realtor_application(
  p_verification_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID;
  v_realtor_id UUID;
  v_company_name TEXT;
  v_license_number TEXT;
  v_license_expiry DATE;
  v_whatsapp_phone TEXT;
  v_status TEXT;
  v_verification_type TEXT;
BEGIN
  v_admin_id := public.current_user_id();

  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admins only';
  END IF;

  SELECT realtor_id, company_name, license_number, license_expiry, whatsapp_phone, status, verification_type
    INTO v_realtor_id, v_company_name, v_license_number, v_license_expiry, v_whatsapp_phone, v_status, v_verification_type
  FROM public.realtor_verifications
  WHERE id = p_verification_id
  FOR UPDATE;

  IF v_realtor_id IS NULL THEN
    RAISE EXCEPTION 'Verification request not found';
  END IF;
  IF v_verification_type <> 'realtor_license' THEN
    RAISE EXCEPTION 'Not a realtor-license application';
  END IF;
  IF v_status <> 'pending' THEN
    RAISE EXCEPTION 'Application is not pending';
  END IF;

  UPDATE public.realtor_verifications
  SET status = 'approved',
      reviewed_by = v_admin_id,
      reviewed_at = NOW()
  WHERE id = p_verification_id;

  UPDATE public.users
  SET role = 'realtor'
  WHERE id = v_realtor_id
    AND role <> 'admin';

  INSERT INTO public.realtors (
    user_id, company_name, license_number, license_expiry, whatsapp_phone, verified_at
  )
  VALUES (
    v_realtor_id, v_company_name, v_license_number, v_license_expiry, v_whatsapp_phone, NOW()
  )
  ON CONFLICT (user_id) DO UPDATE
  SET company_name = EXCLUDED.company_name,
      license_number = EXCLUDED.license_number,
      license_expiry = EXCLUDED.license_expiry,
      whatsapp_phone = EXCLUDED.whatsapp_phone,
      verified_at = NOW();
END;
$$;

-- ============================================
-- FUNCTION: list the current user's open conversations
-- ============================================
--
-- One row per offer that has at least one message, newest last-message
-- first, for a "chats" tab distinct from the existing per-offer
-- MessagesScreen (list_messages(p_offer_id)).

CREATE OR REPLACE FUNCTION public.list_my_conversations()
RETURNS TABLE (
  offer_id UUID,
  other_party_id UUID,
  other_party_name TEXT,
  property_title TEXT,
  last_message TEXT,
  last_message_at TIMESTAMP,
  unread_count INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := public.current_user_id();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  RETURN QUERY
  SELECT
    o.id,
    other.id,
    other.full_name,
    o.property_title,
    lm.body,
    lm.created_at,
    COALESCE(uc.unread, 0)::INT
  FROM public.realtor_offers o
  JOIN public.property_requests pr ON pr.id = o.request_id
  JOIN public.users other
    ON other.id = (CASE WHEN pr.buyer_id = v_user_id THEN o.realtor_id ELSE pr.buyer_id END)
  JOIN LATERAL (
    SELECT m.body, m.created_at
    FROM public.messages m
    WHERE m.offer_id = o.id
    ORDER BY m.created_at DESC
    LIMIT 1
  ) lm ON true
  LEFT JOIN LATERAL (
    SELECT COUNT(*) AS unread
    FROM public.messages m
    WHERE m.offer_id = o.id
      AND m.recipient_id = v_user_id
      AND m.is_read = false
  ) uc ON true
  WHERE pr.buyer_id = v_user_id OR o.realtor_id = v_user_id
  ORDER BY lm.created_at DESC;
END;
$$;
