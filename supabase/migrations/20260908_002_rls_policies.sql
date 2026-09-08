-- Phase 1: Row-Level Security (RLS) Policies for Dabberli
-- Created: 2026-09-08

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

-- Users cannot delete their own profile (admin only)
CREATE POLICY "users_delete_none" ON public.users
  FOR DELETE USING (FALSE);

-- Public can view minimal realtor profiles (verified only)
CREATE POLICY "users_select_realtor_public" ON public.users
  FOR SELECT USING (role = 'realtor' AND is_verified = true);

-- ============================================
-- REALTORS TABLE POLICIES
-- ============================================

-- Realtors can view their own profile
CREATE POLICY "realtors_select_own" ON public.realtors
  FOR SELECT USING (auth.uid() = user_id);

-- Realtors can update their own profile
CREATE POLICY "realtors_update_own" ON public.realtors
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Public can view verified realtor profiles
CREATE POLICY "realtors_select_public" ON public.realtors
  FOR SELECT USING (verified_at IS NOT NULL);

-- ============================================
-- PROPERTY REQUESTS TABLE POLICIES
-- ============================================

-- Buyers can only view their own requests
CREATE POLICY "property_requests_select_own" ON public.property_requests
  FOR SELECT USING (auth.uid() = buyer_id);

-- Buyers can only insert their own requests
CREATE POLICY "property_requests_insert_own" ON public.property_requests
  FOR INSERT WITH CHECK (auth.uid() = buyer_id);

-- Buyers can only update their own requests
CREATE POLICY "property_requests_update_own" ON public.property_requests
  FOR UPDATE USING (auth.uid() = buyer_id)
  WITH CHECK (auth.uid() = buyer_id);

-- Buyers can only delete their own requests
CREATE POLICY "property_requests_delete_own" ON public.property_requests
  FOR DELETE USING (auth.uid() = buyer_id);

-- Realtors can view active requests to create offers
CREATE POLICY "property_requests_select_active_for_realtor" ON public.property_requests
  FOR SELECT USING (
    status = 'active'
    AND expires_at > NOW()
    AND EXISTS (SELECT 1 FROM public.realtors WHERE user_id = auth.uid() AND verified_at IS NOT NULL)
  );

-- ============================================
-- REALTOR OFFERS TABLE POLICIES
-- ============================================

-- Realtors can only view their own offers
CREATE POLICY "realtor_offers_select_own" ON public.realtor_offers
  FOR SELECT USING (auth.uid() = realtor_id);

-- Realtors can create offers
CREATE POLICY "realtor_offers_insert_own" ON public.realtor_offers
  FOR INSERT WITH CHECK (
    auth.uid() = realtor_id
    AND EXISTS (SELECT 1 FROM public.realtors WHERE user_id = auth.uid() AND verified_at IS NOT NULL)
  );

-- Realtors can update their own offers
CREATE POLICY "realtor_offers_update_own" ON public.realtor_offers
  FOR UPDATE USING (auth.uid() = realtor_id)
  WITH CHECK (auth.uid() = realtor_id);

-- Buyers can view offers on their own requests
CREATE POLICY "realtor_offers_select_for_buyer" ON public.realtor_offers
  FOR SELECT USING (
    auth.uid() = (
      SELECT buyer_id FROM public.property_requests WHERE id = request_id
    )
  );

-- Buyers can update offer response (accept/reject)
CREATE POLICY "realtor_offers_update_buyer_response" ON public.realtor_offers
  FOR UPDATE USING (
    auth.uid() = (
      SELECT buyer_id FROM public.property_requests WHERE id = request_id
    )
  )
  WITH CHECK (
    auth.uid() = (
      SELECT buyer_id FROM public.property_requests WHERE id = request_id
    )
    AND (buyer_response IS NULL OR buyer_response IN ('interested', 'not_interested'))
  );

-- ============================================
-- OFFER INTERACTIONS TABLE POLICIES
-- ============================================

-- Only involved parties can view interactions
CREATE POLICY "offer_interactions_select_involved" ON public.offer_interactions
  FOR SELECT USING (
    auth.uid() = buyer_id OR auth.uid() = realtor_id
  );

-- System can insert interactions
CREATE POLICY "offer_interactions_insert" ON public.offer_interactions
  FOR INSERT WITH CHECK (true);

-- ============================================
-- VERIFICATIONS TABLE POLICIES
-- ============================================

-- Users can view their own verification records
CREATE POLICY "verifications_select_own" ON public.verifications
  FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert their own verification records
CREATE POLICY "verifications_insert_own" ON public.verifications
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Only admins can update verification status
CREATE POLICY "verifications_update_admin" ON public.verifications
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
