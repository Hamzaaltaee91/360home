// Offer Matching Engine
// Recommends matching property requests to realtors based on criteria

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
import { sanitizeInt, sanitizeString, sanitizeUuid } from "../_shared/sanitize.ts";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

interface MatchRequest {
  realtor_id: string;
  category?: string;
  limit?: number;
}

interface PropertyMatch {
  request_id: string;
  buyer_id: string;
  category: string;
  title: string;
  city: string;
  min_price: number;
  max_price: number;
  bedrooms?: number;
  bathrooms?: number;
  match_score: number;
}

// احسب درجة المطابقة (0-100) لطلب واحد مقابل وسيط
export function computeMatchScore(
  request: any,
  options: { hasExistingOffer: boolean; now?: number }
): number {
  const now = options.now ?? Date.now();
  let matchScore = 50; // درجة أساسية

  // +20 إذا كان الطلب حديثًا (أقل من 7 أيام)
  const requestAge =
    (now - new Date(request.created_at).getTime()) / (1000 * 60 * 60 * 24);
  if (requestAge < 7) matchScore += 20;

  // +15 إذا لم يكن هناك عرض سابق
  if (!options.hasExistingOffer) matchScore += 15;

  // -10 إذا كان الطلب عاجلًا (ربما أقل عرضًا)
  if (request.is_urgent) matchScore -= 10;

  return Math.max(0, Math.min(100, matchScore));
}

// ابنِ قائمة المطابقات مرتبة حسب درجة المطابقة
export function buildMatches(
  requests: any[],
  existingOfferRequestIds: Set<string>,
  now?: number
): PropertyMatch[] {
  const matches: PropertyMatch[] = requests.map((request: any) => ({
    request_id: request.id,
    buyer_id: request.buyer_id,
    category: request.category,
    title: request.title,
    city: request.city,
    min_price: request.min_price,
    max_price: request.max_price,
    bedrooms: request.bedrooms,
    bathrooms: request.bathrooms,
    match_score: computeMatchScore(request, {
      hasExistingOffer: existingOfferRequestIds.has(request.id),
      now,
    }),
  }));

  matches.sort((a, b) => b.match_score - a.match_score);
  return matches;
}

serve(async (req) => {
  const origin = req.headers.get("Origin");
  const preflight = handleCorsPreflight(req);
  if (preflight) return preflight;

  try {
    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405, origin);
    }

    const body: MatchRequest = await req.json();
    const realtor_id = sanitizeUuid(body.realtor_id);
    const category = sanitizeString(body.category, 64) || undefined;
    const limit = sanitizeInt(body.limit, { min: 1, max: 100 }) ?? 10;

    if (!realtor_id) {
      return jsonResponse({ error: "Invalid realtor_id" }, 400, origin);
    }

    const identifier = resolveRateLimitIdentifier(
      realtor_id,
      req.headers.get("x-forwarded-for")
    );
    const limited = await enforceRateLimit(
      supabase,
      RATE_LIMITS["match-offers"],
      identifier
    );
    if (limited) return limited;

    // احصل على بيانات الوسيط
    const { data: realtor } = await supabase
      .from("realtors")
      .select("specializations")
      .eq("user_id", realtor_id)
      .single();

    if (!realtor) {
      return jsonResponse({ error: "Realtor not found" }, 404, origin);
    }

    // ابحث عن الطلبات المطابقة بناءً على:
    // 1. الفئة (residential/commercial/land)
    // 2. الحالة (active)
    // 3. عدم وجود عرض سابق من نفس الوسيط
    let query = supabase
      .from("property_requests")
      .select(
        `
        id,
        buyer_id,
        category,
        title,
        city,
        min_price,
        max_price,
        bedrooms,
        bathrooms,
        created_at
      `
      )
      .eq("status", "active")
      .gt("expires_at", new Date().toISOString());

    // فلتر حسب الفئة إذا تم تحديده
    if (category) {
      query = query.eq("category", category);
    } else if (realtor.specializations && realtor.specializations.length > 0) {
      // أو استخدم تخصصات الوسيط
      query = query.in("category", realtor.specializations);
    }

    const { data: requests } = await query.limit(limit);

    if (!requests || requests.length === 0) {
      return jsonResponse({ matches: [] }, 200, origin);
    }

    // اجلب معرفات الطلبات التي أنشأ لها الوسيط عرضًا سابقًا
    const { data: existingOffers } = await supabase
      .from("realtor_offers")
      .select("request_id")
      .eq("realtor_id", realtor_id)
      .in(
        "request_id",
        requests.map((r: any) => r.id)
      );

    const existingOfferRequestIds = new Set<string>(
      (existingOffers || []).map((o: any) => o.request_id)
    );

    // احسب المطابقات ورتبها حسب درجة المطابقة
    const matches = buildMatches(requests, existingOfferRequestIds);

    return jsonResponse({ matches }, 200, origin);
  } catch (error) {
    console.error("Matching error:", error);
    return jsonResponse({ error: (error as Error).message }, 500, origin);
  }
});
