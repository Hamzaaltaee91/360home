-- Critical fix: handle_new_user() honored a client-supplied role.
--
-- Written by hand (not by the autonomous pilot): role assignment, forbidden
-- to the pilot per CONVENTIONS.md §5.
--
-- public.handle_new_user() (20260908000003_functions_and_triggers.sql) did
-- `v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'buyer')`, then only
-- rejected values outside ('buyer','realtor','admin'). raw_user_meta_data
-- is the `data` payload passed to supabase.auth.signUp() — 100%
-- client-controlled. Any signup call with `data: {"role": "admin"}` (or
-- "realtor") got that role with zero verification, bypassing the entire
-- admin-approval flow in 20260911000009_realtor_application_approval.sql.
-- lib/screens/auth/signup_screen.dart's UI even exposed a "realtor" choice
-- in its signup form, calling exactly this path.
--
-- Every account must now start as 'buyer'. Becoming a realtor happens only
-- through submit_realtor_application() + admin approval; becoming an admin
-- happens only through admin_set_user_role(), which itself blocks
-- self-role-changes and requires an existing admin caller.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (auth_id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    'buyer'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
