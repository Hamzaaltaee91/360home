// Unit tests for the pure helpers in send-notification/index.ts.
// These avoid any live Supabase client by only exercising exported
// pure functions.

import {
  assert,
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  buildNotificationChannel,
  buildRealtimePayload,
  isValidNotificationType,
  type NotificationPayload,
} from "./index.ts";

Deno.test("isValidNotificationType accepts supported types", () => {
  assert(isValidNotificationType("new_offer"));
  assert(isValidNotificationType("offer_response"));
  assert(isValidNotificationType("new_request"));
  assert(isValidNotificationType("verification_status"));
});

Deno.test("isValidNotificationType rejects unsupported values", () => {
  assertFalse(isValidNotificationType("unknown"));
  assertFalse(isValidNotificationType(""));
  assertFalse(isValidNotificationType(undefined));
  assertFalse(isValidNotificationType(null));
  assertFalse(isValidNotificationType(42));
});

Deno.test("buildNotificationChannel namespaces by user id", () => {
  assertEquals(buildNotificationChannel("user-123"), "notifications:user-123");
});

Deno.test("buildRealtimePayload maps fields and preserves data", () => {
  const payload: NotificationPayload = {
    user_id: "user-123",
    type: "new_offer",
    title: "عرض جديد",
    message: "لديك عرض جديد على طلبك",
    data: { offer_id: "offer-1" },
  };

  const result = buildRealtimePayload(payload, "2024-01-01T00:00:00.000Z");

  assertEquals(result.type, "new_offer");
  assertEquals(result.title, "عرض جديد");
  assertEquals(result.message, "لديك عرض جديد على طلبك");
  assertEquals(result.timestamp, "2024-01-01T00:00:00.000Z");
  assertEquals(result.data, { offer_id: "offer-1" });
});

Deno.test("buildRealtimePayload defaults timestamp to now", () => {
  const before = Date.now();
  const result = buildRealtimePayload({
    user_id: "user-123",
    type: "verification_status",
    title: "تم التحقق",
    message: "تمت الموافقة على حسابك",
    data: {},
  });
  const after = Date.now();

  const ts = new Date(result.timestamp).getTime();
  assert(ts >= before && ts <= after);
});
