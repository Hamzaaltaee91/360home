-- Phase 2: Realtor Verifications enhancements
-- Created: 2026-09-08
--
-- The base `realtor_verifications` table is created in
-- 20260908_001_initial_schema.sql and its RLS policies live in
-- 20260908_002_rls_policies.sql. This migration completes the feature by:
--   1. Adding a `verification_type` column (license / identity / business).
--   2. Adding an `updated_at` column + trigger for consistency.
--   3. Preventing duplicate pending requests per realtor.
--   4. Syncing `realtors.verified_at` when a request is approved.

-- ============================================
-- COLUMNS
-- ============================================

ALTER TABLE public.realtor_verifications
  ADD COLUMN IF NOT EXISTS verification_type TEXT NOT NULL DEFAULT 'realtor_license'
    CHECK (verification_type IN ('realtor_license', 'identity', 'business_registration'));

ALTER TABLE public.realtor_verifications
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_realtor_verifications_verification_type
  ON public.realtor_verifications(verification_type);

CREATE INDEX IF NOT EXISTS idx_realtor_verifications_created_at
  ON public.realtor_verifications(created_at);

-- Prevent more than one pending request per realtor.
CREATE UNIQUE INDEX IF NOT EXISTS uniq_realtor_verifications_pending
  ON public.realtor_verifications(realtor_id)
  WHERE status = 'pending';

-- ============================================
-- TRIGGER: keep updated_at fresh
-- ============================================

DROP TRIGGER IF EXISTS update_realtor_verifications_updated_at
  ON public.realtor_verifications;
CREATE TRIGGER update_realtor_verifications_updated_at
  BEFORE UPDATE ON public.realtor_verifications
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- TRIGGER: sync realtors.verified_at on approval
-- ============================================

CREATE OR REPLACE FUNCTION public.sync_realtor_verification()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'approved' AND (OLD.status IS DISTINCT FROM 'approved') THEN
    UPDATE public.realtors
    SET verified_at = COALESCE(verified_at, NOW())
    WHERE user_id = NEW.realtor_id;
  ELSIF NEW.status = 'rejected' AND OLD.status = 'approved' THEN
    UPDATE public.realtors
    SET verified_at = NULL
    WHERE user_id = NEW.realtor_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_realtor_verification_status_change
  ON public.realtor_verifications;
CREATE TRIGGER on_realtor_verification_status_change
  AFTER UPDATE ON public.realtor_verifications
  FOR EACH ROW EXECUTE FUNCTION public.sync_realtor_verification();

-- ============================================
-- FUNCTION: Submit a realtor verification request
-- ============================================

CREATE OR REPLACE FUNCTION public.submit_realtor_verification(
  p_document_url TEXT,
  p_verification_type TEXT DEFAULT 'realtor_license'
)
RETURNS TABLE (
  verification_id UUID,
  verification_status TEXT
) AS $$
DECLARE
  v_user_id UUID;
  v_id UUID;
BEGIN
  v_user_id := public.current_user_id();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_verification_type NOT IN ('realtor_license', 'identity', 'business_registration') THEN
    RAISE EXCEPTION 'Invalid verification type: %', p_verification_type;
  END IF;

  INSERT INTO public.realtor_verifications (
    realtor_id,
    document_url,
    verification_type,
    status
  )
  VALUES (
    v_user_id,
    p_document_url,
    p_verification_type,
    'pending'
  )
  RETURNING id INTO v_id;

  RETURN QUERY SELECT v_id, 'pending'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================
-- FUNCTION: Get current realtor's verification status
-- ============================================

CREATE OR REPLACE FUNCTION public.get_my_verification_status()
RETURNS TABLE (
  verification_id UUID,
  verification_type TEXT,
  verification_status TEXT,
  rejection_reason TEXT,
  document_url TEXT,
  created_at TIMESTAMP,
  reviewed_at TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    rv.id,
    rv.verification_type,
    rv.status,
    rv.rejection_reason,
    rv.document_url,
    rv.created_at,
    rv.reviewed_at
  FROM public.realtor_verifications rv
  WHERE rv.realtor_id = public.current_user_id()
  ORDER BY rv.created_at DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
