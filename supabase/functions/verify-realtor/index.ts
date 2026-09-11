// Realtor Verification Service
// Admin approves/rejects realtor license documents

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  handleCorsPreflight,
  jsonResponse,
} from "../_shared/cors.ts";
import {
  enforceRateLimit,
  RATE_LIMITS,
  resolveRateLimitIdentifier,
} from "../_shared/rate_limit.ts";
import {
  sanitizeEnum,
  sanitizeString,
  sanitizeUuid,
} from "../_shared/sanitize.ts";
import { writeAuditLog } from "../_shared/audit.ts";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

interface VerificationRequest {
  verification_id: string;
  status: "approved" | "rejected";
  rejection_reason?: string;
}

// ---------------------------------------------------------------------------
// Pure helpers (exported for unit testing)
// ---------------------------------------------------------------------------

/** Only users with the "admin" role may verify realtors. */
export function isAuthorizedAdmin(role: string | null | undefined): boolean {
  return role === "admin";
}

/**
 * Build the update payload for the `verifications` row.
 * `rejection_reason` is only persisted when the status is "rejected";
 * otherwise it is explicitly cleared.
 */
export function buildVerificationUpdate(
  status: "approved" | "rejected",
  rejectionReason: string | undefined,
  verifiedBy: string,
  reviewedAt: string = new Date().toISOString()
): Record<string, unknown> {
  return {
    status,
    rejection_reason: status === "rejected" ? rejectionReason ?? null : null,
    verified_by: verifiedBy,
    reviewed_at: reviewedAt,
  };
}

/**
 * Build the follow-up updates applied when a verification is approved:
 * mark the user as verified and stamp the realtor's `verified_at`.
 */
export function buildApprovalUpdates(
  userId: string,
  verifiedAt: string = new Date().toISOString()
): {
  user: { table: "users"; values: { is_verified: boolean }; match: { id: string } };
  realtor: {
    table: "realtors";
    values: { verified_at: string };
    match: { user_id: string };
  };
} {
  return {
    user: {
      table: "users",
      values: { is_verified: true },
      match: { id: userId },
    },
    realtor: {
      table: "realtors",
      values: { verified_at: verifiedAt },
      match: { user_id: userId },
    },
  };
}

serve(async (req) => {
  const origin = req.headers.get("Origin");
  const preflight = handleCorsPreflight(req);
  if (preflight) return preflight;

  try {
    // التحقق من أن الطلب POST
    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405, origin);
    }

    // التحقق من أن المستخدم admin
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Missing authorization" }, 401, origin);
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: user, error: userError } = await supabase.auth.getUser(
      token
    );

    if (userError || !user?.user) {
      return jsonResponse({ error: "Unauthorized" }, 401, origin);
    }

    // تحقق من أن المستخدم admin
    const { data: adminUser } = await supabase
      .from("users")
      .select("role")
      .eq("auth_id", user.user.id)
      .single();

    if (!isAuthorizedAdmin(adminUser?.role)) {
      return jsonResponse(
        { error: "Only admins can verify realtors" },
        403,
        origin
      );
    }

    // احصل على بيانات الطلب
    const rawBody: VerificationRequest = await req.json();
    const verification_id = sanitizeUuid(rawBody.verification_id);
    const status = sanitizeEnum(
      rawBody.status,
      ["approved", "rejected"] as const
    );
    const rejection_reason =
      sanitizeString(rawBody.rejection_reason, 1000) || undefined;

    if (!verification_id || !status) {
      return jsonResponse(
        { error: "Invalid verification payload" },
        400,
        origin
      );
    }

    const identifier = resolveRateLimitIdentifier(
      user.user.id,
      req.headers.get("x-forwarded-for")
    );
    const limited = await enforceRateLimit(
      supabase,
      RATE_LIMITS["verify-realtor"],
      identifier
    );
    if (limited) return limited;

    // تحديث حالة التحقق
    const { error: updateError } = await supabase
      .from("verifications")
      .update(buildVerificationUpdate(status, rejection_reason, user.user.id))
      .eq("id", verification_id);

    if (updateError) {
      throw updateError;
    }

    // سجّل عملية التحقق في سجل التدقيق
    await writeAuditLog(supabase, {
      actorId: user.user.id,
      action: `verification_${status}`,
      entityType: "realtor_verification",
      entityId: verification_id,
      metadata: {
        status,
        rejection_reason: rejection_reason ?? null,
      },
    });

    // إذا تمت الموافقة، حدّث is_verified في جدول المستخدمين
    if (status === "approved") {
      const { data: verification } = await supabase
        .from("verifications")
        .select("user_id")
        .eq("id", verification_id)
        .single();

      if (verification) {
        const approval = buildApprovalUpdates(verification.user_id);

        await supabase
          .from(approval.user.table)
          .update(approval.user.values)
          .eq("id", approval.user.match.id);

        // حدّث verified_at في جدول الوسطاء
        await supabase
          .from(approval.realtor.table)
          .update(approval.realtor.values)
          .eq("user_id", approval.realtor.match.user_id);
      }
    }

    return jsonResponse(
      {
        success: true,
        message: `Verification ${status} successfully`,
      },
      200,
      origin
    );
  } catch (error) {
    console.error("Verification error:", error);
    return jsonResponse({ error: (error as Error).message }, 500, origin);
  }
});
