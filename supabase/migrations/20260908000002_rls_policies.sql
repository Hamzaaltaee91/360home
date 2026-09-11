-- Phase 1: Row-Level Security (RLS) Policies for Dabberli
-- Created: 2026-09-08

-- ============================================
-- HELPER FUNCTIONS (must be defined before policies)
-- ============================================

-- Resolve the current auth user's public.users.id (bypasses RLS)
CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS UUID AS $$
  SELECT id FROM public.users WHERE auth_id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, auth;

-- Check whether the current auth user is an admin (bypasses RLS to avoid recursion)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users WHERE auth_id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, auth;

-- Ensure the helper functions can bypass RLS regardless of owner privileges
ALTER FUNCTION public.current_user_id() SET row_security = off;
ALTER FUNCTION public.is_admin() SET row_security = off;

-- ============================================
-- USERS TABLE POLICIES
-- ============================================

-- Users can only view their own profile
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT USING (auth.uid() = auth_id);

-- Users can only update their own profile
CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE USING (auth.uid() = auth_id)
  WITH CHECK (auth.uid() = auth_id);

-- Users can insert their own profile (normally done by trigger)
CREATE POLICY "users_insert_own" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = auth_id);

-- Users cannot delete their own profile (admin only)
CREATE POLICY "users_delete_none" ON public.users
  FOR DELETE USING (FALSE);

-- Admins can view and manage all users
CREATE POLICY "users_select_admin" ON public.users
  FOR SELECT USING (public.is_admin());

CREATE POLICY "users_update_admin" ON public.users
  FOR UPDATE USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "users_delete_admin" ON public.users
  FOR DELETE USING (public.is_admin());

-- NOTE: Public realtor visibility is intentionally NOT granted on public.users
-- to avoid leaking PII (email, phone, bio). Use the realtors table's
-- realtors_select_public policy or a dedicated view/RPC for public profiles.

-- ============================================
-- REALTORS TABLE POLICIES
-- ============================================

-- Realtors can view their own profile
CREATE POLICY "realtors_select_own" ON public.realtors
  FOR SELECT USING (public.current_user_id() = user_id);

-- Realtors can create their own profile
CREATE POLICY "realtors_insert_own" ON public.realtors
  FOR INSERT WITH CHECK (public.current_user_id() = user_id);

-- Realtors can delete their own profile
CREATE POLICY "realtors_delete_own" ON public.realtors
  FOR DELETE USING (public.current_user_id() = user_id);

-- Admins can manage all realtor profiles
CREATE POLICY "realtors_admin_all" ON public.realtors
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Realtors can update their own profile
CREATE POLICY "realtors_update_own" ON public.realtors
  FOR UPDATE USING (public.current_user_id() = user_id)
  WITH CHECK (public.current_user_id() = user_id);

-- Public can view verified realtor profiles
CREATE POLICY "realtors_select_public" ON public.realtors
  FOR SELECT USING (verified_at IS NOT NULL);

-- ============================================
-- PROPERTY REQUESTS TABLE POLICIES
-- ============================================

-- Buyers can only view their own requests
CREATE POLICY "property_requests_select_own" ON public.property_requests
  FOR SELECT USING (public.current_user_id() = buyer_id);

-- Buyers can only insert their own requests
CREATE POLICY "property_requests_insert_own" ON public.property_requests
  FOR INSERT WITH CHECK (public.current_user_id() = buyer_id);

-- Buyers can only update their own requests
CREATE POLICY "property_requests_update_own" ON public.property_requests
  FOR UPDATE USING (public.current_user_id() = buyer_id)
  WITH CHECK (public.current_user_id() = buyer_id);

-- Buyers can only delete their own requests
CREATE POLICY "property_requests_delete_own" ON public.property_requests
  FOR DELETE USING (public.current_user_id() = buyer_id);

-- Realtors can view active requests to create offers
CREATE POLICY "property_requests_select_active_for_realtor" ON public.property_requests
  FOR SELECT USING (
    status = 'active'
    AND (expires_at IS NULL OR expires_at > NOW())
    AND EXISTS (SELECT 1 FROM public.realtors WHERE user_id = public.current_user_id() AND verified_at IS NOT NULL)
  );

