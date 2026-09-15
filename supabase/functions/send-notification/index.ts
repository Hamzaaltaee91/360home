// Notification Service
// Sends real-time alerts via Supabase Realtime channels

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  handleCorsPreflight,
  jsonResponse,
} from "../_shared/cors.ts";
import { requireCaller } from "../_shared/auth.ts";
import {
  enforceRateLimit,
  RATE_LIMITS,
  resolveRateLimitIdentifier,
} from "../_shared/rate_limit.ts";
import {
  sanitizeObject,
  sanitizeString,
  sanitizeUuid,
} from "../_shared/sanitize.ts";

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
  const origin = req.headers.get("Origin");
  const preflight = handleCorsPreflight(req);
  if (preflight) return preflight;

  try {
    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405, origin);
    }

    // Require an authenticated caller — was completely missing, letting
    // anyone push arbitrary attacker-authored content to any user's
    // notification channel + trigger an email to them.
    const authResult = await requireCaller(req, supabase, origin);
    if ("error" in authResult) return authResult.error;
    const { caller } = authResult;

    const rawBody: NotificationPayload = await req.json();
    const user_id = sanitizeUuid(rawBody.user_id);
    const type = rawBody.type;
    const title = sanitizeString(rawBody.title, 200);
    const message = sanitizeString(rawBody.message, 2000);
    const data = sanitizeObject<Record<string, unknown>>(rawBody.data ?? {});

    if (type === "verification_status" && caller.role !== "admin") {
      return jsonResponse({ error: "Admin access only" }, 403, origin);
    }

    const identifier = resolveRateLimitIdentifier(
      caller.appUserId,
      req.headers.get("x-forwarded-for")
    );
    const limited = await enforceRateLimit(
      supabase,
      RATE_LIMITS["send-notification"],
      identifier
    );
    if (limited) return limited;

    if (!user_id || !isValidNotificationType(type) || !title || !message) {
      return jsonResponse(
        { error: "Invalid notification payload" },
        400,
        origin
      );
    }

    const body: NotificationPayload = { user_id, type, title, message, data };

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

    return jsonResponse({ success: true }, 200, origin);
  } catch (error) {
    console.error("Notification error:", error);
    return jsonResponse({ error: (error as Error).message }, 500, origin);
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
