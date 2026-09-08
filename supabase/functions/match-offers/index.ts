// Offer Matching Engine
// Recommends matching property requests to realtors based on criteria

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        { status: 405 }
      );
    }

    const body: MatchRequest = await req.json();
    const { realtor_id, category, limit = 10 } = body;

    // احصل على بيانات الوسيط
    const { data: realtor } = await supabase
      .from("realtors")
      .select("specializations")
      .eq("user_id", realtor_id)
      .single();

    if (!realtor) {
      return new Response(
        JSON.stringify({ error: "Realtor not found" }),
        { status: 404 }
      );
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
      return new Response(
        JSON.stringify({ matches: [] }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // للطلب الواحد، احسب درجة المطابقة
    const matches: PropertyMatch[] = await Promise.all(
      requests.map(async (request: any) => {
        // تحقق من أن الوسيط لم ينشئ عرضًا سابقًا
        const { count: existingOffers } = await supabase
          .from("realtor_offers")
          .select("*", { count: "exact" })
          .eq("realtor_id", realtor_id)
          .eq("request_id", request.id);

        // احسب درجة المطابقة (0-100)
        let matchScore = 50; // درجة أساسية

        // +20 إذا كان الطلب حديثًا (أقل من 7 أيام)
        const requestAge =
          (Date.now() -
            new Date(request.created_at).getTime()) /
          (1000 * 60 * 60 * 24);
        if (requestAge < 7) matchScore += 20;

        // +15 إذا لم يكن هناك عرض سابق
        if (!existingOffers || existingOffers === 0) matchScore += 15;

        // -10 إذا كان الطلب عاجلًا (ربما أقل عرضًا)
        if (request.is_urgent) matchScore -= 10;

        return {
          request_id: request.id,
          buyer_id: request.buyer_id,
          category: request.category,
          title: request.title,
          city: request.city,
          min_price: request.min_price,
          max_price: request.max_price,
          bedrooms: request.bedrooms,
          bathrooms: request.bathrooms,
          match_score: Math.max(0, Math.min(100, matchScore)),
        };
      })
    );

    // رتب حسب درجة المطابقة
    matches.sort((a, b) => b.match_score - a.match_score);

    return new Response(
      JSON.stringify({ matches }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Matching error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
