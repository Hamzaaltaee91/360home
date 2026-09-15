-- Performance fixes (2026-09-15), from Supabase's own performance
-- advisories. Two safe, additive/behavior-preserving categories only —
-- not touching multiple_permissive_policies (180 findings, needs
-- per-table design review, not a blind bulk edit) or unused_index (58
-- findings — expected noise on a pre-launch app with no real traffic
-- yet; removing them now risks needing them back the moment real usage
-- starts).

-- ---------------------------------------------------------------------------
-- 1. auth_rls_initplan: `auth.uid()` in a policy is re-evaluated per row.
--    Wrapping it as `(select auth.uid())` lets Postgres evaluate it once
--    per query instead. Same 4 policies flagged by get_advisors; logic
--    unchanged, only the auth.uid() call sites are wrapped.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "users_select_own" ON public.users;
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT USING ((select auth.uid()) = auth_id);

DROP POLICY IF EXISTS "users_insert_own" ON public.users;
CREATE POLICY "users_insert_own" ON public.users
  FOR INSERT WITH CHECK ((select auth.uid()) = auth_id);

DROP POLICY IF EXISTS "users_update_own" ON public.users;
CREATE POLICY "users_update_own"
  ON public.users
  FOR UPDATE
  USING ((select auth.uid()) = auth_id)
  WITH CHECK (
    (select auth.uid()) = auth_id
    AND role = public.current_user_role()
    AND is_verified = (SELECT is_verified FROM public.users WHERE auth_id = (select auth.uid()))
  );

DROP POLICY IF EXISTS "audit_logs_admin_select" ON public.audit_logs;
CREATE POLICY "audit_logs_admin_select" ON public.audit_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id = (select auth.uid()) AND u.role = 'admin'
    )
  );

-- ---------------------------------------------------------------------------
-- 2. unindexed_foreign_keys: purely additive covering indexes, no
--    behavior change.
-- ---------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked_id ON public.blocked_users(blocked_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_realtor_verifications_reviewed_by ON public.realtor_verifications(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_reports_message_id ON public.reports(message_id);
CREATE INDEX IF NOT EXISTS idx_reports_reporter_id ON public.reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_reviewed_by ON public.reports(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_verifications_verified_by ON public.verifications(verified_by);
