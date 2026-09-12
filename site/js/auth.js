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

export async function requireSession() {
  const { data } = await supabase.auth.getSession();
  if (!data.session) {
    window.location.href = "auth.html";
    return new Promise(() => {});
  }
  return data.session;
}
