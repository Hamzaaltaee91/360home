import {
  assertEquals,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  buildApprovalUpdates,
  buildVerificationUpdate,
  isAuthorizedAdmin,
} from "./index.ts";

// ---------------------------------------------------------------------------
// isAuthorizedAdmin
// ---------------------------------------------------------------------------

Deno.test("isAuthorizedAdmin - returns true only for admin role", () => {
  assertEquals(isAuthorizedAdmin("admin"), true);
  assertEquals(isAuthorizedAdmin("buyer"), false);
  assertEquals(isAuthorizedAdmin("realtor"), false);
});

Deno.test("isAuthorizedAdmin - returns false for null or undefined", () => {
  assertEquals(isAuthorizedAdmin(null), false);
  assertEquals(isAuthorizedAdmin(undefined), false);
});

// ---------------------------------------------------------------------------
// buildVerificationUpdate
// ---------------------------------------------------------------------------

Deno.test("buildVerificationUpdate - approval clears rejection_reason", () => {
  const update = buildVerificationUpdate(
    "approved",
    "some reason",
    "admin-1",
    "2024-01-01T00:00:00Z"
  );
  assertEquals(update, {
    status: "approved",
    rejection_reason: null,
    verified_by: "admin-1",
    reviewed_at: "2024-01-01T00:00:00Z",
  });
});

Deno.test("buildVerificationUpdate - rejection persists the reason", () => {
  const update = buildVerificationUpdate(
    "rejected",
    "license expired",
    "admin-1",
    "2024-01-01T00:00:00Z"
  );
  assertEquals(update, {
    status: "rejected",
    rejection_reason: "license expired",
    verified_by: "admin-1",
    reviewed_at: "2024-01-01T00:00:00Z",
  });
});

Deno.test("buildVerificationUpdate - rejection without reason stores null", () => {
  const update = buildVerificationUpdate(
    "rejected",
    undefined,
    "admin-1",
    "2024-01-01T00:00:00Z"
  );
  assertEquals(update.rejection_reason, null);
});

Deno.test("buildVerificationUpdate - defaults reviewed_at to now", () => {
  const before = Date.now();
  const update = buildVerificationUpdate("approved", undefined, "admin-1");
  const after = Date.now();
  const reviewedAt = new Date(update.reviewed_at as string).getTime();
  assertEquals(reviewedAt >= before && reviewedAt <= after, true);
});

// ---------------------------------------------------------------------------
// buildApprovalUpdates
// ---------------------------------------------------------------------------

Deno.test("buildApprovalUpdates - marks user verified and stamps realtor", () => {
  const approval = buildApprovalUpdates("user-42", "2024-01-01T00:00:00Z");
  assertEquals(approval, {
    user: {
      table: "users",
      values: { is_verified: true },
      match: { id: "user-42" },
    },
    realtor: {
      table: "realtors",
      values: { verified_at: "2024-01-01T00:00:00Z" },
      match: { user_id: "user-42" },
    },
  });
});

Deno.test("buildApprovalUpdates - defaults verified_at to now", () => {
  const before = Date.now();
  const approval = buildApprovalUpdates("user-42");
  const after = Date.now();
  const verifiedAt = new Date(approval.realtor.values.verified_at).getTime();
  assertEquals(verifiedAt >= before && verifiedAt <= after, true);
});
