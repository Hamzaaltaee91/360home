// Shared rate-limiting helper for Edge Functions.
//
// Backed by public.rate_limit_hits (see
// supabase/migrations/20260914000004_rate_limit_hits.sql), written to and
// read from using the caller's service-role client, so it works
// regardless of RLS. Fails open on infrastructure errors — a rate-limit
// check that can't run should never block legitimate traffic.

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { jsonResponse } from "./cors.ts";

export interface RateLimitConfig {
  functionName: string;
  maxRequests: number;
  windowSeconds: number;
}

export const RATE_LIMITS: Record<string, RateLimitConfig> = {
  analytics: { functionName: "analytics", maxRequests: 30, windowSeconds: 60 },
  "match-offers": {
    functionName: "match-offers",
    maxRequests: 30,
    windowSeconds: 60,
  },
  "search-requests": {
    functionName: "search-requests",
    maxRequests: 60,
    windowSeconds: 60,
  },
  "send-notification": {
    functionName: "send-notification",
    maxRequests: 100,
    windowSeconds: 60,
  },
  "delete-account": {
    functionName: "delete-account",
    maxRequests: 5,
    windowSeconds: 300,
  },
};

/** Prefers the authenticated user id; falls back to the first forwarded IP. */
export function resolveRateLimitIdentifier(
  userId: string | null | undefined,
  forwardedFor: string | null,
): string {
  if (userId) return `user:${userId}`;
  const ip = forwardedFor?.split(",")[0]?.trim();
  return ip ? `ip:${ip}` : "anonymous";
}

/**
 * Checks and records one hit against `config` for `identifier`. Returns a
 * 429 Response when the limit is exceeded, or `null` to proceed —
 * callers should `return limited` only when this is non-null.
 */
export async function enforceRateLimit(
  supabase: SupabaseClient,
  config: RateLimitConfig,
  identifier: string,
): Promise<Response | null> {
  const windowStart = new Date(
    Date.now() - config.windowSeconds * 1000,
  ).toISOString();

  const { count, error: countError } = await supabase
    .from("rate_limit_hits")
    .select("id", { count: "exact", head: true })
    .eq("function_name", config.functionName)
    .eq("identifier", identifier)
    .gte("created_at", windowStart);

  if (countError) {
    console.error("rate limit check failed:", countError.message);
    return null;
  }

  if ((count ?? 0) >= config.maxRequests) {
    return jsonResponse(
      { error: "Too many requests, please try again later" },
      429,
    );
  }

  const { error: insertError } = await supabase
    .from("rate_limit_hits")
    .insert({ function_name: config.functionName, identifier });
  if (insertError) {
    console.error("rate limit hit insert failed:", insertError.message);
  }

  return null;
}
