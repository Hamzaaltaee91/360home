# Dabberli Buyer Web Site — Design Spec

**Date:** 2026-09-12
**Status:** Approved for planning
**Scope:** Buyer flow only (MVP). Realtor and admin flows are out of scope for this spec.

## 1. Purpose

Replace the Flutter-web build as the way browser users reach Dabberli, with a
plain HTML/CSS/JS static site. Flutter continues to serve iOS/Android; the
Flutter web target is dropped in favor of this site once it covers the buyer
flow. No backend service is introduced — the site talks directly to the same
Supabase project the Flutter app uses, the same way the Flutter app does.

## 2. Non-goals

- No realtor or admin UI in this iteration.
- No build tooling (no npm, no bundler, no framework). Plain files served as-is.
- No automated test suite — verification is manual (open pages, exercise the
  flow) per the project's existing testing conventions for this kind of asset.
- No HTTPS/custom domain yet (no domain is registered); served over plain
  HTTP by IP.

## 3. Architecture

A new top-level directory `site/` in the existing `360home` repo, sitting
alongside `lib/`, `supabase/`, etc. It is intentionally **not** named `web/`
so it never collides with Flutter's own generated `web/` build output.

```
site/
  index.html            Landing + login + signup (tabs or toggle, one page)
  dashboard.html         Buyer's own property requests, newest first
  request-new.html       Form to create a new property request
  request.html            Single request's details + offers received on it
  offer.html               Single offer's details + accept/reject actions
  css/
    style.css             All styling: palette, typography, RTL layout
  js/
    config.js              SUPABASE_URL / SUPABASE_ANON_KEY constants
    supabase-client.js      Initializes the Supabase JS client (CDN import)
    auth.js                 signUp/signIn/signOut/getSession helpers
    requests.js             CRUD helpers for property_requests
    offers.js               Read/respond helpers for realtor_offers
```

Each HTML page loads `config.js` then `supabase-client.js` then the page's
own script, in that order, via plain `<script src="...">` tags (no modules
bundler; native `type="module"` is fine since browsers support it directly).

Supabase JS is loaded from a CDN:
`https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.js`
(pin an exact version once picked, don't float `@latest`).

## 4. Pages & flows

- **index.html** — Public landing copy (what Dabberli is) plus a login form
  and a "create account" form (toggle between the two, no page navigation
  needed for that switch). On successful login/signup, redirect to
  `dashboard.html`. Signup calls `supabase.auth.signUp` with
  `options.data.role = 'buyer'` and `full_name` — the existing
  `handle_new_user` trigger creates the matching `public.users` row
  automatically; the site does not insert into `public.users` itself.
- **dashboard.html** — Requires an active session (redirect to `index.html`
  if not signed in). Lists the signed-in buyer's own `property_requests`
  (`select * from property_requests where buyer_id = auth.uid()`), newest
  first, each linking to `request.html?id=<uuid>`. A button links to
  `request-new.html`.
- **request-new.html** — Form covering the core `property_requests` fields
  from `supabase/migrations/20260908000001_initial_schema.sql`: category
  (residential/commercial/land), title, description, city, area_name,
  min_price/max_price, bedrooms, bathrooms, furnished. On submit, insert a
  row with `buyer_id = auth.uid()` and redirect to `dashboard.html`.
- **request.html?id=`<uuid>`** — Shows that one request's details, and lists
  `realtor_offers` where `request_id = id`, each linking to
  `offer.html?id=<uuid>`.
- **offer.html?id=`<uuid>`** — Shows one offer's details (price, realtor
  contact info via a public-safe view of `users`, photos if present) with
  "interested" / "not interested" buttons that update
  `realtor_offers.buyer_response`.

## 5. Auth & data access

Session handled entirely by the Supabase JS client (it persists to
`localStorage` itself — no custom session code needed). Every protected page
starts with `await supabase.auth.getSession()`; if there's no session,
redirect to `index.html`. All reads/writes rely on the RLS policies already
defined in `supabase/migrations/20260908000002_rls_policies.sql` — the site
does not duplicate authorization logic client-side beyond hiding UI for
signed-out users.

`js/config.js` holds the Supabase URL and anon key as plain constants — this
is not a secret (Supabase's anon key is designed for client exposure and is
already embedded in the compiled Flutter web bundle today):

```js
const SUPABASE_URL = "https://ojnhaqpiufgfxusokazb.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";
```

## 6. Visual design

Reuses the existing Dabberli design system (warm/hospitality identity):
honey + cardamom color palette, Aref Ruqaa for display/headings and IBM Plex
Sans Arabic for body text (both loadable from Google Fonts), full RTL layout
(`<html lang="ar" dir="rtl">`). One shared `css/style.css`; no per-page
stylesheets.

## 7. Deployment

nginx is installed on the existing DigitalOcean droplet (46.101.175.29),
which does not currently run any web server. Its site root points directly
at `~/360home/site/` on that same box — the same checkout the pilot already
works in. Because of that, no separate deploy/publish step exists: every
`git pull` that lands new commits on `site/` is live immediately. Served
over plain HTTP on port 80 (no domain yet, so no TLS/certbot in this pass);
revisit HTTPS once a domain is pointed at the server.

## 8. Testing

No automated test suite for this static site. Verification is manual:
load each page in a browser, sign up a test buyer, create a request, and
confirm it appears on the dashboard. This matches the project's existing
practice for hand-verified UI work.

## 9. Out of scope / follow-ups

- Realtor and admin web flows (separate future spec).
- HTTPS via Let's Encrypt once a domain exists.
- Any build tooling, should the vanilla approach outgrow itself.
