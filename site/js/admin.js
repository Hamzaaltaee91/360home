import { supabase } from "./supabase-client.js";

export async function listPendingRealtorApplications() {
  const { data, error } = await supabase.rpc("list_pending_realtor_applications");
  if (error) throw error;
  return data;
}

export async function approveRealtorApplication(verificationId) {
  const { data, error } = await supabase.rpc("approve_realtor_application", {
    p_verification_id: verificationId,
  });
  if (error) throw error;
  return data;
}

export async function rejectRealtorApplication(verificationId, reason) {
  const { data, error } = await supabase.rpc("reject_realtor_application", {
    p_verification_id: verificationId,
    p_reason: reason,
  });
  if (error) throw error;
  return data;
}
