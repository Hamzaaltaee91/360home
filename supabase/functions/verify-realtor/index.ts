// Realtor Verification Service
// Admin approves/rejects realtor license documents

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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
  try {
    // التحقق من أن الطلب POST
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        { status: 405 }
      );
    }

    // التحقق من أن المستخدم admin
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization" }),
        { status: 401 }
      );
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: user, error: userError } = await supabase.auth.getUser(
      token
    );

    if (userError || !user?.user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401 }
      );
    }

    // تحقق من أن المستخدم admin
    const { data: adminUser } = await supabase
      .from("users")
      .select("role")
      .eq("auth_id", user.user.id)
      .single();

    if (!isAuthorizedAdmin(adminUser?.role)) {
      return new Response(
        JSON.stringify({ error: "Only admins can verify realtors" }),
        { status: 403 }
      );
    }

    // احصل على بيانات الطلب
    const body: VerificationRequest = await req.json();
    const { verification_id, status, rejection_reason } = body;

    // تحديث حالة التحقق
    const { error: updateError } = await supabase
      .from("verifications")
      .update(buildVerificationUpdate(status, rejection_reason, user.user.id))
      .eq("id", verification_id);

    if (updateError) {
      throw updateError;
    }

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

    return new Response(
      JSON.stringify({
        success: true,
        message: `Verification ${status} successfully`,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Verification error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
