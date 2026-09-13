-- Realtor application + admin approval.
--
-- Written by hand (not by the autonomous pilot): this touches role
-- assignment, which CONVENTIONS.md §5 forbids the pilot from ever doing.
-- No client code ever sets a role directly. A buyer submits an application
-- (company/license details + a document) via submit_realtor_application();
-- an admin approves or rejects it via approve/reject_realtor_application().
-- All privilege logic (the is_admin() check, the role flip, and creating
-- the public.realtors row) lives inside these SECURITY DEFINER functions,
-- never in client-supplied data.

-- ============================================
-- COLUMNS: realtor_verifications gains application details
-- ============================================

ALTER TABLE public.realtor_verifications
  ADD COLUMN IF NOT EXISTS company_name TEXT;

ALTER TABLE public.realtor_verifications
  ADD COLUMN IF NOT EXISTS license_number TEXT;

ALTER TABLE public.realtor_verifications
  ADD COLUMN IF NOT EXISTS license_expiry DATE;

-- ============================================
-- FUNCTION: submit a realtor application (self-service, safe)
-- ============================================

CREATE OR REPLACE FUNCTION public.submit_realtor_application(
  p_company_name TEXT,
  p_license_number TEXT,
  p_license_expiry DATE,
  p_document_url TEXT
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

  INSERT INTO public.realtor_verifications (
    realtor_id,
    document_url,
    verification_type,
    company_name,
    license_number,
    license_expiry,
    status
  )
  VALUES (
    v_user_id,
    p_document_url,
    'realtor_license',
    btrim(p_company_name),
    btrim(p_license_number),
    p_license_expiry,
    'pending'
  )
  RETURNING id INTO v_id;

  RETURN QUERY SELECT v_id, 'pending'::TEXT;
END;
$$;

-- ============================================
-- FUNCTION: list pending realtor applications (admin only)
-- ============================================

CREATE OR REPLACE FUNCTION public.list_pending_realtor_applications()
RETURNS TABLE (
  verification_id UUID,
  realtor_id UUID,
  full_name TEXT,
  email TEXT,
  company_name TEXT,
  license_number TEXT,
  license_expiry DATE,
  document_url TEXT,
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
    rv.id,
    rv.realtor_id,
    u.full_name,
    u.email,
    rv.company_name,
    rv.license_number,
    rv.license_expiry,
    rv.document_url,
    rv.created_at
  FROM public.realtor_verifications rv
  JOIN public.users u ON u.id = rv.realtor_id
  WHERE rv.status = 'pending'
    AND rv.verification_type = 'realtor_license'
  ORDER BY rv.created_at ASC;
END;
$$;

-- ============================================
-- FUNCTION: approve a realtor application (admin only)
-- Flips role, creates/updates the realtors row. The only place in the
-- codebase where a user's role changes to 'realtor'.
-- ============================================

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
  v_status TEXT;
  v_verification_type TEXT;
BEGIN
  v_admin_id := public.current_user_id();

  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admins only';
  END IF;

  SELECT realtor_id, company_name, license_number, license_expiry, status, verification_type
    INTO v_realtor_id, v_company_name, v_license_number, v_license_expiry, v_status, v_verification_type
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
    user_id, company_name, license_number, license_expiry, verified_at
  )
  VALUES (
    v_realtor_id, v_company_name, v_license_number, v_license_expiry, NOW()
  )
  ON CONFLICT (user_id) DO UPDATE
  SET company_name = EXCLUDED.company_name,
      license_number = EXCLUDED.license_number,
      license_expiry = EXCLUDED.license_expiry,
      verified_at = NOW();
END;
$$;

-- ============================================
-- FUNCTION: reject a realtor application (admin only)
-- ============================================

CREATE OR REPLACE FUNCTION public.reject_realtor_application(
  p_verification_id UUID,
  p_reason TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID;
  v_status TEXT;
  v_verification_type TEXT;
BEGIN
  v_admin_id := public.current_user_id();

  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admins only';
  END IF;

  SELECT status, verification_type INTO v_status, v_verification_type
  FROM public.realtor_verifications
  WHERE id = p_verification_id
  FOR UPDATE;

  IF v_status IS NULL THEN
    RAISE EXCEPTION 'Verification request not found';
  END IF;
  IF v_verification_type <> 'realtor_license' THEN
    RAISE EXCEPTION 'Not a realtor-license application';
  END IF;
  IF v_status <> 'pending' THEN
    RAISE EXCEPTION 'Application is not pending';
  END IF;

  UPDATE public.realtor_verifications
  SET status = 'rejected',
      rejection_reason = p_reason,
      reviewed_by = v_admin_id,
      reviewed_at = NOW()
  WHERE id = p_verification_id;
END;
$$;
