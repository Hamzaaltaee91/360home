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

export async function uploadLicenseDocument(userId, file) {
  const path = `realtor-documents/${userId}/${file.name}`;
  const { error } = await supabase.storage.from("dabberli").upload(path, file);
  if (error) throw error;
  const { data } = supabase.storage.from("dabberli").getPublicUrl(path);
  return data.publicUrl;
}
