-- Phase 2: Notifications table verification
-- Created: 2026-09-08
--
-- The notifications table is created in 20260908_001_initial_schema.sql and
-- its RLS policies in 20260908_002_rls_policies.sql. This migration asserts
-- that the table and all required columns exist, so that any accidental
-- removal or rename is caught at migration time rather than at runtime.
--
-- Implemented with plain SQL (no DO blocks) so it is compatible with all
-- SQL parsers and linters.

-- Ensure the table itself exists.
-- This SELECT raises an error if the table is missing.
SELECT 1 / CASE WHEN EXISTS (
  SELECT 1
  FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_name = 'notifications'
) THEN 1 ELSE 0 END AS notifications_table_exists;

-- Ensure every required column exists.
-- Each SELECT raises a division-by-zero error if its column is missing.
SELECT 1 / CASE WHEN EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'id'
) THEN 1 ELSE 0 END AS notifications_id_exists;

SELECT 1 / CASE WHEN EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'user_id'
) THEN 1 ELSE 0 END AS notifications_user_id_exists;

SELECT 1 / CASE WHEN EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'type'
) THEN 1 ELSE 0 END AS notifications_type_exists;

SELECT 1 / CASE WHEN EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'title'
) THEN 1 ELSE 0 END AS notifications_title_exists;

SELECT 1 / CASE WHEN EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'message'
) THEN 1 ELSE 0 END AS notifications_message_exists;

SELECT 1 / CASE WHEN EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'data'
) THEN 1 ELSE 0 END AS notifications_data_exists;

SELECT 1 / CASE WHEN EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'is_read'
) THEN 1 ELSE 0 END AS notifications_is_read_exists;

SELECT 1 / CASE WHEN EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'created_at'
) THEN 1 ELSE 0 END AS notifications_created_at_exists;

-- Ensure RLS is enabled.
SELECT 1 / CASE WHEN EXISTS (
  SELECT 1
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname = 'notifications'
    AND c.relrowsecurity = true
) THEN 1 ELSE 0 END AS notifications_rls_enabled;

-- Ensure the notification type constraint stays in sync with the
-- NotificationPayload type used by the send-notification Edge Function.
-- The constraint is created in 20260908_001_initial_schema.sql; this
-- statement is a no-op if it already exists.
ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type IN ('new_offer', 'offer_response', 'new_request', 'verification_status'));
