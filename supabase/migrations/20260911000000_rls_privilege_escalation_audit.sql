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

create or replace function public.current_user_role()
  returns text
  language sql
  stable
  security definer
  set search_path = pg_catalog, public
as $$
  select role from public.users where id = auth.uid();
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
    where id = auth.uid() and role = 'admin'
  );
$$;

drop policy if exists "users_update_own" on public.users;

create policy "users_update_own"
  on public.users
  for update
  using (auth.uid() = id)
  with check (
    auth.uid() = id
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
-- 2. Property requests: buyers may only mutate their own requests.
-- ---------------------------------------------------------------------------
drop policy if exists "requests_update_own" on public.requests;

create policy "requests_update_own"
  on public.requests
  for update
  using (auth.uid() = buyer_id)
  with check (auth.uid() = buyer_id);

drop policy if exists "requests_delete_own" on public.requests;

create policy "requests_delete_own"
  on public.requests
  for delete
  using (auth.uid() = buyer_id);

-- ---------------------------------------------------------------------------
-- 3. Offers: realtors may only mutate their own offers, and only while the
--    parent request is still open (no editing offers on closed requests).
-- ---------------------------------------------------------------------------
drop policy if exists "offers_update_own" on public.offers;

create policy "offers_update_own"
  on public.offers
  for update
  using (
    auth.uid() = realtor_id
    and exists (
      select 1 from public.requests r
      where r.id = offers.request_id and r.status = 'open'
    )
  )
  with check (auth.uid() = realtor_id);

drop policy if exists "offers_delete_own" on public.offers;

create policy "offers_delete_own"
  on public.offers
  for delete
  using (
    auth.uid() = realtor_id
    and exists (
      select 1 from public.requests r
      where r.id = offers.request_id and r.status = 'open'
    )
  );

-- ---------------------------------------------------------------------------
-- 4. Realtor verifications: realtors may only insert/update their own
--    verification row, and may never set their own status to 'approved'.
-- ---------------------------------------------------------------------------
drop policy if exists "verifications_insert_own" on public.realtor_verifications;

create policy "verifications_insert_own"
  on public.realtor_verifications
  for insert
  with check (
    auth.uid() = realtor_id
    and status = 'pending'
  );

drop policy if exists "verifications_update_own" on public.realtor_verifications;

create policy "verifications_update_own"
  on public.realtor_verifications
  for update
  using (auth.uid() = realtor_id)
  with check (
    auth.uid() = realtor_id
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
-- 5. Subscriptions: users may read their own subscription but never write
--    to it directly (writes happen via Edge Functions using the service role).
-- ---------------------------------------------------------------------------
drop policy if exists "subscriptions_insert_own" on public.subscriptions;
drop policy if exists "subscriptions_update_own" on public.subscriptions;
drop policy if exists "subscriptions_delete_own" on public.subscriptions;

-- ---------------------------------------------------------------------------
-- 6. Notifications: users may only mark their own notifications as read.
-- ---------------------------------------------------------------------------
drop policy if exists "notifications_update_own" on public.notifications;

create policy "notifications_update_own"
  on public.notifications
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- 7. Photos: owners may only mutate photos attached to their own entities.
-- ---------------------------------------------------------------------------
drop policy if exists "photos_delete_own" on public.photos;

create policy "photos_delete_own"
  on public.photos
  for delete
  using (
    exists (
      select 1 from public.requests r
      where r.id = photos.request_id and r.buyer_id = auth.uid()
    )
    or exists (
      select 1 from public.offers o
      where o.id = photos.offer_id and o.realtor_id = auth.uid()
    )
  );
