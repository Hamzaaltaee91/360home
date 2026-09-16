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

// Returns the signed-in user's display info as { full_name, email },
// or null when nobody is signed in. Mirrors getCurrentAppUserId's
// error handling: the query error is thrown as-is.
export async function getCurrentUserDisplay() {
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;
  const { data, error } = await supabase
    .from("users")
    .select("full_name, email")
    .eq("auth_id", user.id)
    .single();
  if (error) throw error;
  return { full_name: data.full_name, email: data.email };
}

// Renders an avatar button + dropdown (name, email, sign-out) into `container`.
// Replaces a plain sign-out button in the nav. Renders nothing if unauthenticated.
export async function mountProfileMenu(container) {
  const currentUser = await getCurrentUserDisplay();
  if (!currentUser) return;

  const displayName =
    currentUser.full_name && currentUser.full_name.trim()
      ? currentUser.full_name
      : currentUser.email;
  const initial = displayName.trim().charAt(0).toUpperCase();

  const wrapper = document.createElement("div");
  wrapper.className = "profile-menu";

  const avatarBtn = document.createElement("button");
  avatarBtn.type = "button";
  avatarBtn.className = "profile-avatar";
  avatarBtn.textContent = initial;
  avatarBtn.setAttribute("aria-haspopup", "true");
  avatarBtn.setAttribute("aria-expanded", "false");
  avatarBtn.setAttribute("aria-label", displayName);

  const dropdown = document.createElement("div");
  dropdown.className = "profile-dropdown";
  dropdown.hidden = true;

  const nameEl = document.createElement("p");
  nameEl.className = "profile-dropdown-name";
  nameEl.textContent = displayName;

  const emailEl = document.createElement("p");
  emailEl.className = "profile-dropdown-email";
  emailEl.textContent = currentUser.email;

  const signoutBtn = document.createElement("button");
  signoutBtn.type = "button";
  signoutBtn.className = "btn btn-ghost";
  signoutBtn.textContent = "تسجيل الخروج";
  signoutBtn.addEventListener("click", signOut);

  dropdown.append(nameEl, emailEl, signoutBtn);
  wrapper.append(avatarBtn, dropdown);
  container.appendChild(wrapper);

  function closeDropdown() {
    dropdown.hidden = true;
    avatarBtn.setAttribute("aria-expanded", "false");
    document.removeEventListener("click", onOutsideClick);
  }

  function onOutsideClick(e) {
    if (!wrapper.contains(e.target)) closeDropdown();
  }

  avatarBtn.addEventListener("click", (e) => {
    e.stopPropagation();
    const willOpen = dropdown.hidden;
    dropdown.hidden = !willOpen;
    avatarBtn.setAttribute("aria-expanded", String(willOpen));
    if (willOpen) {
      document.addEventListener("click", onOutsideClick);
    } else {
      document.removeEventListener("click", onOutsideClick);
    }
  });
}

export async function requestPasswordReset(email) {
  return supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${window.location.origin}/reset-password.html`,
  });
}

export async function updatePassword(newPassword) {
  return supabase.auth.updateUser({ password: newPassword });
}

export async function requireSession() {
  const { data } = await supabase.auth.getSession();
  if (!data.session) {
    window.location.href = "auth.html";
    return new Promise(() => {});
  }
  return data.session;
}

// Maps a public.users.role value to the landing page for that role.
// Unknown or missing roles fall back to the buyer dashboard.
export function getRoleHomePath(role) {
  if (role === "realtor") return "realtor-dashboard.html";
  if (role === "admin") return "admin-realtors.html";
  return "dashboard.html";
}
