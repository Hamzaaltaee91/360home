import { supabase } from "./supabase-client.js";

export async function listOffersForRequest(requestId) {
  const { data, error } = await supabase
    .from("realtor_offers")
    .select("*")
    .eq("request_id", requestId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data;
}

export async function getOffer(id) {
  const { data, error } = await supabase
    .from("realtor_offers")
    .select("*")
    .eq("id", id)
    .single();
  if (error) throw error;
  if (!data) throw new Error("not found");
  return data;
}

export async function respondToOffer(id, response) {
  const { error } = await supabase
    .from("realtor_offers")
    .update({ buyer_response: response })
    .eq("id", id);
  if (error) throw error;
}
