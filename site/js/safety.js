import { supabase } from "./supabase-client.js";

export async function reportContent(reportedUserId, messageId, reason, details) {
  const { error } = await supabase.rpc("report_content", {
    p_reported_user_id: reportedUserId,
    p_message_id: messageId,
    p_reason: reason,
    p_details: details,
  });
  if (error) throw error;
}

export async function blockUser(userId) {
  const { error } = await supabase.rpc("block_user", {
    p_user_id: userId,
  });
  if (error) throw error;
}

export async function unblockUser(userId) {
  const { error } = await supabase.rpc("unblock_user", {
    p_user_id: userId,
  });
  if (error) throw error;
}

export async function listBlockedUsers() {
  const { data, error } = await supabase.rpc("list_blocked_users");
  if (error) throw error;
  return data;
}

export async function listOpenReports() {
  const { data, error } = await supabase.rpc("list_open_reports");
  if (error) throw error;
  return data;
}

export async function resolveReport(reportId, status) {
  const { error } = await supabase.rpc("resolve_report", {
    p_report_id: reportId,
    p_status: status,
  });
  if (error) throw error;
}
