-- Phase 2: Notifications table verification
-- Created: 2026-09-08
--
-- The notifications table is created in 20260908_001_initial_schema.sql and
-- its RLS policies in 20260908_002_rls_policies.sql. This migration asserts
-- that the table and all required columns exist, so that any accidental
-- removal or rename is caught at migration time rather than at runtime.

DO $$
DECLARE
  v_missing TEXT[] := '{}';
  v_col TEXT;
  v_required_cols TEXT[] := ARRAY[
    'id',
    'user_id',
    'type',
    'title',
    'message',
    'data',
    'is_read',
    'created_at'
  ];
BEGIN
  -- Ensure the table itself exists
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'notifications'
  ) THEN
    RAISE EXCEPTION 'public.notifications table is missing';
  END IF;

  -- Ensure every required column exists
  FOREACH v_col IN ARRAY v_required_cols LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'notifications'
        AND column_name = v_col
    ) THEN
      v_missing := array_append(v_missing, v_col);
    END IF;
  END LOOP;

  IF array_length(v_missing, 1) > 0 THEN
    RAISE EXCEPTION 'public.notifications is missing columns: %', array_to_string(v_missing, ', ');
  END IF;

  -- Ensure RLS is enabled
  IF NOT EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'notifications'
      AND c.relrowsecurity = true
  ) THEN
    RAISE EXCEPTION 'RLS is not enabled on public.notifications';
  END IF;
END;
$$;

-- Ensure the notification type constraint stays in sync with the
-- NotificationPayload type used by the send-notification Edge Function.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'notifications_type_check'
      AND conrelid = 'public.notifications'::regclass
  ) THEN
    ALTER TABLE public.notifications
      ADD CONSTRAINT notifications_type_check
      CHECK (type IN ('new_offer', 'offer_response', 'new_request', 'verification_status'));
  END IF;
END;
$$;
