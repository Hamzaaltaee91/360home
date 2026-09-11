-- Tests for the realtor_verifications feature.
-- Run with: supabase db test  (or psql -f this file against a local db)
--
-- These tests use a transaction that is rolled back at the end so they
-- do not pollute the database.

BEGIN;

-- ------------------------------------------------------------------
-- Setup: create an auth user + public user + realtor
-- ------------------------------------------------------------------
DO $$
DECLARE
  v_auth_id UUID := gen_random_uuid();
  v_user_id UUID;
  v_realtor_id UUID;
  v_verification_id UUID;
  v_status TEXT;
  v_verified_at TIMESTAMP;
BEGIN
  INSERT INTO auth.users (
    id, instance_id, aud, role, email,
    encrypted_password, email_confirmed_at,
    created_at, updated_at
  )
  VALUES (
    v_auth_id, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'realtor-test@example.com',
    crypt('password123', gen_salt('bf')), NOW(),
    NOW(), NOW()
  );

  SELECT id INTO v_user_id FROM public.users WHERE auth_id = v_auth_id;
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'handle_new_user trigger did not create a public.users row';
  END IF;

  INSERT INTO public.realtors (user_id, company_name, license_number, license_expiry)
  VALUES (v_user_id, 'Test Co', 'LIC-TEST-001', NOW() + INTERVAL '1 year')
  RETURNING id INTO v_realtor_id;

  -- ------------------------------------------------------------------
  -- Test 1: inserting a pending verification works
  -- ------------------------------------------------------------------
  INSERT INTO public.realtor_verifications (realtor_id, document_url, verification_type)
  VALUES (v_user_id, 'https://example.com/doc.pdf', 'realtor_license')
  RETURNING id INTO v_verification_id;

  IF v_verification_id IS NULL THEN
    RAISE EXCEPTION 'Test 1 failed: verification row was not created';
  END IF;

  -- ------------------------------------------------------------------
  -- Test 2: duplicate pending verification is rejected
  -- ------------------------------------------------------------------
  BEGIN
    INSERT INTO public.realtor_verifications (realtor_id, document_url, verification_type)
    VALUES (v_user_id, 'https://example.com/doc2.pdf', 'realtor_license');
    RAISE EXCEPTION 'Test 2 failed: duplicate pending verification was allowed';
  EXCEPTION
    WHEN unique_violation THEN
      NULL; -- expected
  END;

  -- ------------------------------------------------------------------
  -- Test 3: approving a verification sets realtors.verified_at
  -- ------------------------------------------------------------------
  UPDATE public.realtor_verifications
  SET status = 'approved', reviewed_at = NOW()
  WHERE id = v_verification_id;

  SELECT verified_at INTO v_verified_at
  FROM public.realtors WHERE user_id = v_user_id;

  IF v_verified_at IS NULL THEN
    RAISE EXCEPTION 'Test 3 failed: realtors.verified_at was not set on approval';
  END IF;

  -- ------------------------------------------------------------------
  -- Test 4: rejecting an approved verification clears verified_at
  -- ------------------------------------------------------------------
  UPDATE public.realtor_verifications
  SET status = 'rejected', rejection_reason = 'Expired license'
  WHERE id = v_verification_id;

  SELECT verified_at INTO v_verified_at
  FROM public.realtors WHERE user_id = v_user_id;

  IF v_verified_at IS NOT NULL THEN
    RAISE EXCEPTION 'Test 4 failed: realtors.verified_at was not cleared on rejection';
  END IF;

  -- ------------------------------------------------------------------
  -- Test 5: updated_at trigger fires
  -- ------------------------------------------------------------------
  SELECT updated_at INTO v_verified_at
  FROM public.realtor_verifications WHERE id = v_verification_id;

  IF v_verified_at IS NULL THEN
    RAISE EXCEPTION 'Test 5 failed: updated_at was not set';
  END IF;

  RAISE NOTICE 'All realtor_verifications tests passed.';
END $$;

ROLLBACK;
