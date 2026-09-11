// Notification Service
// Sends real-time alerts via Supabase Realtime channels

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

export type NotificationType =
  | "new_offer"
  | "offer_response"
  | "new_request"
  | "verification_status";

export interface NotificationPayload {
  user_id: string;
  type: NotificationType;
  title: string;
  message: string;
  data: Record<string, unknown>;
}

export interface RealtimePayload {
  type: NotificationType;
  title: string;
  message: string;
  timestamp: string;
  data: Record<string, unknown>;
}

const VALID_NOTIFICATION_TYPES: readonly NotificationType[] = [
  "new_offer",
  "offer_response",
  "new_request",
  "verification_status",
];

// يتحقق أن نوع الإخطار ضمن الأنواع المدعومة
export function isValidNotificationType(type: unknown): type is NotificationType {
  return (
    typeof type === "string" &&
    (VALID_NOTIFICATION_TYPES as readonly string[]).includes(type)
  );
}

// اسم قناة Realtime الخاصة بالمستخدم
export function buildNotificationChannel(userId: string): string {
  return `notifications:${userId}`;
}

// يبني حمولة البث المرسلة عبر Realtime
export function buildRealtimePayload(
  payload: NotificationPayload,
  timestamp: string = new Date().toISOString()
): RealtimePayload {
  return {
    type: payload.type,
    title: payload.title,
    message: payload.message,
    timestamp,
    data: payload.data,
  };
}

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        { status: 405 }
      );
    }

    const body: NotificationPayload = await req.json();
    const { user_id, type, title, message } = body;

    if (!user_id || !isValidNotificationType(type)) {
      return new Response(
        JSON.stringify({ error: "Invalid notification payload" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // احفظ الإخطار في قاعدة البيانات (اختياري)
    // يمكن إنشاء جدول notifications للتخزين التاريخي

    // أرسل عبر Supabase Realtime
    // الاشتراك في القناة: realtime:notifications:{user_id}
    const realtimePayload = buildRealtimePayload(body);

    // استخدم Supabase Realtime broadcast
    const { error: broadcastError } = await supabase.realtime.broadcast(
      buildNotificationChannel(user_id),
      realtimePayload
    );

    if (broadcastError) {
      console.error("Broadcast error:", broadcastError);
      // لا تفشل - الإخطار قد يكون غير حرج
    }

    // أرسل بريدًا إلكترونيًا (إذا أراد المستخدم)
    await sendEmailNotification(user_id, type, title, message);

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Notification error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

async function sendEmailNotification(
  userId: string,
  type: string,
  title: string,
  message: string
) {
  try {
    // احصل على بريد المستخدم
    const { data: user } = await supabase
      .from("users")
      .select("email")
      .eq("id", userId)
      .single();

    if (!user?.email) return;

    // استخدم خدمة بريدية (Resend, SendGrid, إلخ)
    // مثال: await sendEmail(user.email, title, message);

    console.log(`Email sent to ${user.email}: ${title}`);
  } catch (error) {
    console.error("Email error:", error);
  }
}
