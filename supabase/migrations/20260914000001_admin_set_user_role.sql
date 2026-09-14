-- Admin role assignment via a single audited RPC.
--
-- Written by hand (not by the autonomous pilot): CONVENTIONS.md §5 forbids
-- the pilot from ever touching role assignment. lib/screens/admin/
-- manage_users_screen.dart previously called a raw
-- `_client.from('users').update({'role': role})` (RLS-protected by the
-- existing "admins_update_users" policy, unchanged here), bypassing any
-- application-level validation. This RPC gives that one remaining
-- role-write client call a single, auditable, server-validated path,
-- matching the pattern already used for realtor applications in
-- 20260911000009_realtor_application_approval.sql.

CREATE OR REPLACE FUNCTION public.admin_set_user_role(
  p_user_id UUID,
  p_role TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID;
BEGIN
  v_admin_id := public.current_user_id();

  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admins only';
  END IF;

  IF p_role NOT IN ('buyer', 'realtor', 'admin') THEN
    RAISE EXCEPTION 'Invalid role: %', p_role;
  END IF;

  IF p_user_id = v_admin_id AND p_role <> 'admin' THEN
    RAISE EXCEPTION 'Cannot change your own role';
  END IF;

  UPDATE public.users
  SET role = p_role
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;
END;
$$;
