import { supabase } from "./supabase-client.js";

export async function submitRealtorApplication(
  companyName,
  licenseNumber,
  licenseExpiry,
  documentUrl,
) {
  const { error } = await supabase.rpc("submit_realtor_application", {
    p_company_name: companyName,
    p_license_number: licenseNumber,
    p_license_expiry: licenseExpiry,
    p_document_url: documentUrl,
  });
  if (error) throw error;
}

export async function getMyVerificationStatus() {
  const { data, error } = await supabase.rpc("get_my_verification_status");
  if (error) throw error;
  if (!data || data.length === 0) return null;
  return data[0];
}
