import { supabase } from "./supabase-client.js";

export async function submitReview(offerId, rating, comment) {
  const { error } = await supabase.rpc("submit_realtor_review", {
    p_offer_id: offerId,
    p_rating: rating,
    p_comment: comment,
  });
  if (error) throw error;
}

export async function listRealtorReviews(realtorId) {
  const { data, error } = await supabase.rpc("list_realtor_reviews", {
    p_realtor_id: realtorId,
  });
  if (error) throw error;
  return data;
}

export async function getMyReviewForOffer(offerId) {
  const { data, error } = await supabase.rpc("get_my_review_for_offer", {
    p_offer_id: offerId,
  });
  if (error) throw error;
  return data && data.length > 0 ? data[0] : null;
}
