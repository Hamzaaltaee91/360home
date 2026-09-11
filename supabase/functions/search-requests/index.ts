// Search & Filtering Service
// Advanced search with geospatial queries, budget filters, category sorting

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

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

export interface SearchQuery {
  category?: string;
  city?: string;
  min_price?: number;
  max_price?: number;
  bedrooms?: number;
  bathrooms?: number;
  latitude?: number;
  longitude?: number;
  radius_km?: number; // radius in kilometers
  sort_by?: "recent" | "price_low" | "price_high";
  status?: string;
  limit?: number;
  offset?: number;
}

export interface SearchResponse {
  results: any[];
  total_count: number;
  has_more: boolean;
}

// Minimal structural type for the Supabase query builder so the pure
// helpers below can be unit-tested without a live client.
export interface QueryBuilder {
  eq(column: string, value: unknown): QueryBuilder;
  ilike(column: string, pattern: string): QueryBuilder;
  gte(column: string, value: unknown): QueryBuilder;
  lte(column: string, value: unknown): QueryBuilder;
  order(column: string, options: { ascending: boolean }): QueryBuilder;
  range(from: number, to: number): QueryBuilder;
  rpc(fn: string, args: Record<string, unknown>): QueryBuilder;
}

export interface SearchFilters {
  category?: string;
  city?: string;
  min_price?: number;
  max_price?: number;
  bedrooms?: number;
  bathrooms?: number;
  latitude?: number;
  longitude?: number;
  radius_km: number;
  sort_by: "recent" | "price_low" | "price_high";
  status: string;
  limit: number;
  offset: number;
}

export function normalizeSearchQuery(body: SearchQuery): SearchFilters {
  return {
    category: body.category,
    city: body.city,
    min_price: body.min_price,
    max_price: body.max_price,
    bedrooms: body.bedrooms,
    bathrooms: body.bathrooms,
    latitude: body.latitude,
    longitude: body.longitude,
    radius_km: body.radius_km ?? 10,
    sort_by: body.sort_by ?? "recent",
    status: body.status ?? "active",
    limit: body.limit ?? 20,
    offset: body.offset ?? 0,
  };
}

// Applies the shared filters (category, city, price, rooms) to a query.
export function applyCommonFilters(
  query: QueryBuilder,
  filters: SearchFilters
): QueryBuilder {
  let q = query;

  if (filters.category) {
    q = q.eq("category", filters.category);
  }

  if (filters.city) {
    q = q.ilike("city", `%${filters.city}%`);
  }

  if (filters.min_price !== undefined) {
    q = q.gte("min_price", filters.min_price);
  }

  if (filters.max_price !== undefined) {
    q = q.lte("max_price", filters.max_price);
  }

  if (filters.bedrooms !== undefined) {
    q = q.eq("bedrooms", filters.bedrooms);
  }

  if (filters.bathrooms !== undefined) {
    q = q.eq("bathrooms", filters.bathrooms);
  }

  return q;
}

// Builds the paginated, sorted, geo-aware results query.
export function buildSearchQuery(
  query: QueryBuilder,
  filters: SearchFilters
): QueryBuilder {
  let q = applyCommonFilters(query, filters);

  // فلتر جغرافي (إذا توفرت الإحداثيات)
  if (filters.latitude !== undefined && filters.longitude !== undefined) {
    q = q.rpc("nearby_requests", {
      lat: filters.latitude,
      lng: filters.longitude,
      radius_m: filters.radius_km * 1000,
    });
  }

  // الترتيب
  if (filters.sort_by === "recent") {
    q = q.order("created_at", { ascending: false });
  } else if (filters.sort_by === "price_low") {
    q = q.order("min_price", { ascending: true });
  } else if (filters.sort_by === "price_high") {
    q = q.order("max_price", { ascending: false });
  }

  // التصفح
  return q.range(filters.offset, filters.offset + filters.limit - 1);
}

// Builds the count query (no sorting/pagination/geo).
export function buildCountQuery(
  query: QueryBuilder,
  filters: SearchFilters
): QueryBuilder {
  return applyCommonFilters(query, filters);
}

export function buildSearchResponse(
  results: any[] | null,
  totalCount: number | null,
  filters: SearchFilters
): SearchResponse {
  const total = totalCount ?? 0;
  return {
    results: results ?? [],
    total_count: total,
    has_more: filters.offset + filters.limit < total,
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

    const identifier = resolveRateLimitIdentifier(
      null,
      req.headers.get("x-forwarded-for")
    );
    const limited = await enforceRateLimit(
      supabase,
      RATE_LIMITS["search-requests"],
      identifier
    );
    if (limited) return limited;

    const body: SearchQuery = await req.json();
    const filters = normalizeSearchQuery(body);

    // ابدأ ببناء الاستعلام
    const baseQuery = supabase
      .from("property_requests")
      .select("*")
      .eq("status", filters.status);

    const query = buildSearchQuery(baseQuery, filters);

    const { data: results, error } = await query;

    if (error) {
      throw error;
    }

    // احصل على إجمالي العدد
    const countBase = supabase
      .from("property_requests")
      .select("*", { count: "exact" })
      .eq("status", filters.status);

    const countQuery = buildCountQuery(countBase, filters);

    const { count: totalCount } = await countQuery;

    return jsonResponse(
      buildSearchResponse(results, totalCount, filters),
      200,
      origin
    );
  } catch (error) {
    console.error("Search error:", error);
    return jsonResponse({ error: (error as Error).message }, 500, origin);
  }
});
