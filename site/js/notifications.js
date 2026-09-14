import { supabase } from "./supabase-client.js";

export async function listMyNotifications() {
  const {
    data: { user },
  } = await supabase.auth.getUser();
  const { data, error } = await supabase
    .from("notifications")
    .select("*")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data;
}

export async function unreadCount() {
  const {
    data: { user },
  } = await supabase.auth.getUser();
  const { count, error } = await supabase
    .from("notifications")
    .select("*", { count: "exact", head: true })
    .eq("user_id", user.id)
    .eq("is_read", false);
  if (error) throw error;
  return count ?? 0;
}

export async function markAsRead(id) {
  const { error } = await supabase
    .from("notifications")
    .update({ is_read: true })
    .eq("id", id);
  if (error) throw error;
}

/**
 * Subscribes to Realtime changes on the current user's notifications.
 * Invokes `callback` with the fresh unread count on every change.
 * Resolves to the channel object so callers can unsubscribe:
 *   const channel = await subscribeToUnreadCount(setCount);
 *   ...later: await supabase.removeChannel(channel);
 */
export async function subscribeToUnreadCount(callback) {
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const channel = supabase
    .channel(`notifications:${user.id}`)
    .on(
      "postgres_changes",
      {
        event: "*",
        schema: "public",
        table: "notifications",
        filter: `user_id=eq.${user.id}`,
      },
      async () => {
        const count = await unreadCount();
        callback(count);
      },
    )
    .subscribe();

  return channel;
}
