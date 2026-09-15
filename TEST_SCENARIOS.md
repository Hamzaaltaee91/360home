# Dabberli — End-to-End Test Scenarios

Manual test script against the **live** app (Flutter mobile/web + `site/`
admin panel) and the **live** Supabase project (`ojnhaqpiufgfxusokazb`).
Written 2026-09-15, after the full security review + fixes on this branch.

---

## 0. Demo accounts — one-time setup

Three accounts, created via the real signup flow (no shortcuts — this
exercises the actual signup path as a real user will hit it):

| Role (final) | Email | Password | Notes |
|---|---|---|---|
| Buyer | `demo.buyer@dabberli.test` | `DemoBuyer!2026` | Stays a buyer — signup is buyer-only now |
| Realtor | `demo.realtor@dabberli.test` | `DemoRealtor!2026` | Signs up as buyer, then applies to become a realtor (step below) |
| Admin | `demo.admin@dabberli.test` | `DemoAdmin!2026` | Signs up as buyer, role elevated to admin directly in DB (no self-serve path — that's intentional) |

**Steps:**
1. Sign up all three emails/passwords above through the Flutter app or
   `site/signup.html` (every signup is buyer-only now — role selection
   was intentionally removed).
2. Tell me once all three are created — I'll confirm their emails
   (`auth.users.email_confirmed_at`) via SQL if signup requires email
   verification, so login works immediately without needing real inbox
   access.
3. For the **realtor** demo account: either (a) go through the real
   "سجّل كوسيط" flow in the app/`become-realtor.html` (submit company
   name, license number, license expiry, WhatsApp — realistic test of
   that flow), then tell me to approve it as if I were the admin — or
   (b) tell me to skip straight to a pre-verified realtor row for speed.
   Either way I do the actual approval/verification write via SQL —
   this is a data change, not an RLS/migration change, so it's in scope
   for me to do directly.
4. For the **admin** demo account: I set `role = 'admin'` directly on
   its `public.users` row via SQL. There is deliberately no in-app way
   to do this (that's the fix from today's security review), so this
   step can only happen from my side or the Supabase dashboard.

Tell me when step 1 is done and I'll do 2-4.

---

## 1. Buyer journey (`demo.buyer@dabberli.test`)

1. **Sign up / log in** — email+password, and separately test Google
   Sign-In on web (this broke once before — commit `4721764` — worth
   re-confirming it still works).
2. **Create a property request** (`buyer_home_screen.dart` → create):
   - category: `residential`, purpose: `rent`
   - governorate: pick one of the 18 (e.g. `baghdad`), area: pick a
     listed sub-area or "أخرى" (other) with free text
   - property_subtype: `apartment`
   - rental_period: `monthly` (only shown when purpose = rent)
   - price range, bedrooms/bathrooms, currency selector (should default
     to IQD, confirm the dropdown offers other options too)
3. **View own requests** on the home screen; confirm it appears with
   status `active`.
4. **Browse offers tab** — empty until the realtor demo submits one
   (do section 2 first, then come back).
5. Once an offer exists: open it, respond `interested` /
   `not_interested`. Confirm you **cannot** edit price/title/status on
   the offer (that's the bug fixed today — try it via the site's
   `offers.js` / a REST call directly if you want to actively confirm
   the fix, expect a rejection).
6. **Chats tab** — after responding, open the conversation with the
   realtor, send a message, confirm it's received (test realtime if
   two sessions open).
7. **Leave a review** on the offer once accepted (star rating +
   comment).
8. **Report/block** the realtor from the chat screen's menu — confirm
   an admin-side report entry is created (check in admin flow, section
   3).
9. **Profile screen** — confirm the bottom nav now appears (today's
   fix), shows buyer's 4 items, badge on "العروض" reflects pending
   offer count.
10. **"سجّل كوسيط"** entry point visible (buyer-only) — don't submit
    here, that's the realtor demo's job.
11. **Delete account flow** — do NOT actually confirm deletion on the
    demo account you want to keep reusing; just confirm the
    confirmation dialog appears and cancel out.

## 2. Realtor journey (`demo.realtor@dabberli.test`)

1. **Log in**, confirm realtor home screen loads once verified (before
   verification, offer-creation should be blocked — worth testing
   pre-verification too, to confirm `realtor_offers_insert_own`'s
   `verified_at IS NOT NULL` check holds).
2. **Browse requests** tab — should show the buyer demo's active
   request (and *only* active ones — try to confirm you can't see
   inactive/sold requests via this screen or the `search-requests`
   edge function directly).
3. **Create an offer** on that request: price, property title/address,
   photos (tests the now-scoped `dabberli` bucket upload — confirm it
   still works for your own offer's `offer-photos/<offerId>/` path),
   lease type, area/bedrooms/bathrooms.
4. **My Offers** — confirm it shows with `status: pending`.
5. Wait for buyer's response (section 1 step 5) — confirm
   `buyer_response` updates and a notification/chat thread appears.
6. **Chats tab** — reply to the buyer.
7. **Realtor home stats** (`getRealtorStats` via `analytics` function)
   — confirm total/accepted/rejected/pending counts update correctly
   after the buyer responds. This exercises the now-authenticated
   `analytics` edge function end-to-end — good smoke test that
   today's edge-function auth deploy didn't break the real call path.
8. **Verification/reviews** — after buyer leaves a review, confirm it
   shows on the realtor's public profile / ratings summary.

## 3. Admin journey (`demo.admin@dabberli.test`)

1. **Log in**, confirm admin dashboard loads with no bottom nav (per
   today's fix — role == 'admin' → null bottom nav, by design).
2. **Verify realtors** screen — approve/reject the realtor demo's
   application (if you went the real-application route in section
   0.3a). Confirm `verified_at` gets set and the realtor can now create
   offers.
3. **Manage users** screen — confirm you can view all users, and that
   the "update role" action still works (uses the
   `admin_set_user_role` RPC, unaffected by today's changes).
4. **Reports** screen (`admin-reports.html` or its Flutter equivalent)
   — resolve the report the buyer filed in section 1 step 8.
5. **Storage/KYC document review** — open the realtor's uploaded
   license document from the verification screen; confirm it loads via
   a **signed URL** now (today's fix), not a raw public link, and that
   the link expires after the signed URL's TTL.

## 4. Cross-cutting / regression checks

- **Google Sign-In on web** — confirm login works end to end (this
  specific flow broke once already).
- **Currency selector** — confirm both create-request and create-offer
  screens default to IQD, not the DB's old AED default.
- **Governorate/area/purpose/rental_period fields** — confirm they
  round-trip correctly (create with them, reload the request, values
  still there).
- **Attempt privilege escalation as the buyer demo** (confirms today's
  fixes hold): try to `PATCH` your own `public.users` row to set
  `is_verified: true` or `role: 'admin'` directly via the REST API —
  both should be rejected now.
- **Attempt to write another user's storage path** (buyer demo trying
  to upload to the realtor demo's `profile-pictures/<realtor-id>/...`
  prefix) — should be rejected.
- **Call `search-requests` / `match-offers` / `analytics` /
  `send-notification` edge functions with no Authorization header** —
  all four should now return 401, not data.

---

## Notes for whoever runs this

- All 4 fixed edge functions were deployed live for the first time
  today (they existed in the repo but were never deployed before) —
  section 4's last bullet is the most important regression check in
  this whole doc.
- If anything here fails, it's either a real regression from today's
  fixes or a pre-existing gap — either way, tell me which step and
  I'll dig in.
