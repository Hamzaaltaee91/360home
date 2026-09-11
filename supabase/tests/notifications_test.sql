-- Tests for the public.notifications table
-- Run with: supabase test db
--
-- Verifies the table exists with all required columns, RLS is enabled,
-- and the expected policies are present.

BEGIN;

SELECT plan(12);

-- Table exists
SELECT has_table('public', 'notifications', 'notifications table exists');

-- Required columns exist
SELECT has_column('public', 'notifications', 'id', 'notifications.id exists');
SELECT has_column('public', 'notifications', 'user_id', 'notifications.user_id exists');
SELECT has_column('public', 'notifications', 'type', 'notifications.type exists');
SELECT has_column('public', 'notifications', 'title', 'notifications.title exists');
SELECT has_column('public', 'notifications', 'message', 'notifications.message exists');
SELECT has_column('public', 'notifications', 'data', 'notifications.data exists');
SELECT has_column('public', 'notifications', 'is_read', 'notifications.is_read exists');
SELECT has_column('public', 'notifications', 'created_at', 'notifications.created_at exists');

-- RLS is enabled
SELECT is(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.notifications'::regclass),
  true,
  'RLS is enabled on notifications'
);

-- Expected policies exist
SELECT policies_are(
  'public',
  'notifications',
  ARRAY[
    'notifications_select_own',
    'notifications_update_own',
    'notifications_delete_own',
    'notifications_admin_all'
  ],
  'notifications has the expected RLS policies'
);

-- Type constraint exists
SELECT has_check(
  'public',
  'notifications',
  'notifications_type_check',
  'notifications.type has a check constraint'
);

SELECT * FROM finish();

ROLLBACK;
