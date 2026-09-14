import { supabase } from "./supabase-client.js";

export async function listMyRequests() {
  const { data, error } = await supabase
    .from("property_requests")
    .select("*")
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
  const {
    data: { user },
  } = await supabase.auth.getUser();
  const { data, error } = await supabase
    .from("property_requests")
    .insert({ ...fields, buyer_id: user.id })
    .select()
    .single();
  if (error) throw error;
  return data;
}
