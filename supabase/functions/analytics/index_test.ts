import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  computeBuyerStats,
  computePlatformStats,
  computeRealtorStats,
} from "./index.ts";

// ---------------------------------------------------------------------------
// computeRealtorStats
// ---------------------------------------------------------------------------

Deno.test("computeRealtorStats - returns zeros when offers is null", () => {
  const stats = computeRealtorStats(null, null);
  assertEquals(stats, {
    total_offers: 0,
    accepted_offers: 0,
    rejected_offers: 0,
    pending_offers: 0,
    average_response_time: 0,
    total_interactions: 0,
  });
});

Deno.test("computeRealtorStats - counts accepted, rejected and pending", () => {
  const offers = [
    { status: "pending", buyer_response: "interested", created_at: "2024-01-01T00:00:00Z", updated_at: "2024-01-01T00:00:00Z" },
    { status: "pending", buyer_response: "not_interested", created_at: "2024-01-01T00:00:00Z", updated_at: "2024-01-01T00:00:00Z" },
    { status: "pending", buyer_response: null, created_at: "2024-01-01T00:00:00Z", updated_at: "2024-01-01T00:00:00Z" },
    { status: "closed", buyer_response: "interested", created_at: "2024-01-01T00:00:00Z", updated_at: "2024-01-01T00:00:00Z" },
  ];
  const stats = computeRealtorStats(offers, [{}, {}]);
  assertEquals(stats.total_offers, 4);
  assertEquals(stats.accepted_offers, 2);
  assertEquals(stats.rejected_offers, 1);
  assertEquals(stats.pending_offers, 3);
  assertEquals(stats.total_interactions, 2);
});

Deno.test("computeRealtorStats - computes average response time in hours", () => {
  const offers = [
    { status: "pending", buyer_response: null, created_at: "2024-01-01T00:00:00Z", updated_at: "2024-01-01T02:00:00Z" }, // 2h
    { status: "pending", buyer_response: null, created_at: "2024-01-01T00:00:00Z", updated_at: "2024-01-01T04:00:00Z" }, // 4h
  ];
  const stats = computeRealtorStats(offers, null);
  assertEquals(stats.average_response_time, 3);
});

Deno.test("computeRealtorStats - ignores offers with no update", () => {
  const offers = [
    { status: "pending", buyer_response: null, created_at: "2024-01-01T00:00:00Z", updated_at: "2024-01-01T00:00:00Z" },
  ];
  const stats = computeRealtorStats(offers, null);
  assertEquals(stats.average_response_time, 0);
});

// ---------------------------------------------------------------------------
// computeBuyerStats
// ---------------------------------------------------------------------------

Deno.test("computeBuyerStats - handles null inputs", () => {
  const stats = computeBuyerStats(null, null);
  assertEquals(stats, {
    total_requests: 0,
    active_requests: 0,
    total_offers_received: 0,
    total_offers_accepted: 0,
    response_rate: 0,
  });
});

Deno.test("computeBuyerStats - counts active requests and accepted offers", () => {
  const requests = [
    { id: "r1", status: "active" },
    { id: "r2", status: "closed" },
    { id: "r3", status: "active" },
  ];
  const offers = [
    { id: "o1", buyer_response: "interested" },
    { id: "o2", buyer_response: "not_interested" },
    { id: "o3", buyer_response: null },
  ];
  const stats = computeBuyerStats(requests, offers);
  assertEquals(stats.total_requests, 3);
  assertEquals(stats.active_requests, 2);
  assertEquals(stats.total_offers_received, 3);
  assertEquals(stats.total_offers_accepted, 1);
  // 2 of 3 offers have a response -> 67%
  assertEquals(stats.response_rate, 67);
});

Deno.test("computeBuyerStats - response_rate is 0 when no offers", () => {
  const stats = computeBuyerStats([{ id: "r1", status: "active" }], []);
  assertEquals(stats.response_rate, 0);
});

// ---------------------------------------------------------------------------
// computePlatformStats
// ---------------------------------------------------------------------------

Deno.test("computePlatformStats - handles null inputs", () => {
  const stats = computePlatformStats(null, null, null, "2024-01-01", "2024-01-31");
  assertEquals(stats.period, { from: "2024-01-01", to: "2024-01-31" });
  assertEquals(stats.new_users, { total: 0, buyers: 0, realtors: 0 });
  assertEquals(stats.property_requests, 0);
  assertEquals(stats.realtor_offers, 0);
  assertEquals(stats.offer_acceptance_rate, 0);
  assertEquals(stats.average_offers_per_request, 0);
});

Deno.test("computePlatformStats - aggregates users, requests and offers", () => {
  const users = [
    { id: "u1", role: "buyer" },
    { id: "u2", role: "buyer" },
    { id: "u3", role: "realtor" },
    { id: "u4", role: "admin" },
  ];
  const requests = [{ id: "r1" }, { id: "r2" }];
  const offers = [
    { id: "o1", buyer_response: "interested" },
    { id: "o2", buyer_response: "not_interested" },
    { id: "o3", buyer_response: "interested" },
    { id: "o4", buyer_response: null },
  ];
  const stats = computePlatformStats(users, requests, offers, "2024-01-01", "2024-01-31");
  assertEquals(stats.new_users, { total: 4, buyers: 2, realtors: 1 });
  assertEquals(stats.property_requests, 2);
  assertEquals(stats.realtor_offers, 4);
  // 2 of 4 offers accepted -> 50%
  assertEquals(stats.offer_acceptance_rate, 50);
  // 4 offers / 2 requests -> 2
  assertEquals(stats.average_offers_per_request, 2);
});

Deno.test("computePlatformStats - average_offers_per_request is 0 with no requests", () => {
  const stats = computePlatformStats([], [], [{ id: "o1" }], "2024-01-01", "2024-01-31");
  assertEquals(stats.average_offers_per_request, 0);
});
