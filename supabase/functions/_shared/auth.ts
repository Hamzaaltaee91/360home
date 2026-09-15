// Shared caller-authentication helper for Edge Functions.
//
// Verifies the caller's JWT (never trust a client-supplied user_id/
// realtor_id/buyer_id) and resolves it to the caller's public.users row
// (id + role). Mirrors the pattern already used correctly in
// delete-account/index.ts, generalized for reuse.

import {
  createClient,
  SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";
import { jsonResponse } from "./cors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

export interface CallerAppUser {
  authId: string; // auth.users.id, from the verified JWT
  appUserId: string; // public.users.id — what realtor_id/buyer_id/user_id columns reference
  role: string; // 'buyer' | 'realtor' | 'admin'
}

/**
 * Verifies the request's Authorization header against Supabase Auth and
 * resolves the caller's public.users row. Returns either the resolved
 * caller, or a 401 Response the handler should return immediately.
 *
 * `adminClient` must be a service-role client — used only to read the
 * CALLER'S OWN public.users row (looked up by their own verified auth id),
 * never anyone else's.
 */
export async function requireCaller(
  req: Request,
  adminClient: SupabaseClient,
  origin: string | null,
): Promise<{ caller: CallerAppUser } | { error: Response }> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return {
      error: jsonResponse({ error: "Missing Authorization header" }, 401, origin),
    };
  }

  const callerClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user },
    error: userError,
  } = await callerClient.auth.getUser();

  if (userError || !user) {
    return { error: jsonResponse({ error: "Not authenticated" }, 401, origin) };
  }

  const { data: appUser, error: appUserError } = await adminClient
    .from("users")
    .select("id, role")
    .eq("auth_id", user.id)
    .single();

  if (appUserError || !appUser) {
    return {
      error: jsonResponse({ error: "User profile not found" }, 401, origin),
    };
  }

  return {
    caller: { authId: user.id, appUserId: appUser.id, role: appUser.role },
  };
}
