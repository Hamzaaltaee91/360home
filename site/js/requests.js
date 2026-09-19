import { supabase } from "./supabase-client.js";
import { getCurrentAppUserId } from "./auth.js";

export async function listMyRequests() {
  const buyerId = await getCurrentAppUserId();
  const { data, error } = await supabase
    .from("property_requests")
    .select("*")
    .eq("buyer_id", buyerId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data;
}

export async function updateRequest(id, fields) {
  const { data, error } = await supabase
    .from("property_requests")
    .update(fields)
    .eq("id", id)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function deleteRequest(id) {
  const { error } = await supabase
    .from("property_requests")
    .delete()
    .eq("id", id);
  if (error) throw error;
}

export async function listActiveRequestsForRealtor() {
  // No pg_cron in this project — sweep stale requests to 'inactive'
  // opportunistically, right before the realtor-facing query that
  // actually depends on 'active' meaning "posted within the last
  // month". Best-effort: a failed sweep shouldn't block browsing.
  try {
    await supabase.rpc("auto_expire_old_requests");
  } catch (err) {
    console.error(err);
  }

  const { data, error } = await supabase
    .from("property_requests")
    .select("*")
    .eq("status", "active")
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data;
}

export async function getRequest(id) {
  const { data, error } = await supabase
    .from("property_requests")
    .select("*")
    .eq("id", id)
    .single();
  if (error) throw error;
  if (!data) throw new Error("not found");
  return data;
}

export async function createRequest(fields) {
  const buyerId = await getCurrentAppUserId();
  const { data, error } = await supabase
    .from("property_requests")
    .insert({ ...fields, buyer_id: buyerId })
    .select()
    .single();
  if (error) throw error;
  return data;
}
