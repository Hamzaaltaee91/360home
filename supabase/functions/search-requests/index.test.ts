// Unit tests for search-requests pure helpers.
// Run with: deno test --allow-net --allow-env supabase/functions/search-requests/index.test.ts

import {
  assertEquals,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  applyCommonFilters,
  buildCountQuery,
  buildSearchQuery,
  buildSearchResponse,
  normalizeSearchQuery,
  type QueryBuilder,
  type SearchFilters,
} from "./index.ts";

// Records every call made against the query builder so tests can assert
// on the exact chain produced by the helpers.
interface Call {
  method: string;
  args: unknown[];
}

function makeRecorder(): { builder: QueryBuilder; calls: Call[] } {
  const calls: Call[] = [];
  const builder: QueryBuilder = {
    eq(column, value) {
      calls.push({ method: "eq", args: [column, value] });
      return builder;
    },
    ilike(column, pattern) {
      calls.push({ method: "ilike", args: [column, pattern] });
      return builder;
    },
    gte(column, value) {
      calls.push({ method: "gte", args: [column, value] });
      return builder;
    },
    lte(column, value) {
      calls.push({ method: "lte", args: [column, value] });
      return builder;
    },
    order(column, options) {
      calls.push({ method: "order", args: [column, options] });
      return builder;
    },
    range(from, to) {
      calls.push({ method: "range", args: [from, to] });
      return builder;
    },
    rpc(fn, args) {
      calls.push({ method: "rpc", args: [fn, args] });
      return builder;
    },
  };
  return { builder, calls };
}

function baseFilters(overrides: Partial<SearchFilters> = {}): SearchFilters {
  return {
    radius_km: 10,
    sort_by: "recent",
    status: "active",
    limit: 20,
    offset: 0,
    ...overrides,
  };
}

Deno.test("normalizeSearchQuery applies defaults", () => {
  const filters = normalizeSearchQuery({});
  assertEquals(filters.radius_km, 10);
  assertEquals(filters.sort_by, "recent");
  assertEquals(filters.status, "active");
  assertEquals(filters.limit, 20);
  assertEquals(filters.offset, 0);
});

Deno.test("normalizeSearchQuery preserves provided values", () => {
  const filters = normalizeSearchQuery({
    category: "apartment",
    city: "Riyadh",
    min_price: 100000,
    max_price: 500000,
    bedrooms: 3,
    bathrooms: 2,
    latitude: 24.7136,
    longitude: 46.6753,
    radius_km: 25,
    sort_by: "price_low",
    status: "pending",
    limit: 5,
    offset: 10,
  });
  assertEquals(filters.category, "apartment");
  assertEquals(filters.city, "Riyadh");
  assertEquals(filters.min_price, 100000);
  assertEquals(filters.max_price, 500000);
  assertEquals(filters.bedrooms, 3);
  assertEquals(filters.bathrooms, 2);
  assertEquals(filters.latitude, 24.7136);
  assertEquals(filters.longitude, 46.6753);
  assertEquals(filters.radius_km, 25);
  assertEquals(filters.sort_by, "price_low");
  assertEquals(filters.status, "pending");
  assertEquals(filters.limit, 5);
  assertEquals(filters.offset, 10);
});

Deno.test("applyCommonFilters applies category, city, price and rooms", () => {
  const { builder, calls } = makeRecorder();
  applyCommonFilters(
    builder,
    baseFilters({
      category: "villa",
      city: "Jeddah",
      min_price: 200000,
      max_price: 900000,
      bedrooms: 4,
      bathrooms: 3,
    })
  );

  assertEquals(calls, [
    { method: "eq", args: ["category", "villa"] },
    { method: "ilike", args: ["city", "%Jeddah%"] },
    { method: "gte", args: ["min_price", 200000] },
    { method: "lte", args: ["max_price", 900000] },
    { method: "eq", args: ["bedrooms", 4] },
    { method: "eq", args: ["bathrooms", 3] },
  ]);
});

Deno.test("applyCommonFilters skips undefined filters", () => {
  const { builder, calls } = makeRecorder();
  applyCommonFilters(builder, baseFilters());
  assertEquals(calls, []);
});

