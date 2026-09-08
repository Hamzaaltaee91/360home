// Search & Filtering Service
// Advanced search with geospatial queries, budget filters, category sorting

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

interface SearchQuery {
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

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        { status: 405 }
      );
    }

    const body: SearchQuery = await req.json();
    const {
      category,
      city,
      min_price,
      max_price,
      bedrooms,
      bathrooms,
      latitude,
      longitude,
      radius_km = 10,
      sort_by = "recent",
      status = "active",
      limit = 20,
      offset = 0,
    } = body;

    // ابدأ ببناء الاستعلام
    let query = supabase
      .from("property_requests")
      .select("*")
      .eq("status", status);

    // فلاتر أساسية
    if (category) {
      query = query.eq("category", category);
    }

    if (city) {
      query = query.ilike("city", `%${city}%`);
    }

    if (min_price !== undefined) {
      query = query.gte("min_price", min_price);
    }

    if (max_price !== undefined) {
      query = query.lte("max_price", max_price);
    }

    if (bedrooms !== undefined) {
      query = query.eq("bedrooms", bedrooms);
    }

    if (bathrooms !== undefined) {
      query = query.eq("bathrooms", bathrooms);
    }

    // فلتر جغرافي (إذا توفرت الإحداثيات)
    if (latitude !== undefined && longitude !== undefined) {
      // استخدم PostGIS للبحث عن المسافة
      // SELECT * FROM property_requests
      // WHERE earth_distance(ll_to_earth(latitude, longitude),
      //                       ll_to_earth($1, $2)) <= $3 * 1000
      query = query.rpc("nearby_requests", {
        lat: latitude,
        lng: longitude,
        radius_m: radius_km * 1000,
      });
    }

    // الترتيب
    if (sort_by === "recent") {
      query = query.order("created_at", { ascending: false });
    } else if (sort_by === "price_low") {
      query = query.order("min_price", { ascending: true });
    } else if (sort_by === "price_high") {
      query = query.order("max_price", { ascending: false });
    }

    // التصفح
    query = query.range(offset, offset + limit - 1);

    const { data: results, error } = await query;

    if (error) {
      throw error;
    }

    // احصل على إجمالي العدد
    let countQuery = supabase
      .from("property_requests")
      .select("*", { count: "exact" })
      .eq("status", status);

    if (category) countQuery = countQuery.eq("category", category);
    if (city) countQuery = countQuery.ilike("city", `%${city}%`);
    if (min_price !== undefined) countQuery = countQuery.gte("min_price", min_price);
    if (max_price !== undefined) countQuery = countQuery.lte("max_price", max_price);

    const { count: totalCount } = await countQuery;

    return new Response(
      JSON.stringify({
        results: results || [],
        total_count: totalCount || 0,
        has_more: (offset + limit) < (totalCount || 0),
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Search error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