-- Admins can view and manage all requests
CREATE POLICY "property_requests_admin_all" ON public.property_requests
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ============================================
-- REALTOR OFFERS TABLE POLICIES
-- ============================================

-- Realtors can only view their own offers
CREATE POLICY "realtor_offers_select_own" ON public.realtor_offers
  FOR SELECT USING (public.current_user_id() = realtor_id);

-- Realtors can create offers
CREATE POLICY "realtor_offers_insert_own" ON public.realtor_offers
  FOR INSERT WITH CHECK (
    public.current_user_id() = realtor_id
    AND EXISTS (SELECT 1 FROM public.realtors WHERE user_id = public.current_user_id() AND verified_at IS NOT NULL)
  );

-- Realtors can update their own offers
CREATE POLICY "realtor_offers_update_own" ON public.realtor_offers
  FOR UPDATE USING (public.current_user_id() = realtor_id)
  WITH CHECK (public.current_user_id() = realtor_id);

-- Buyers can view offers on their own requests
CREATE POLICY "realtor_offers_select_for_buyer" ON public.realtor_offers
  FOR SELECT USING (
    public.current_user_id() = (
      SELECT buyer_id FROM public.property_requests WHERE id = realtor_offers.request_id
    )
  );

-- Buyers can update offer response (accept/reject)
CREATE POLICY "realtor_offers_update_buyer_response" ON public.realtor_offers
  FOR UPDATE USING (
    public.current_user_id() = (
      SELECT buyer_id FROM public.property_requests WHERE id = realtor_offers.request_id
    )
  )
  WITH CHECK (
    public.current_user_id() = (
      SELECT buyer_id FROM public.property_requests WHERE id = realtor_offers.request_id
    )
    AND (buyer_response IS NULL OR buyer_response IN ('interested', 'not_interested'))
  );

-- Realtors can delete their own offers
CREATE POLICY "realtor_offers_delete_own" ON public.realtor_offers
  FOR DELETE USING (public.current_user_id() = realtor_id);

-- Admins can manage all offers
CREATE POLICY "realtor_offers_admin_all" ON public.realtor_offers
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ============================================
-- OFFER INTERACTIONS TABLE POLICIES
-- ============================================

-- Only involved parties can view interactions
CREATE POLICY "offer_interactions_select_involved" ON public.offer_interactions
  FOR SELECT USING (
    public.current_user_id() = buyer_id OR public.current_user_id() = realtor_id
  );

-- Only involved parties can insert interactions
CREATE POLICY "offer_interactions_insert_involved" ON public.offer_interactions
  FOR INSERT WITH CHECK (
    public.current_user_id() = buyer_id OR public.current_user_id() = realtor_id
  );

-- Admins can view all interactions
CREATE POLICY "offer_interactions_select_admin" ON public.offer_interactions
  FOR SELECT USING (public.is_admin());

-- ============================================
-- VERIFICATIONS TABLE POLICIES
-- ============================================

-- Users can view their own verification records
CREATE POLICY "verifications_select_own" ON public.verifications
  FOR SELECT USING (public.current_user_id() = user_id);

-- Users can only insert their own verification records
CREATE POLICY "verifications_insert_own" ON public.verifications
  FOR INSERT WITH CHECK (public.current_user_id() = user_id);

-- Only admins can update verification status
CREATE POLICY "verifications_update_admin" ON public.verifications
  FOR UPDATE USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Admins can view all verifications
CREATE POLICY "verifications_select_admin" ON public.verifications
  FOR SELECT USING (public.is_admin());

-- Admins can delete verifications
CREATE POLICY "verifications_delete_admin" ON public.verifications
  FOR DELETE USING (public.is_admin());

-- ============================================
-- NOTIFICATIONS TABLE POLICIES
-- ============================================

-- Users can view their own notifications
CREATE POLICY "notifications_select_own" ON public.notifications
  FOR SELECT USING (public.current_user_id() = user_id);

-- Users can mark their own notifications as read
CREATE POLICY "notifications_update_own" ON public.notifications
  FOR UPDATE USING (public.current_user_id() = user_id)
  WITH CHECK (public.current_user_id() = user_id);