Deno.test("applyCommonFilters keeps zero-valued price filters", () => {
  const { builder, calls } = makeRecorder();
  applyCommonFilters(builder, baseFilters({ min_price: 0, max_price: 0 }));
  assertEquals(calls, [
    { method: "gte", args: ["min_price", 0] },
    { method: "lte", args: ["max_price", 0] },
  ]);
});

Deno.test("buildSearchQuery adds radius RPC when coordinates provided", () => {
  const { builder, calls } = makeRecorder();
  buildSearchQuery(
    builder,
    baseFilters({ latitude: 24.7136, longitude: 46.6753, radius_km: 15 })
  );

  const rpcCall = calls.find((c) => c.method === "rpc");
  assertEquals(rpcCall, {
    method: "rpc",
    args: [
      "nearby_requests",
      { lat: 24.7136, lng: 46.6753, radius_m: 15000 },
    ],
  });
});

Deno.test("buildSearchQuery omits radius RPC without coordinates", () => {
  const { builder, calls } = makeRecorder();
  buildSearchQuery(builder, baseFilters());
  assertEquals(calls.some((c) => c.method === "rpc"), false);
});

Deno.test("buildSearchQuery omits radius RPC with only latitude", () => {
  const { builder, calls } = makeRecorder();
  buildSearchQuery(builder, baseFilters({ latitude: 24.7136 }));
  assertEquals(calls.some((c) => c.method === "rpc"), false);
});

Deno.test("buildSearchQuery sorts by recent", () => {
  const { builder, calls } = makeRecorder();
  buildSearchQuery(builder, baseFilters({ sort_by: "recent" }));
  assertEquals(calls.find((c) => c.method === "order"), {
    method: "order",
    args: ["created_at", { ascending: false }],
  });
});

Deno.test("buildSearchQuery sorts by price_low", () => {
  const { builder, calls } = makeRecorder();
  buildSearchQuery(builder, baseFilters({ sort_by: "price_low" }));
  assertEquals(calls.find((c) => c.method === "order"), {
    method: "order",
    args: ["min_price", { ascending: true }],
  });
});

Deno.test("buildSearchQuery sorts by price_high", () => {
  const { builder, calls } = makeRecorder();
  buildSearchQuery(builder, baseFilters({ sort_by: "price_high" }));
  assertEquals(calls.find((c) => c.method === "order"), {
    method: "order",
    args: ["max_price", { ascending: false }],
  });
});

Deno.test("buildSearchQuery paginates with offset and limit", () => {
  const { builder, calls } = makeRecorder();
  buildSearchQuery(builder, baseFilters({ offset: 40, limit: 20 }));
  assertEquals(calls.find((c) => c.method === "range"), {
    method: "range",
    args: [40, 59],
  });
});

Deno.test("buildCountQuery applies filters but no sort or pagination", () => {
  const { builder, calls } = makeRecorder();
  buildCountQuery(
    builder,
    baseFilters({ category: "apartment", city: "Dammam", min_price: 50000 })
  );
  assertEquals(calls, [
    { method: "eq", args: ["category", "apartment"] },
    { method: "ilike", args: ["city", "%Dammam%"] },
    { method: "gte", args: ["min_price", 50000] },
  ]);
});

Deno.test("buildSearchResponse reports has_more when more pages exist", () => {
  const response = buildSearchResponse(
    [{ id: 1 }],
    100,
    baseFilters({ offset: 0, limit: 20 })
  );
  assertEquals(response.results, [{ id: 1 }]);
  assertEquals(response.total_count, 100);
  assertEquals(response.has_more, true);
});

Deno.test("buildSearchResponse reports no more on last page", () => {
  const response = buildSearchResponse(
    [{ id: 1 }],
    20,
    baseFilters({ offset: 0, limit: 20 })
  );
  assertEquals(response.has_more, false);
});

Deno.test("buildSearchResponse handles null results and count", () => {
  const response = buildSearchResponse(null, null, baseFilters());
  assertEquals(response.results, []);
  assertEquals(response.total_count, 0);
  assertEquals(response.has_more, false);
});
