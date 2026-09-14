import { supabase } from "./supabase-client.js";

export async function sendMessage(offerId, body) {
  const { error } = await supabase.rpc("send_message", {
    p_offer_id: offerId,
    p_body: body,
  });
  if (error) throw error;
}

export async function listMessages(offerId) {
  const { data, error } = await supabase.rpc("list_messages", {
    p_offer_id: offerId,
  });
  if (error) throw error;
  return data ?? [];
}

export async function markMessagesRead(offerId) {
  const { error } = await supabase.rpc("mark_messages_read", {
    p_offer_id: offerId,
  });
  if (error) throw error;
}

export async function unreadMessageCount() {
  const { data, error } = await supabase.rpc("unread_message_count");
  if (error) throw error;
  return data ?? 0;
}

export async function subscribeToMessages(offerId, callback) {
  const channel = supabase
    .channel(`messages:${offerId}`)
    .on(
      "postgres_changes",
      {
        event: "INSERT",
        schema: "public",
        table: "messages",
        filter: `offer_id=eq.${offerId}`,
      },
      (payload) => {
        callback(payload.new);
      },
    )
    .subscribe();

  return channel;
}