-- Users can delete their own notifications
CREATE POLICY "notifications_delete_own" ON public.notifications
  FOR DELETE USING (public.current_user_id() = user_id);

-- Admins can manage all notifications
CREATE POLICY "notifications_admin_all" ON public.notifications
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ============================================
-- REALTOR VERIFICATIONS TABLE POLICIES
-- ============================================

-- Realtors can view their own verification requests
CREATE POLICY "realtor_verifications_select_own" ON public.realtor_verifications
  FOR SELECT USING (public.current_user_id() = realtor_id);

-- Realtors can submit their own verification requests
CREATE POLICY "realtor_verifications_insert_own" ON public.realtor_verifications
  FOR INSERT WITH CHECK (public.current_user_id() = realtor_id);

-- Admins can review and update verification requests
CREATE POLICY "realtor_verifications_update_admin" ON public.realtor_verifications
  FOR UPDATE USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Admins can view all verification requests
CREATE POLICY "realtor_verifications_select_admin" ON public.realtor_verifications
  FOR SELECT USING (public.is_admin());

-- Admins can delete verification requests
CREATE POLICY "realtor_verifications_delete_admin" ON public.realtor_verifications
  FOR DELETE USING (public.is_admin());

-- ============================================
-- PROPERTY PHOTOS TABLE POLICIES
-- ============================================

-- Owners (buyer of the request or realtor of the offer) can view photos
CREATE POLICY "property_photos_select_owner" ON public.property_photos
  FOR SELECT USING (
    (request_id IS NOT NULL AND public.current_user_id() = (
      SELECT buyer_id FROM public.property_requests WHERE id = property_photos.request_id
    ))
    OR
    (offer_id IS NOT NULL AND public.current_user_id() = (
      SELECT realtor_id FROM public.realtor_offers WHERE id = property_photos.offer_id
    ))
    OR
    (offer_id IS NOT NULL AND public.current_user_id() = (
      SELECT pr.buyer_id
      FROM public.realtor_offers ro
      JOIN public.property_requests pr ON pr.id = ro.request_id
      WHERE ro.id = property_photos.offer_id
    ))
  );

-- Owners can insert photos for their own request/offer
CREATE POLICY "property_photos_insert_owner" ON public.property_photos
  FOR INSERT WITH CHECK (
    (request_id IS NOT NULL AND public.current_user_id() = (
      SELECT buyer_id FROM public.property_requests WHERE id = property_photos.request_id
    ))
    OR
    (offer_id IS NOT NULL AND public.current_user_id() = (
      SELECT realtor_id FROM public.realtor_offers WHERE id = property_photos.offer_id
    ))
  );

-- Owners can update their own photos
CREATE POLICY "property_photos_update_owner" ON public.property_photos
  FOR UPDATE USING (
    (request_id IS NOT NULL AND public.current_user_id() = (
      SELECT buyer_id FROM public.property_requests WHERE id = property_photos.request_id
    ))
    OR
    (offer_id IS NOT NULL AND public.current_user_id() = (
      SELECT realtor_id FROM public.realtor_offers WHERE id = property_photos.offer_id
    ))
  )
  WITH CHECK (
    (request_id IS NOT NULL AND public.current_user_id() = (
      SELECT buyer_id FROM public.property_requests WHERE id = property_photos.request_id
    ))
    OR
    (offer_id IS NOT NULL AND public.current_user_id() = (
      SELECT realtor_id FROM public.realtor_offers WHERE id = property_photos.offer_id
    ))
  );

-- Owners can delete their own photos
CREATE POLICY "property_photos_delete_owner" ON public.property_photos
  FOR DELETE USING (
    (request_id IS NOT NULL AND public.current_user_id() = (
      SELECT buyer_id FROM public.property_requests WHERE id = property_photos.request_id
    ))
    OR
    (offer_id IS NOT NULL AND public.current_user_id() = (
      SELECT realtor_id FROM public.realtor_offers WHERE id = property_photos.offer_id
    ))
  );

-- Admins can manage all photos
CREATE POLICY "property_photos_admin_all" ON public.property_photos
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());
