-- Tests for 20260908_003_functions_and_triggers.sql
-- Run with: supabase db test (or psql against local instance)
-- These tests verify triggers and functions behave as expected.

BEGIN;

-- Ensure pgcrypto is available for crypt()/gen_salt()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================
-- Test 1: handle_new_user() creates a public.users row
-- ============================================
DO $$
DECLARE
  v_auth_id UUID := gen_random_uuid();
  v_user_id UUID;
  v_role TEXT;
BEGIN
  INSERT INTO auth.users (
    id, instance_id, aud, role, email,
    encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
  )
  VALUES (
    v_auth_id,
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'test_buyer@example.com',
    crypt('password123', gen_salt('bf')),
    NOW(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"role": "buyer", "full_name": "Test Buyer"}'::jsonb,
    NOW(),
    NOW()
  );

  SELECT id, role INTO v_user_id, v_role
  FROM public.users
  WHERE auth_id = v_auth_id;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'handle_new_user did not create a public.users row';
  END IF;

  IF v_role != 'buyer' THEN
    RAISE EXCEPTION 'Expected role buyer, got %', v_role;
  END IF;

  RAISE NOTICE 'Test 1 passed: handle_new_user creates user with correct role';
END $$;

-- ============================================
-- Test 2: handle_new_user() defaults invalid role to 'buyer'
-- ============================================
DO $$
DECLARE
  v_auth_id UUID := gen_random_uuid();
  v_role TEXT;
BEGIN
  INSERT INTO auth.users (
    id, instance_id, aud, role, email,
    encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
  )
  VALUES (
    v_auth_id,
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'test_invalid_role@example.com',
    crypt('password123', gen_salt('bf')),
    NOW(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"role": "superadmin"}'::jsonb,
    NOW(),
    NOW()
  );

  SELECT role INTO v_role
  FROM public.users
  WHERE auth_id = v_auth_id;

  IF v_role != 'buyer' THEN
    RAISE EXCEPTION 'Expected invalid role to default to buyer, got %', v_role;
  END IF;

  RAISE NOTICE 'Test 2 passed: invalid role defaults to buyer';
END $$;

-- ============================================
-- Test 3: update_updated_at_column() updates users.updated_at
-- ============================================
DO $$
DECLARE
  v_user_id UUID;
  v_before TIMESTAMP;
  v_after TIMESTAMP;
BEGIN
  SELECT id INTO v_user_id FROM public.users ORDER BY created_at LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE NOTICE 'Test 3 skipped: no users exist';
    RETURN;
  END IF;

  SELECT updated_at INTO v_before FROM public.users WHERE id = v_user_id;

  PERFORM pg_sleep(0.01);

  UPDATE public.users SET full_name = 'Updated Name' WHERE id = v_user_id;

  SELECT updated_at INTO v_after FROM public.users WHERE id = v_user_id;

  IF v_after <= v_before THEN
    RAISE EXCEPTION 'updated_at was not refreshed (before=%, after=%)', v_before, v_after;
  END IF;

  RAISE NOTICE 'Test 3 passed: updated_at trigger works on users';
END $$;

-- ============================================
-- Test 4: log_offer_interaction() inserts on status change
-- ============================================
DO $$
DECLARE
  v_buyer_id UUID;
  v_realtor_id UUID;
  v_request_id UUID;
  v_offer_id UUID;
  v_count INT;
BEGIN
  SELECT id INTO v_buyer_id FROM public.users WHERE role = 'buyer' LIMIT 1;
  SELECT id INTO v_realtor_id FROM public.users WHERE role = 'realtor' LIMIT 1;

  IF v_buyer_id IS NULL OR v_realtor_id IS NULL THEN
    RAISE NOTICE 'Test 4 skipped: need at least one buyer and one realtor';
    RETURN;
  END IF;

  INSERT INTO public.property_requests (buyer_id, category, title, city)
  VALUES (v_buyer_id, 'residential', 'Test Request', 'Dubai')
  RETURNING id INTO v_request_id;

  INSERT INTO public.realtor_offers (
    realtor_id, request_id, property_title, property_address, offered_price
  )
  VALUES (
    v_realtor_id, v_request_id, 'Test Offer', 'Test Address', 100000
  )
  RETURNING id INTO v_offer_id;

  UPDATE public.realtor_offers SET status = 'accepted' WHERE id = v_offer_id;

  SELECT COUNT(*) INTO v_count
  FROM public.offer_interactions
  WHERE offer_id = v_offer_id;

  IF v_count < 1 THEN
    RAISE EXCEPTION 'log_offer_interaction did not insert an interaction row';
  END IF;

  RAISE NOTICE 'Test 4 passed: log_offer_interaction inserts on status change';
END $$;

-- ============================================
-- Test 5: get_matching_offers() excludes expired offers
-- ============================================
DO $$
DECLARE
  v_buyer_id UUID;
  v_realtor_id UUID;
  v_request_id UUID;
  v_offer_id UUID;
  v_count INT;
BEGIN
  SELECT id INTO v_buyer_id FROM public.users WHERE role = 'buyer' LIMIT 1;
  SELECT id INTO v_realtor_id FROM public.users WHERE role = 'realtor' LIMIT 1;

  IF v_buyer_id IS NULL OR v_realtor_id IS NULL THEN
    RAISE NOTICE 'Test 5 skipped: need at least one buyer and one realtor';
    RETURN;
  END IF;

  INSERT INTO public.property_requests (buyer_id, category, title, city)
  VALUES (v_buyer_id, 'residential', 'Test Request 2', 'Dubai')
  RETURNING id INTO v_request_id;

  INSERT INTO public.realtor_offers (
    realtor_id, request_id, property_title, property_address, offered_price, status
  )
  VALUES (
    v_realtor_id, v_request_id, 'Expired Offer', 'Test Address', 100000, 'expired'
  )
  RETURNING id INTO v_offer_id;

  SELECT COUNT(*) INTO v_count
  FROM public.get_matching_offers(v_request_id);

  IF v_count != 0 THEN
    RAISE EXCEPTION 'get_matching_offers returned expired offers (count=%)', v_count;
  END IF;

  RAISE NOTICE 'Test 5 passed: get_matching_offers excludes expired offers';
END $$;

ROLLBACK;
