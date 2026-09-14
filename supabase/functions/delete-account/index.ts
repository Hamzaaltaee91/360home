// Account Deletion Service
//
// Required for App Store (Guideline 5.1.1(v)) and Google Play (User Data
// policy): an app that lets a user create an account must let them delete
// it from within the app. Always deletes the CALLER's own account — the
// caller's identity comes only from their verified JWT, never from a
// client-supplied id, so this cannot be used to delete anyone else's
// account. Deleting the auth.users row cascades (ON DELETE CASCADE) through
// public.users into every table that references it.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { handleCorsPreflight, jsonResponse } from "../_shared/cors.ts";
import {
  enforceRateLimit,
  RATE_LIMITS,
  resolveRateLimitIdentifier,
} from "../_shared/rate_limit.ts";
import { writeAuditLog } from "../_shared/audit.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

serve(async (req) => {
  const origin = req.headers.get("Origin");
  const preflight = handleCorsPreflight(req);
  if (preflight) return preflight;

  try {
    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405, origin);
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Missing Authorization header" }, 401, origin);
    }

    // A client scoped to the caller's own JWT — used only to verify who is
    // calling. Never used to read or write anything on their behalf.
    const callerClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await callerClient.auth.getUser();

    if (userError || !user) {
      return jsonResponse({ error: "Not authenticated" }, 401, origin);
    }

    const identifier = resolveRateLimitIdentifier(
      user.id,
      req.headers.get("x-forwarded-for"),
    );
    const limited = await enforceRateLimit(
      adminClient,
      RATE_LIMITS["delete-account"],
      identifier,
    );
    if (limited) return limited;

    const { error: deleteError } = await adminClient.auth.admin.deleteUser(
      user.id,
    );

    if (deleteError) {
      console.error("account deletion failed:", deleteError.message);
      return jsonResponse({ error: "Failed to delete account" }, 500, origin);
    }

    // actor_id references public.users(id), which was already cascade-
    // deleted by the auth.users deletion above — pass null and keep the
    // deleted id in metadata instead of violating that foreign key.
    await writeAuditLog(adminClient, {
      actorId: null,
      action: "account_deleted",
      entityType: "user",
      entityId: user.id,
      metadata: { self_service: true },
    });

    return jsonResponse({ success: true }, 200, origin);
  } catch (error) {
    console.error("delete-account error:", error);
    return jsonResponse({ error: (error as Error).message }, 500, origin);
  }
});
