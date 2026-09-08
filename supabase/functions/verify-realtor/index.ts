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

    if (adminUser?.role !== "admin") {
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
      .update({
        status,
        rejection_reason: status === "rejected" ? rejection_reason : null,
        verified_by: user.user.id,
        reviewed_at: new Date().toISOString(),
      })
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
        await supabase
          .from("users")
          .update({ is_verified: true })
          .eq("id", verification.user_id);

        // حدّث verified_at في جدول الوسطاء
        await supabase
          .from("realtors")
          .update({ verified_at: new Date().toISOString() })
          .eq("user_id", verification.user_id);
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
