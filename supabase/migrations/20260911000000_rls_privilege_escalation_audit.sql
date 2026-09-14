-- RLS Privilege Escalation Audit
-- Hardens existing RLS policies against privilege escalation vectors.
-- This is an additive migration: it does NOT modify previously applied
-- migrations. It drops and recreates only the policies that need tightening.

-- ---------------------------------------------------------------------------
-- 1. Users table: prevent self-promotion to admin / role tampering.
-- ---------------------------------------------------------------------------
-- Users must never be able to change their own `role` column. Only an admin
-- (or the service role, which bypasses RLS) may change roles.
--
-- NOTE: policies on `public.users` must not query `public.users` directly,
-- otherwise Postgres raises "infinite recursion detected in policy for
-- relation users". We use SECURITY DEFINER helper functions that bypass RLS
-- to read the caller's role safely.
--
-- FIX (applied before this migration was ever deployed): every occurrence
-- below originally compared `id` (public.users' own primary key) against
-- `auth.uid()` (the auth.users identity, exposed on public.users as
-- `auth_id`). Those are different UUIDs for the same person — the
-- comparison would never match, so current_user_role()/is_admin() would
-- always return null/false, and the users_update_own policy would block
-- every user from ever updating their own row, including the admin who
-- redefined is_admin() out from under every RPC that calls it. Corrected
-- to `auth_id = auth.uid()`, matching current_user_id() in
-- 20260908000002_rls_policies.sql (the correct existing convention).

create or replace function public.current_user_role()
  returns text
  language sql
  stable
  security definer
  set search_path = pg_catalog, public
as $$
  select role from public.users where auth_id = auth.uid();
$$;

create or replace function public.is_admin()
  returns boolean
  language sql
  stable
  security definer
  set search_path = pg_catalog, public
as $$
  select exists (
    select 1 from public.users
    where auth_id = auth.uid() and role = 'admin'
  );
$$;

drop policy if exists "users_update_own" on public.users;

create policy "users_update_own"
  on public.users
  for update
  using (auth.uid() = auth_id)
  with check (
    auth.uid() = auth_id
    -- role must remain unchanged for non-admins
    and role = public.current_user_role()
  );

-- Admins may update any user row (including roles).
drop policy if exists "admins_update_users" on public.users;

create policy "admins_update_users"
  on public.users
  for update
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- 2. Property requests / offers: sections removed here (see fix note below).
-- ---------------------------------------------------------------------------
--
-- FIX (applied before this migration was ever deployed — it never appears
-- in `supabase migrations list` for any environment): the original sections
-- 2, 3, 5, and 7 referenced public.requests, public.offers,
-- public.subscriptions, and public.photos — none of which exist. The real
-- table names are public.property_requests and public.realtor_offers
-- (see 20260908000001_initial_schema.sql), there is no subscriptions table
-- (realtor subscriptions were never built), and photos live in
-- public.property_photos / the realtor_offers.photo_urls array, not a
-- separate photos table. Applying this migration unmodified would have
-- errored on the first DROP POLICY against a nonexistent table and blocked
-- every migration after it. The protections these sections intended
-- already exist correctly under the real table names in
-- 20260908000002_rls_policies.sql (property_requests_update_own,
-- realtor_offers_update_own, etc.), so they are not re-added here.
--
-- ---------------------------------------------------------------------------
-- 4. Realtor verifications: realtors may only insert/update their own
--    verification row, and may never set their own status to 'approved'.
--
-- FIX: realtor_verifications.realtor_id references public.users(id), not
-- auth.users(id) — same auth.uid()-vs-app-id bug as section 1. Uses the
-- existing public.current_user_id() helper (20260908000002_rls_policies.sql)
-- instead of raw auth.uid().
-- ---------------------------------------------------------------------------
drop policy if exists "verifications_insert_own" on public.realtor_verifications;

create policy "verifications_insert_own"
  on public.realtor_verifications
  for insert
  with check (
    public.current_user_id() = realtor_id
    and status = 'pending'
  );

drop policy if exists "verifications_update_own" on public.realtor_verifications;

create policy "verifications_update_own"
  on public.realtor_verifications
  for update
  using (public.current_user_id() = realtor_id)
  with check (
    public.current_user_id() = realtor_id
    -- realtors cannot self-approve; status must stay pending on their writes
    and status = 'pending'
  );

-- Only admins may approve/reject verifications.
drop policy if exists "admins_update_verifications" on public.realtor_verifications;

create policy "admins_update_verifications"
  on public.realtor_verifications
  for update
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- 6. Notifications: users may only mark their own notifications as read.
--
-- FIX: notifications.user_id references public.users(id), not
-- auth.users(id) — same bug as sections 1 and 4.
-- ---------------------------------------------------------------------------
drop policy if exists "notifications_update_own" on public.notifications;

create policy "notifications_update_own"
  on public.notifications
  for update
  using (public.current_user_id() = user_id)
  with check (public.current_user_id() = user_id);
