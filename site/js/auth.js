import { supabase } from "./supabase-client.js";

export async function signUpBuyer(email, password, fullName) {
  return supabase.auth.signUp({
    email,
    password,
    options: { data: { role: "buyer", full_name: fullName } },
  });
}

export async function signIn(email, password) {
  return supabase.auth.signInWithPassword({ email, password });
}

export async function signInWithGoogle() {
  return supabase.auth.signInWithOAuth({
    provider: "google",
    options: { redirectTo: `${window.location.origin}/dashboard.html` },
  });
}

export async function signOut() {
  await supabase.auth.signOut();
  window.location.href = "auth.html";
}

// Resolves the signed-in auth user to their public.users.id — the id
// referenced by buyer_id/realtor_id/etc, NOT the same as auth.getUser()'s
// user.id (that's auth.users.id, a different id space).
export async function getCurrentAppUserId() {
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) throw new Error("not authenticated");
  const { data, error } = await supabase
    .from("users")
    .select("id")
    .eq("auth_id", user.id)
    .single();
  if (error) throw error;
  return data.id;
}

export async function requireSession() {
  const { data } = await supabase.auth.getSession();
  if (!data.session) {
    window.location.href = "auth.html";
    return new Promise(() => {});
  }
  return data.session;
}
