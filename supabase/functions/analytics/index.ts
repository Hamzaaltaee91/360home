// Analytics Service
// Tracks user engagement, offer response rates, realtor performance

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

interface AnalyticsQuery {
  type: "realtor" | "buyer" | "platform";
  user_id?: string;
  date_from?: string;
  date_to?: string;
}

export interface RealtorStats {
  total_offers: number;
  accepted_offers: number;
  rejected_offers: number;
  pending_offers: number;
  average_response_time: number; // بالساعات
  total_interactions: number;
}

export interface BuyerStats {
  total_requests: number;
  active_requests: number;
  total_offers_received: number;
  total_offers_accepted: number;
  response_rate: number; // نسبة الرد (0-100)
}

export interface PlatformStats {
  period: { from: string; to: string };
  new_users: { total: number; buyers: number; realtors: number };
  property_requests: number;
  realtor_offers: number;
  offer_acceptance_rate: number;
  average_offers_per_request: number;
}

serve(async (req) => {
  const origin = req.headers.get("Origin");
  const preflight = handleCorsPreflight(req);
  if (preflight) return preflight;

  try {
    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405, origin);
    }

    const body: AnalyticsQuery = await req.json();
    const {
      type,
      user_id,
      date_from = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
      date_to = new Date().toISOString(),
    } = body;

    const identifier = resolveRateLimitIdentifier(
      user_id,
      req.headers.get("x-forwarded-for")
    );
    const limited = await enforceRateLimit(
      supabase,
      RATE_LIMITS["analytics"],
      identifier
    );
    if (limited) return limited;

    if (type === "realtor" && user_id) {
      return jsonResponse(
        await getRealtorStats(user_id, date_from, date_to),
        200,
        origin
      );
    } else if (type === "buyer" && user_id) {
      return jsonResponse(
        await getBuyerStats(user_id, date_from, date_to),
        200,
        origin
      );
    } else if (type === "platform") {
      return jsonResponse(
        await getPlatformStats(date_from, date_to),
        200,
        origin
      );
    }

    return jsonResponse({ error: "Invalid analytics type" }, 400, origin);
  } catch (error) {
    console.error("Analytics error:", error);
    return jsonResponse({ error: (error as Error).message }, 500, origin);
  }
});

export function computeRealtorStats(
  offers: any[] | null,
  interactions: any[] | null
): RealtorStats {
  if (!offers) {
    return {
      total_offers: 0,
      accepted_offers: 0,
      rejected_offers: 0,
      pending_offers: 0,
      average_response_time: 0,
      total_interactions: 0,
    };
  }

  const accepted = offers.filter(
    (o: any) => o.buyer_response === "interested"
  ).length;
  const rejected = offers.filter(
    (o: any) => o.buyer_response === "not_interested"
  ).length;
  const pending = offers.filter((o: any) => o.status === "pending").length;

  // احسب وقت الرد المتوسط
  const responseTimes = offers
    .filter((o: any) => o.updated_at > o.created_at)
    .map((o: any) => {
      const diff =
        new Date(o.updated_at).getTime() - new Date(o.created_at).getTime();
      return diff / (1000 * 60 * 60); // تحويل إلى ساعات
    });

  const avgResponseTime =
    responseTimes.length > 0
      ? responseTimes.reduce((a: number, b: number) => a + b, 0) /
        responseTimes.length
      : 0;

  return {
    total_offers: offers.length,
    accepted_offers: accepted,
    rejected_offers: rejected,
    pending_offers: pending,
    average_response_time: Math.round(avgResponseTime * 100) / 100,
    total_interactions: interactions?.length || 0,
  };
}

async function getRealtorStats(
  realtorId: string,
  dateFrom: string,
  dateTo: string
): Promise<RealtorStats> {
  const { data: offers } = await supabase
    .from("realtor_offers")
    .select("id, status, created_at, buyer_response, updated_at")
    .eq("realtor_id", realtorId)
    .gte("created_at", dateFrom)
    .lte("created_at", dateTo);

  const { data: interactions } = await supabase
    .from("offer_interactions")
    .select("*")
    .eq("realtor_id", realtorId)
    .gte("created_at", dateFrom)
    .lte("created_at", dateTo);

  return computeRealtorStats(offers, interactions);
}

export function computeBuyerStats(
  requests: any[] | null,
  offers: any[] | null
): BuyerStats {
  const active = requests?.filter((r: any) => r.status === "active").length || 0;
  const accepted = offers?.filter((o: any) => o.buyer_response === "interested")
    .length || 0;
  const responseCount = offers?.filter((o: any) => o.buyer_response) || [];

  const responseRate =
    offers && offers.length > 0
      ? Math.round((responseCount.length / offers.length) * 100)
      : 0;

  return {
    total_requests: requests?.length || 0,
    active_requests: active,
    total_offers_received: offers?.length || 0,
    total_offers_accepted: accepted,
    response_rate: responseRate,
  };
}

async function getBuyerStats(
  buyerId: string,
  dateFrom: string,
  dateTo: string
): Promise<BuyerStats> {
  const { data: requests } = await supabase
    .from("property_requests")
    .select("id, status")
    .eq("buyer_id", buyerId)
    .gte("created_at", dateFrom)
    .lte("created_at", dateTo);

  const { data: offers } = await supabase
    .from("realtor_offers")
    .select("id, buyer_response, request_id")
    .in(
      "request_id",
      requests?.map((r: any) => r.id) || []
    )
    .gte("created_at", dateFrom)
    .lte("created_at", dateTo);

  return computeBuyerStats(requests, offers);
}

export function computePlatformStats(
  users: any[] | null,
  requests: any[] | null,
  offers: any[] | null,
  dateFrom: string,
  dateTo: string
): PlatformStats {
  const buyers = users?.filter((u: any) => u.role === "buyer").length || 0;
  const realtors = users?.filter((u: any) => u.role === "realtor").length || 0;

  const offerAcceptanceRate =
    offers && offers.length > 0
      ? Math.round(
          (offers.filter((o: any) => o.buyer_response === "interested")
            .length /
            offers.length) *
            100
        )
      : 0;

  return {
    period: { from: dateFrom, to: dateTo },
    new_users: {
      total: users?.length || 0,
      buyers,
      realtors,
    },
    property_requests: requests?.length || 0,
    realtor_offers: offers?.length || 0,
    offer_acceptance_rate: offerAcceptanceRate,
    average_offers_per_request:
      requests && requests.length > 0
        ? Math.round(((offers?.length || 0) / requests.length) * 100) / 100
        : 0,
  };
}

async function getPlatformStats(
  dateFrom: string,
  dateTo: string
): Promise<PlatformStats> {
  const { data: users } = await supabase
    .from("users")
    .select("id, role")
    .gte("created_at", dateFrom)
    .lte("created_at", dateTo);

  const { data: requests } = await supabase
    .from("property_requests")
    .select("*")
    .gte("created_at", dateFrom)
    .lte("created_at", dateTo);

  const { data: offers } = await supabase
    .from("realtor_offers")
    .select("*")
    .gte("created_at", dateFrom)
    .lte("created_at", dateTo);

  return computePlatformStats(users, requests, offers, dateFrom, dateTo);
}
