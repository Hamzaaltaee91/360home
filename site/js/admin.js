import { supabase } from "./supabase-client.js";

export async function listPendingVerifications() {
  const { data, error } = await supabase.rpc("list_pending_verifications");
  if (error) throw error;
  return data;
}

export async function approveVerification(verificationId) {
  const { data, error } = await supabase.rpc("approve_verification", {
    p_verification_id: verificationId,
  });
  if (error) throw error;
  return data;
}

export async function rejectVerification(verificationId, reason) {
  const { data, error } = await supabase.rpc("reject_verification", {
    p_verification_id: verificationId,
    p_reason: reason,
  });
  if (error) throw error;
  return data;
}
