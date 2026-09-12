# Buyer Web Site Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a plain HTML/CSS/JS static site (`site/`) that lets buyers sign up, sign in, post property requests, and respond to realtor offers, talking directly to the existing Supabase project — replacing Flutter-web as the browser entry point.

**Architecture:** Five static HTML pages share one stylesheet and small per-concern JS modules (config, Supabase client init, auth, requests, offers). No bundler — every script is loaded via a plain `<script type="module" src="...">` tag, in dependency order, on each page. All data access goes through the Supabase JS client directly; RLS policies already in the database (not duplicated client-side) are the actual authorization boundary. Deployment is nginx on the existing DigitalOcean droplet, serving `~/360home/site/` directly — a `git pull` is the entire deploy step.

**Tech Stack:** Vanilla HTML5, CSS3, ES modules (no build step), Supabase JS v2 via CDN (`https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.js`), nginx.

**Spec:** `docs/superpowers/specs/2026-09-12-buyer-web-site-design.md`

## Global Constraints

- No build tooling of any kind (no npm, no webpack/vite, no TypeScript) — pages are served byte-for-byte as written.
- `site/` is a new top-level directory, never named `web/` (Flutter's own build output uses that name).
- Every page is `<html lang="ar" dir="rtl">` — full RTL layout.
- Fonts: Aref Ruqaa (headings/display) + IBM Plex Sans Arabic (body), both from Google Fonts.
- Supabase project URL: `https://ojnhaqpiufgfxusokazb.supabase.co`.
- Supabase anon key (safe to embed client-side — this is the publishable key, not a secret): `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qbmhhcXBpdWZnZnh1c29rYXpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg5MjI1NzMsImV4cCI6MjEwNDQ5ODU3M30.D9jYEHSYL45bpmo-7RkxdKz19u-qhRIJNoypSClg3tg`.
- No automated tests for this feature — every task ends with a manual browser-verification step instead of a test-runner step, matching the spec's testing section.
- Scope is buyer flow only: sign up, sign in, list own requests, create a request, view a request's offers, view/respond to one offer. No realtor or admin UI.
- Every protected page must redirect to `index.html` when `supabase.auth.getSession()` has no session.

---

## File Structure

```
site/
  index.html            Landing + login + signup toggle
  dashboard.html         Buyer's own requests, newest first
  request-new.html       Create-request form
  request.html            One request + its offers
  offer.html               One offer + accept/reject
  css/
    style.css             Shared design-system styles, RTL
  js/
    config.js              SUPABASE_URL / SUPABASE_ANON_KEY constants
    supabase-client.js      Creates and exports the Supabase client
    auth.js                 signUp/signIn/signOut/requireSession helpers
    requests.js             CRUD helpers for property_requests
    offers.js               Read/respond helpers for realtor_offers
```

Each HTML page's own inline `<script type="module">` imports only the JS files it needs; `config.js` and `supabase-client.js` are imported by every other JS module rather than loaded as separate `<script>` tags, since ES modules resolve their own imports.

---

## Task 1: Supabase client bootstrap (`js/config.js`, `js/supabase-client.js`)

**Files:**
- Create: `site/js/config.js`
- Create: `site/js/supabase-client.js`

**Interfaces:**
- Produces: `SUPABASE_URL: string`, `SUPABASE_ANON_KEY: string` (named exports from `config.js`); `supabase` (a `SupabaseClient` instance, default export from `supabase-client.js`) — every later JS module imports `supabase` from `'./supabase-client.js'`.

- [ ] **Step 1: Create `site/js/config.js`**

```js
export const SUPABASE_URL = "https://ojnhaqpiufgfxusokazb.supabase.co";
export const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qbmhhcXBpdWZnZnh1c29rYXpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg5MjI1NzMsImV4cCI6MjEwNDQ5ODU3M30.D9jYEHSYL45bpmo-7RkxdKz19u-qhRIJNoypSClg3tg";
```

- [ ] **Step 2: Create `site/js/supabase-client.js`**

```js
import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/+esm";
import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./config.js";

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
```

- [ ] **Step 3: Manual verification**

Create a throwaway `site/_smoke.html` with:

```html
<!DOCTYPE html>
<html><body>
<script type="module">
  import { supabase } from "./js/supabase-client.js";
  supabase.auth.getSession().then(r => document.body.append(JSON.stringify(r)));
</script>
</body></html>
```

Open it via `python3 -m http.server 8000` from inside `site/` and load `http://localhost:8000/_smoke.html` in a browser. Confirm the page prints `{"data":{"session":null},"error":null}` (no console errors about the CDN import or invalid API key). Delete `site/_smoke.html` afterward.

- [ ] **Step 4: Commit**

```bash
git add site/js/config.js site/js/supabase-client.js
git commit -m "feat: add Supabase client bootstrap for buyer web site"
```

---

## Task 2: Auth helpers (`js/auth.js`)

**Files:**
- Create: `site/js/auth.js`

**Interfaces:**
- Consumes: `supabase` from `./supabase-client.js` (Task 1).
- Produces: `signUpBuyer(email, password, fullName): Promise<{data, error}>`, `signIn(email, password): Promise<{data, error}>`, `signOut(): Promise<void>`, `requireSession(): Promise<Session>` (redirects to `index.html` and never resolves if there's no session — later pages call this at the top of their script and can assume a session exists after it resolves).

- [ ] **Step 1: Create `site/js/auth.js`**

```js
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

export async function signOut() {
  await supabase.auth.signOut();
  window.location.href = "index.html";
}

export async function requireSession() {
  const { data } = await supabase.auth.getSession();
  if (!data.session) {
    window.location.href = "index.html";
    return new Promise(() => {});
  }
  return data.session;
}
```

- [ ] **Step 2: Manual verification**

Reuse the `site/_smoke.html` pattern from Task 1: import `signUpBuyer` and call it with a throwaway email (e.g. `test+<timestamp>@example.com`) and a password, then log the result to the page. Confirm `error` is `null` and `data.user` is present. Delete the smoke file afterward.

- [ ] **Step 3: Commit**

```bash
git add site/js/auth.js
git commit -m "feat: add auth helpers for buyer web site"
```

---

## Task 3: Requests data helpers (`js/requests.js`)

**Files:**
- Create: `site/js/requests.js`

**Interfaces:**
- Consumes: `supabase` from `./supabase-client.js` (Task 1).
- Produces: `listMyRequests(): Promise<PropertyRequest[]>` (throws on error), `getRequest(id): Promise<PropertyRequest>` (throws on error, throws `Error('not found')` if no row), `createRequest(fields): Promise<PropertyRequest>` where `fields` is `{category, title, description, city, area_name, min_price, max_price, bedrooms, bathrooms, furnished}` (throws on error). `PropertyRequest` is the raw row shape of `public.property_requests` (see `supabase/migrations/20260908000001_initial_schema.sql`).

- [ ] **Step 1: Create `site/js/requests.js`**

```js
import { supabase } from "./supabase-client.js";

export async function listMyRequests() {
  const { data, error } = await supabase
    .from("property_requests")
    .select("*")
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data;
}

export async function getRequest(id) {
  const { data, error } = await supabase
    .from("property_requests")
    .select("*")
    .eq("id", id)
    .single();
  if (error) throw error;
  if (!data) throw new Error("not found");
  return data;
}

export async function createRequest(fields) {
  const {
    data: { user },
  } = await supabase.auth.getUser();
  const { data, error } = await supabase
    .from("property_requests")
    .insert({ ...fields, buyer_id: user.id })
    .select()
    .single();
  if (error) throw error;
  return data;
}
```

- [ ] **Step 2: Manual verification**

Using the smoke-page pattern, sign in as the test buyer from Task 2, then call `createRequest({category: "residential", title: "شقة تجريبية", city: "بغداد"})` and confirm it returns a row with a `id`. Then call `listMyRequests()` and confirm the created row appears first. Delete the smoke file afterward.

- [ ] **Step 3: Commit**

```bash
git add site/js/requests.js
git commit -m "feat: add property_requests data helpers for buyer web site"
```

---

## Task 4: Offers data helpers (`js/offers.js`)

**Files:**
- Create: `site/js/offers.js`

**Interfaces:**
- Consumes: `supabase` from `./supabase-client.js` (Task 1).
- Produces: `listOffersForRequest(requestId): Promise<RealtorOffer[]>` (throws on error), `getOffer(id): Promise<RealtorOffer>` (throws on error, throws `Error('not found')` if no row), `respondToOffer(id, response): Promise<void>` where `response` is `'interested' | 'not_interested'` (throws on error). `RealtorOffer` is the raw row shape of `public.realtor_offers` (see `supabase/migrations/20260908000001_initial_schema.sql`).

- [ ] **Step 1: Create `site/js/offers.js`**

```js
import { supabase } from "./supabase-client.js";

export async function listOffersForRequest(requestId) {
  const { data, error } = await supabase
    .from("realtor_offers")
    .select("*")
    .eq("request_id", requestId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data;
}

export async function getOffer(id) {
  const { data, error } = await supabase
    .from("realtor_offers")
    .select("*")
    .eq("id", id)
    .single();
  if (error) throw error;
  if (!data) throw new Error("not found");
  return data;
}

export async function respondToOffer(id, response) {
  const { error } = await supabase
    .from("realtor_offers")
    .update({ buyer_response: response })
    .eq("id", id);
  if (error) throw error;
}
```

- [ ] **Step 2: Manual verification**

Using the smoke-page pattern, signed in as the test buyer, call `listOffersForRequest(<the request id from Task 3>)` and confirm it returns `[]` (no realtor has made an offer yet — this is expected, it just proves the query runs under RLS without error). Delete the smoke file afterward.

- [ ] **Step 3: Commit**

```bash
git add site/js/offers.js
git commit -m "feat: add realtor_offers data helpers for buyer web site"
```

---

## Task 5: Shared stylesheet (`css/style.css`)

**Files:**
- Create: `site/css/style.css`

**Interfaces:**
- Produces: CSS custom properties `--color-honey`, `--color-cardamom`, `--color-bg`, `--color-text`, `--font-display`, `--font-body`, and utility classes `.container`, `.card`, `.btn`, `.btn-primary`, `.form-field`, `.error-text` — every page's markup in Tasks 6-10 uses these class names.

- [ ] **Step 1: Create `site/css/style.css`**

```css
@import url('https://fonts.googleapis.com/css2?family=Aref+Ruqaa:wght@400;700&family=IBM+Plex+Sans+Arabic:wght@400;500;700&display=swap');

:root {
  --color-honey: #d99a3f;
  --color-cardamom: #4a5d3a;
  --color-bg: #fdf8f0;
  --color-text: #2e2a24;
  --color-border: #e3d5b8;
  --font-display: 'Aref Ruqaa', serif;
  --font-body: 'IBM Plex Sans Arabic', sans-serif;
}

* { box-sizing: border-box; }

body {
  margin: 0;
  font-family: var(--font-body);
  background: var(--color-bg);
  color: var(--color-text);
  direction: rtl;
}

h1, h2, h3 { font-family: var(--font-display); color: var(--color-cardamom); }

.container { max-width: 720px; margin: 0 auto; padding: 1.5rem; }

.card {
  background: #fff;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  padding: 1.25rem;
  margin-bottom: 1rem;
}

.btn {
  display: inline-block;
  padding: 0.6rem 1.2rem;
  border-radius: 8px;
  border: 1px solid var(--color-border);
  background: #fff;
  color: var(--color-text);
  font-family: var(--font-body);
  font-size: 1rem;
  cursor: pointer;
  text-decoration: none;
}

.btn-primary {
  background: var(--color-honey);
  border-color: var(--color-honey);
  color: #fff;
}

.form-field { margin-bottom: 1rem; display: flex; flex-direction: column; gap: 0.3rem; }
.form-field input, .form-field select, .form-field textarea {
  padding: 0.5rem;
  border: 1px solid var(--color-border);
  border-radius: 6px;
  font-family: var(--font-body);
  font-size: 1rem;
}

.error-text { color: #b3261e; font-size: 0.9rem; }
```

- [ ] **Step 2: Manual verification**

There's no page to load yet — visually confirm by opening the CSS file and checking the Google Fonts URL loads (paste it into a browser tab; it should return CSS text, not a 404).

- [ ] **Step 3: Commit**

```bash
git add site/css/style.css
git commit -m "feat: add shared stylesheet for buyer web site"
```

---

## Task 6: Landing/login/signup page (`index.html`)

**Files:**
- Create: `site/index.html`

**Interfaces:**
- Consumes: `signUpBuyer`, `signIn` from `./js/auth.js` (Task 2).

- [ ] **Step 1: Create `site/index.html`**

```html
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>دبّرلي</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
  <div class="container">
    <h1>دبّرلي</h1>
    <p>انشر مواصفات العقار الذي تبحث عنه، ودع الوسطاء الموثوقين يرسلون لك عروضهم.</p>

    <div class="card">
      <h2 id="form-title">تسجيل الدخول</h2>
      <form id="auth-form">
        <div class="form-field">
          <label for="email">البريد الإلكتروني</label>
          <input type="email" id="email" required>
        </div>
        <div class="form-field" id="name-field" hidden>
          <label for="full-name">الاسم الكامل</label>
          <input type="text" id="full-name">
        </div>
        <div class="form-field">
          <label for="password">كلمة المرور</label>
          <input type="password" id="password" required minlength="6">
        </div>
        <p class="error-text" id="error" hidden></p>
        <button type="submit" class="btn btn-primary" id="submit-btn">دخول</button>
      </form>
      <p>
        <a href="#" id="toggle-mode">ليس لديك حساب؟ أنشئ حسابًا جديدًا</a>
      </p>
    </div>
  </div>

  <script type="module">
    import { signUpBuyer, signIn } from "./js/auth.js";
    import { supabase } from "./js/supabase-client.js";

    let mode = "signin";
    const form = document.getElementById("auth-form");
    const nameField = document.getElementById("name-field");
    const formTitle = document.getElementById("form-title");
    const submitBtn = document.getElementById("submit-btn");
    const toggle = document.getElementById("toggle-mode");
    const errorEl = document.getElementById("error");

    supabase.auth.getSession().then(({ data }) => {
      if (data.session) window.location.href = "dashboard.html";
    });

    toggle.addEventListener("click", (e) => {
      e.preventDefault();
      mode = mode === "signin" ? "signup" : "signin";
      nameField.hidden = mode === "signin";
      formTitle.textContent = mode === "signin" ? "تسجيل الدخول" : "إنشاء حساب";
      submitBtn.textContent = mode === "signin" ? "دخول" : "إنشاء حساب";
      toggle.textContent = mode === "signin"
        ? "ليس لديك حساب؟ أنشئ حسابًا جديدًا"
        : "لديك حساب بالفعل؟ سجّل الدخول";
      errorEl.hidden = true;
    });

    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      errorEl.hidden = true;
      const email = document.getElementById("email").value;
      const password = document.getElementById("password").value;
      const fullName = document.getElementById("full-name").value;

      const { error } =
        mode === "signin"
          ? await signIn(email, password)
          : await signUpBuyer(email, password, fullName);

      if (error) {
        errorEl.textContent = error.message;
        errorEl.hidden = false;
        return;
      }
      window.location.href = "dashboard.html";
    });
  </script>
</body>
</html>
```

- [ ] **Step 2: Manual verification**

Serve `site/` with `python3 -m http.server 8000` and open `http://localhost:8000/index.html`. Toggle to signup, create a new buyer account with a real-looking test email/password, confirm it redirects to `dashboard.html` (a 404 is fine at this point — Task 7 hasn't been created yet, but the redirect itself proves signup succeeded). Reload `index.html` directly and confirm signing in with the same credentials also redirects.

- [ ] **Step 3: Commit**

```bash
git add site/index.html
git commit -m "feat: add landing/login/signup page for buyer web site"
```

---

## Task 7: Dashboard page (`dashboard.html`)

**Files:**
- Create: `site/dashboard.html`

**Interfaces:**
- Consumes: `requireSession`, `signOut` from `./js/auth.js` (Task 2); `listMyRequests` from `./js/requests.js` (Task 3).

- [ ] **Step 1: Create `site/dashboard.html`**

```html
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>طلباتي — دبّرلي</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
  <div class="container">
    <div style="display:flex; justify-content:space-between; align-items:center;">
      <h1>طلباتي</h1>
      <button class="btn" id="signout-btn">تسجيل الخروج</button>
    </div>
    <a href="request-new.html" class="btn btn-primary">+ طلب جديد</a>
    <div id="requests-list" style="margin-top:1.5rem;"></div>
    <p id="empty-msg" hidden>لا توجد طلبات بعد.</p>
  </div>

  <script type="module">
    import { requireSession, signOut } from "./js/auth.js";
    import { listMyRequests } from "./js/requests.js";

    await requireSession();
    document.getElementById("signout-btn").addEventListener("click", signOut);

    const requests = await listMyRequests();
    const list = document.getElementById("requests-list");
    if (requests.length === 0) {
      document.getElementById("empty-msg").hidden = false;
    }
    for (const r of requests) {
      const a = document.createElement("a");
      a.href = `request.html?id=${r.id}`;
      a.style.textDecoration = "none";
      a.style.color = "inherit";
      a.innerHTML = `
        <div class="card">
          <h3>${r.title}</h3>
          <p>${r.city} — ${r.category}</p>
        </div>
      `;
      list.appendChild(a);
    }
  </script>
</body>
</html>
```

- [ ] **Step 2: Manual verification**

With the local static server still running, sign in via `index.html` using the Task 6 test account and confirm redirect lands on a working dashboard listing the request created in Task 3's verification step (or showing the empty message if none exist for this account). Click "تسجيل الخروج" and confirm it redirects back to `index.html`. Then open `dashboard.html` directly in a private/incognito window (no session) and confirm it redirects to `index.html`.

- [ ] **Step 3: Commit**

```bash
git add site/dashboard.html
git commit -m "feat: add buyer dashboard page"
```

---

## Task 8: Create-request page (`request-new.html`)

**Files:**
- Create: `site/request-new.html`

**Interfaces:**
- Consumes: `requireSession` from `./js/auth.js` (Task 2); `createRequest` from `./js/requests.js` (Task 3).

- [ ] **Step 1: Create `site/request-new.html`**

```html
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>طلب جديد — دبّرلي</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
  <div class="container">
    <h1>طلب جديد</h1>
    <form id="request-form" class="card">
      <div class="form-field">
        <label for="category">الفئة</label>
        <select id="category" required>
          <option value="residential">سكني</option>
          <option value="commercial">تجاري</option>
          <option value="land">أرض</option>
        </select>
      </div>
      <div class="form-field">
        <label for="title">عنوان الطلب</label>
        <input type="text" id="title" required>
      </div>
      <div class="form-field">
        <label for="description">الوصف</label>
        <textarea id="description"></textarea>
      </div>
      <div class="form-field">
        <label for="city">المدينة</label>
        <input type="text" id="city" required>
      </div>
      <div class="form-field">
        <label for="area-name">المنطقة</label>
        <input type="text" id="area-name">
      </div>
      <div class="form-field">
        <label for="min-price">أقل سعر</label>
        <input type="number" id="min-price">
      </div>
      <div class="form-field">
        <label for="max-price">أعلى سعر</label>
        <input type="number" id="max-price">
      </div>
      <div class="form-field">
        <label for="bedrooms">عدد غرف النوم</label>
        <input type="number" id="bedrooms">
      </div>
      <div class="form-field">
        <label for="bathrooms">عدد الحمامات</label>
        <input type="number" id="bathrooms">
      </div>
      <div class="form-field">
        <label><input type="checkbox" id="furnished"> مفروش</label>
      </div>
      <p class="error-text" id="error" hidden></p>
      <button type="submit" class="btn btn-primary">إرسال الطلب</button>
    </form>
  </div>

  <script type="module">
    import { requireSession } from "./js/auth.js";
    import { createRequest } from "./js/requests.js";

    await requireSession();

    document.getElementById("request-form").addEventListener("submit", async (e) => {
      e.preventDefault();
      const errorEl = document.getElementById("error");
      errorEl.hidden = true;

      const val = (id) => document.getElementById(id).value;
      const num = (id) => (val(id) === "" ? null : Number(val(id)));

      try {
        await createRequest({
          category: val("category"),
          title: val("title"),
          description: val("description") || null,
          city: val("city"),
          area_name: val("area-name") || null,
          min_price: num("min-price"),
          max_price: num("max-price"),
          bedrooms: num("bedrooms"),
          bathrooms: num("bathrooms"),
          furnished: document.getElementById("furnished").checked,
        });
        window.location.href = "dashboard.html";
      } catch (err) {
        errorEl.textContent = err.message;
        errorEl.hidden = false;
      }
    });
  </script>
</body>
</html>
```

- [ ] **Step 2: Manual verification**

Signed in, navigate from the dashboard's "+ طلب جديد" link, fill the form with a new title/city, submit, and confirm redirect to `dashboard.html` with the new request now listed at the top.

- [ ] **Step 3: Commit**

```bash
git add site/request-new.html
git commit -m "feat: add create-request page"
```

---

## Task 9: Request detail page (`request.html`)

**Files:**
- Create: `site/request.html`

**Interfaces:**
- Consumes: `requireSession` from `./js/auth.js` (Task 2); `getRequest` from `./js/requests.js` (Task 3); `listOffersForRequest` from `./js/offers.js` (Task 4).

- [ ] **Step 1: Create `site/request.html`**

```html
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>تفاصيل الطلب — دبّرلي</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
  <div class="container">
    <a href="dashboard.html" class="btn">→ رجوع</a>
    <div id="request-detail"></div>
    <h2>العروض</h2>
    <div id="offers-list"></div>
    <p id="empty-msg" hidden>لا توجد عروض بعد على هذا الطلب.</p>
  </div>

  <script type="module">
    import { requireSession } from "./js/auth.js";
    import { getRequest } from "./js/requests.js";
    import { listOffersForRequest } from "./js/offers.js";

    await requireSession();

    const requestId = new URLSearchParams(window.location.search).get("id");
    const request = await getRequest(requestId);

    document.getElementById("request-detail").innerHTML = `
      <div class="card">
        <h1>${request.title}</h1>
        <p>${request.city} — ${request.category}</p>
        <p>${request.description ?? ""}</p>
      </div>
    `;

    const offers = await listOffersForRequest(requestId);
    const list = document.getElementById("offers-list");
    if (offers.length === 0) {
      document.getElementById("empty-msg").hidden = false;
    }
    for (const o of offers) {
      const a = document.createElement("a");
      a.href = `offer.html?id=${o.id}`;
      a.style.textDecoration = "none";
      a.style.color = "inherit";
      a.innerHTML = `
        <div class="card">
          <h3>${o.property_title}</h3>
          <p>${o.offered_price} ${o.currency}</p>
        </div>
      `;
      list.appendChild(a);
    }
  </script>
</body>
</html>
```

- [ ] **Step 2: Manual verification**

Signed in, click into a request from the dashboard and confirm its title/city/description render and the offers section shows the empty message (no offers exist yet in the test data). Directly edit the URL's `id` query param to a random UUID and confirm the page fails gracefully (a JS error in the console is acceptable at this MVP stage — no request row belongs to another buyer under RLS, so `getRequest` throws `not found`; there is no dedicated error UI in this task).

- [ ] **Step 3: Commit**

```bash
git add site/request.html
git commit -m "feat: add request detail + offers list page"
```

---

## Task 10: Offer detail page (`offer.html`)

**Files:**
- Create: `site/offer.html`

**Interfaces:**
- Consumes: `requireSession` from `./js/auth.js` (Task 2); `getOffer`, `respondToOffer` from `./js/offers.js` (Task 4).

- [ ] **Step 1: Create `site/offer.html`**

```html
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>تفاصيل العرض — دبّرلي</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
  <div class="container">
    <a href="#" id="back-link" class="btn">→ رجوع</a>
    <div id="offer-detail"></div>
    <div id="response-buttons"></div>
    <p id="response-status" hidden></p>
  </div>

  <script type="module">
    import { requireSession } from "./js/auth.js";
    import { getOffer, respondToOffer } from "./js/offers.js";

    await requireSession();

    const offerId = new URLSearchParams(window.location.search).get("id");
    const offer = await getOffer(offerId);

    document.getElementById("back-link").href = `request.html?id=${offer.request_id}`;

    document.getElementById("offer-detail").innerHTML = `
      <div class="card">
        <h1>${offer.property_title}</h1>
        <p>${offer.property_address}</p>
        <p>${offer.offered_price} ${offer.currency}</p>
        <p>${offer.property_description ?? ""}</p>
        <p>${offer.message_to_buyer ?? ""}</p>
      </div>
    `;

    const buttons = document.getElementById("response-buttons");
    const status = document.getElementById("response-status");

    function renderButtons() {
      buttons.innerHTML = `
        <button class="btn btn-primary" id="interested-btn">مهتم</button>
        <button class="btn" id="not-interested-btn">غير مهتم</button>
      `;
      document.getElementById("interested-btn").addEventListener("click", () => respond("interested"));
      document.getElementById("not-interested-btn").addEventListener("click", () => respond("not_interested"));
    }

    async function respond(response) {
      await respondToOffer(offerId, response);
      status.textContent = response === "interested" ? "تم إرسال اهتمامك" : "تم تسجيل عدم الاهتمام";
      status.hidden = false;
      buttons.innerHTML = "";
    }

    renderButtons();
  </script>
</body>
</html>
```

- [ ] **Step 2: Manual verification**

Since no realtor offers exist yet in test data, verify this page by inserting one test row directly via the Supabase SQL editor (`insert into realtor_offers (realtor_id, request_id, property_title, property_address, offered_price) values (<any existing realtor's user id>, '<the test request id>', 'شقة تجريبية', 'بغداد - الكرادة', 150000000)`), then load `offer.html?id=<that offer's id>` while signed in as the buyer who owns the request. Confirm the details render, click "مهتم", and confirm the status message appears and the buttons disappear. Check in the SQL editor that `buyer_response` updated to `'interested'`.

- [ ] **Step 3: Commit**

```bash
git add site/offer.html
git commit -m "feat: add offer detail + respond page"
```

---

## Task 11: nginx deployment on the DigitalOcean droplet

**Files:**
- Create (on server, not in git): `/etc/nginx/sites-available/dabberli`
- Modify (on server, not in git): `/etc/nginx/sites-enabled/` (symlink)

**Interfaces:** None — this task has no code interface, it wires the already-committed `site/` directory to nginx.

- [ ] **Step 1: Install nginx on the droplet**

SSH to the droplet and run:

```bash
apt-get update && apt-get install -y nginx
```

- [ ] **Step 2: Confirm the repo checkout on the server is up to date**

```bash
cd ~/360home && git pull origin claude/dabberli-architecture-phase1-tx1zoi
ls site/index.html
```

Expected: `site/index.html` exists (proves Tasks 1-10 have landed on the server).

- [ ] **Step 3: Write the nginx site config**

Create `/etc/nginx/sites-available/dabberli` with:

```nginx
server {
    listen 80 default_server;
    server_name _;
    root /root/360home/site;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

(Adjust `root` to the actual home directory path the repo is checked out under on the server, e.g. `/home/devuser/360home/site` if not running as root — confirm with `pwd` after `cd ~/360home`.)

- [ ] **Step 4: Enable the site and reload nginx**

```bash
ln -sf /etc/nginx/sites-available/dabberli /etc/nginx/sites-enabled/dabberli
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
```

Expected: `nginx -t` prints `syntax is ok` / `test is successful`.

- [ ] **Step 5: Manual verification**

From a browser (or `curl` from any machine, not just the server itself), open `http://46.101.175.29/` and confirm the Dabberli landing page loads with correct RTL layout and fonts. Sign up a fresh test buyer through the live site, create a request, and confirm it shows up on the dashboard — this exercises the real deployed Supabase connection end-to-end.

- [ ] **Step 6: Commit**

No git commit for this task (server-only nginx config, not part of the repo). If a note is wanted for future reference, append one line to `CONVENTIONS.md` documenting the nginx config path, and commit that:

```bash
git add CONVENTIONS.md
git commit -m "docs: note nginx deployment path for buyer web site"
```

---

## Self-Review Notes

- **Spec coverage:** All 5 pages (§4), auth/data access via RLS (§5), config.js with real URL/key (§5), visual design tokens (§6), nginx deployment on the same droplet (§7), manual-only testing (§8) are each covered by a task above.
- **Placeholder scan:** No TBD/TODO; Task 11's `root` path is flagged as needing on-server confirmation rather than left vague, since the actual home directory depends on which user the pilot's checkout runs as.
- **Type consistency:** `PropertyRequest`/`RealtorOffer` field names used across Tasks 6-10 (`title`, `city`, `category`, `property_title`, `offered_price`, `currency`, `request_id`, `buyer_response`) all match the columns defined in `supabase/migrations/20260908000001_initial_schema.sql`.
