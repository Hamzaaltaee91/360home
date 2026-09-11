-- Schema verification test for 20260908_001_initial_schema.sql
-- Verifies that all required tables exist.
-- Run with: supabase test db

BEGIN;

SELECT plan(6);

SELECT has_table('public', 'users', 'users table exists');
SELECT has_table('public', 'property_requests', 'property_requests table exists');
SELECT has_table('public', 'realtor_offers', 'realtor_offers table exists');
SELECT has_table('public', 'notifications', 'notifications table exists');
SELECT has_table('public', 'realtor_verifications', 'realtor_verifications table exists');
SELECT has_table('public', 'property_photos', 'property_photos table exists');

SELECT * FROM finish();

ROLLBACK;
