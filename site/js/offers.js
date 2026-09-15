import { supabase } from "./supabase-client.js";
import { getCurrentAppUserId } from "./auth.js";

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

export async function createOffer(fields) {
  const realtorId = await getCurrentAppUserId();
  const { data, error } = await supabase
    .from("realtor_offers")
    .insert({ ...fields, realtor_id: realtorId })
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function listMyOffers() {
  const realtorId = await getCurrentAppUserId();
  const { data, error } = await supabase
    .from("realtor_offers")
    .select("*")
    .eq("realtor_id", realtorId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data;
}

export async function uploadOfferPhotos(offerId, files) {
  const photoUrls = [];
  for (const file of files) {
    const filePath = `offer-photos/${offerId}/${file.name}`;
    const { error: uploadError } = await supabase.storage
      .from("dabberli")
      .upload(filePath, file);
    if (uploadError) throw uploadError;
    const { data: publicUrlData } = supabase.storage
      .from("dabberli")
      .getPublicUrl(filePath);
    photoUrls.push(publicUrlData.publicUrl);
  }

  const { error: updateError } = await supabase
    .from("realtor_offers")
    .update({ photo_urls: photoUrls })
    .eq("id", offerId);
  if (updateError) throw updateError;

  return photoUrls;
}
