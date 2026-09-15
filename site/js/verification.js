import { supabase } from "./supabase-client.js";

export async function submitRealtorApplication(
  companyName,
  licenseNumber,
  licenseExpiry,
  documentUrl,
  whatsappPhone,
) {
  const { error } = await supabase.rpc("submit_realtor_application", {
    p_company_name: companyName,
    p_license_number: licenseNumber,
    p_license_expiry: licenseExpiry,
    p_document_url: documentUrl,
    p_whatsapp_phone: whatsappPhone,
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
  const path = `${userId}/${file.name}`;
  const { error } = await supabase.storage
    .from("verification-documents")
    .upload(path, file);
  if (error) throw error;
  return path;
}

export async function getVerificationDocumentUrl(path) {
  const { data, error } = await supabase.storage
    .from("verification-documents")
    .createSignedUrl(path, 3600);
  if (error) throw error;
  return data.signedUrl;
}
