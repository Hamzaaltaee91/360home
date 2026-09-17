import { supabase } from "./supabase-client.js";
import { getCurrentAppUserId } from "./auth.js";

export async function listMyProperties() {
  const realtorId = await getCurrentAppUserId();
  const { data, error } = await supabase
    .from("realtor_properties")
    .select("*")
    .eq("realtor_id", realtorId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data;
}

export async function createProperty(fields) {
  const realtorId = await getCurrentAppUserId();
  const { data, error } = await supabase
    .from("realtor_properties")
    .insert({ ...fields, realtor_id: realtorId })
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function updateProperty(id, fields) {
  const { data, error } = await supabase
    .from("realtor_properties")
    .update(fields)
    .eq("id", id)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function deleteProperty(id) {
  const { error } = await supabase
    .from("realtor_properties")
    .delete()
    .eq("id", id);
  if (error) throw error;
}
