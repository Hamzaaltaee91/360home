
# TODO — Dabberli Architecture Action Plan

> Comprehensive action plan based on current project architecture.
> Status: Phase 1 (Setup) & Phase 2 (Backend) partially done, Phase 3 (Flutter Web) in progress.

---

## 1. Infrastructure & Setup

- [x] **Fix Provider name clash** — In lib/providers/auth_provider.dart and lib/providers/notifications_provider.dart, the name Provider is ambiguous between supabase_flutter and flutter_riverpod. Add `hide Provider` to the supabase_flutter import in both files. Do not rename anything else.
- [x] **Fix broken constructors in models.dart** — Lines 327 and 550 pass too many positional arguments to Object.hash. Split the argument list so no call exceeds 20 positional arguments. Change nothing else in the file.
- [x] **Fix go_router deprecated API** — In lib/routes/app_routes.dart line 321, GoRouterState.location no longer exists. Replace it with state.matchedLocation. Change nothing else.
- [x] **Create missing RequestDetailsScreen** — lib/routes/app_routes.dart imports lib/screens/buyer/request_details_screen.dart which does not exist. Create a minimal StatelessWidget named RequestDetailsScreen that takes a requestId String and shows a Scaffold with the id. Follow the style of the other screens in that folder.
- [x] **Fix pagination type mismatches** — Several screens assign Future<PaginatedResult<T>> to Future<List<T>>. In lib/screens/buyer/buyer_home_screen.dart and any other screen with the same error, change the variable types to match what the service returns. Do not change the service signatures.

- [x] **Add price formatting helper** — Create lib/utils/formatters.dart with a single top-level function formatPrice(num value) that returns the value grouped with commas and suffixed with ' IQD'. Pure Dart only, no new packages, no Flutter imports. Add a matching test in test/utils/formatters_test.dart.

- [x] **Move admin Supabase calls to service layer** — In lib/screens/admin/manage_users_screen.dart, move the two direct Supabase calls (list users, update role) into lib/services/supabase_service.dart as listUsers() and updateUserRole(), then use them from the screen. Do not change any RLS policy or SQL.


- [x] **Setup `.env.local`** — Create environment file with `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- [x] **Verify `pubspec.yaml`** — Verify dependencies (`supabase_flutter`, `go_router`, `flutter_dotenv`, `intl`, `image_picker`, `geolocator`).
- [x] **Configure `analysis_options.yaml`** — Set up lint rules.
- [x] **Setup CI/CD** — Configure `.github/workflows/` for Flutter analyze & test on push.
- [x] **Local Supabase Environment** — Run `supabase start` and apply migrations.

---

## 2. Database & Migrations

- [x] **Review `initial_schema.sql`** — Ensure core tables: users, requests, offers, notifications, verifications, photos.
- [x] **Review `rls_policies.sql`** — Ensure RLS policies for buyer, realtor, and admin.
- [x] **Review `functions_and_triggers.sql`** — Triggers for `updated_at` and auto-creating users.
- [x] **Review `phase2_rpc_functions.sql`** — RPCs: `match_offers`, `search_requests`, `get_realtor_stats`, `get_buyer_stats`.
- [x] **Index Migrations** — Indexes for `city`, `category`, `status`, `buyer_id`, `realtor_id`, `request_id`.
- [x] **PostGIS Migration** — PostGIS extension for geo/radius search.
- [x] **Notifications Table Migration** — Notification fields, types, and read status.
- [x] **Realtor Verifications Migration** — Verification requests table.
- [x] **Create Seed Data** — Write `supabase/seed.sql` with sample test data (users, requests, offers).

---

## 3. Edge Functions

- [x] **Test `analytics/index.ts`** — Unit tests for realtor, buyer, and platform stats.
- [x] **Test `match-offers/index.ts`** — Matching logic by category, budget, and location.
- [x] **Test `search-requests/index.ts`** — Radius search and advanced filtering.
- [x] **Test `send-notification/index.ts`** — In-app and email notifications.
- [x] **Test `verify-realtor/index.ts`** — Verification approval/rejection logic.
- [x] **Create `create-checkout` Function** — Subscription payment handling via Stripe/local gateway.
- [x] **Create `webhook-handler` Function** — Process payment gateway webhooks and update subscription status.
- [x] **Create `delete-account` Function** — GDPR-compliant user account and data deletion.
- [x] **Configure CORS Headers** — Verify CORS headers for Flutter Web requests across all functions.

---

## 4. Services Layer

- [x] **Complete `supabase_service.dart`** — Refactor error handling (try/catch) and return standard user messages.
- [x] **Implement `notification_service.dart`** — Fetch, mark as read, and subscribe to realtime events.
- [x] **Implement `storage_service.dart`** — Upload/delete images via Supabase Storage.
- [x] **Implement `location_service.dart`** — Current location capture and distance calculation.
- [x] **Implement `payment_service.dart`** — Subscription and payment lifecycle handling.
- [x] **Implement `analytics_service.dart`** — Data fetching from analytics Edge Function.
- [x] **Implement Global Error Handler** — Create `lib/utils/error_handler.dart` to standardize Supabase errors.
- [x] **Implement Validators** — Create `lib/utils/validators.dart` for email, phone, price validation.

---

## 5. Models

- [x] **Add `Notification` Model** — Include `fromJson` and `toJson`.
- [x] **Add `RealtorVerification` Model** — Verification request data structure.
- [x] **Add `PropertyPhoto` Model** — Property image attachment model.
- [x] **Add `Subscription` Model** — Realtor subscription state.
- [x] **Add `copyWith` Methods** — Implement `copyWith` on all domain models for state management.
- [x] **Implement Equality (`==` and `hashCode`)** — Consistent value equality across models.
- [x] **Add `toJson` to `PropertyMatch`** — Implement serialization for `PropertyMatch`.

---

## 6. Routing

- [x] **Review `app_routes.dart`** — Verify route definitions (`/splash`, `/login`, `/signup`, `/buyer`, `/realtor`, etc.).
- [x] **Implement Route Guards** — Redirects based on auth state and role (buyer/realtor/admin).
- [x] **Add 404 Screen** — Build fallback `NotFoundScreen`.
- [x] **Implement Deep Linking** — Support direct URL resolution for requests and offers.

---

## 7. Screens

### Authentication
- [x] **Complete `login_screen.dart`** — Add forgot password, remember me, and Supabase auth binding.
- [x] **Complete `signup_screen.dart`** — Password strength validation and terms checkbox.
- [x] **Implement `forgot_password_screen.dart`** — Password reset flow.
- [x] **Implement `verify_email_screen.dart`** — Email verification handler screen.

### Buyer Flow
- [x] **Complete `buyer_home_screen.dart`** — Pull-to-refresh, empty states, and notification badge.
- [x] **Complete `create_request_screen.dart`** — Image upload, geo-location picker, and field validation.
- [x] **Complete `browse_offers_screen.dart`** — Search, sort, and filtering controls.
- [x] **Complete `offer_details_screen.dart`** — Photo viewer, map display, and realtor contact action.
- [x] **Implement `edit_request_screen.dart`** — Request editing workflow.
- [x] **Implement `request_details_screen.dart`** — Details view with received offers list.

### Realtor Flow
- [x] **Complete `realtor_home_screen.dart`** — Dashboard analytics charts integrated with Edge Function.
- [x] **Complete `browse_requests_screen.dart`** — Map search view and filters.
- [x] **Complete `create_offer_screen.dart`** — Photo uploads and geo-location picker.
- [x] **Implement `my_offers_screen.dart`** — List and manage submitted offers.
- [x] **Implement `verification_screen.dart`** — Verification document submission.
- [x] **Implement `subscription_screen.dart`** — Tier selection and payment checkout.

### Profile & Settings
- [x] **Complete `profile_screen.dart`** — Replace placeholder with live profile data display.
- [x] **Implement `edit_profile_screen.dart`** — Profile edits and avatar upload.
- [x] **Implement `settings_screen.dart`** — Language, notifications, and dark mode toggles.
- [x] **Implement `notifications_screen.dart`** — Notification list view.
- [x] **Implement `about_screen.dart`** — About page and privacy policy view.

### Admin Panel
- [x] **Implement `admin_dashboard_screen.dart`** — Core metric summaries.
- [x] **Implement `verify_realtors_screen.dart`** — Review and approve verification requests.
- [x] **Implement `manage_users_screen.dart`** — User directory and role moderation.

---

## 8. Shared Widgets

- [x] **Build `loading_indicator.dart`** — Standardized progress loader.
- [x] **Build `empty_state.dart`** — Uniform empty state with icon and message.
- [x] **Build `error_widget.dart`** — Reusable error view with retry action.
- [x] **Build `custom_button.dart`** — Common button supporting loading and disabled states.
- [x] **Build `custom_text_field.dart`** — Form text input with inline error validation.
- [x] **Build `property_card.dart`** — Standardized property card.
- [x] **Build `offer_card.dart`** — Standardized offer item card.
- [x] **Build `request_card.dart`** — Standardized request item card.
- [x] **Build `image_picker_widget.dart`** — Multi-image picker and preview component.
- [x] **Build `map_picker.dart`** — Interactive location selector.

---

## 9. State Management

- [x] **Establish State Management Choice** — Select and document Riverpod or Bloc.
- [x] **Implement `auth_provider.dart`** — Global authentication state.
- [x] **Implement `user_provider.dart`** — Current user session and profile data.
- [x] **Implement `requests_provider.dart`** — Buyer requests state.
- [x] **Implement `offers_provider.dart`** — Realtor offers state.
- [x] **Implement `notifications_provider.dart`** — Notification stream state.

---

## 10. Localization & RTL

- [x] **Configure `flutter_localizations`** — Ensure dependencies in `pubspec.yaml`.
- [x] **Setup `l10n.yaml`** — Localization generation configuration.
- [x] **Create `lib/l10n/app_ar.arb`** — Arabic string catalog.
- [x] **Create `lib/l10n/app_en.arb`** — English string catalog.
- [x] **Update `main.dart`** — Register `localizationsDelegates` and `supportedLocales`.
- [x] **Verify RTL Alignment** — Ensure bidirectional layout support.

---

## 11. Testing

### Unit Tests
- [x] **Model Tests** — Unit coverage for User, PropertyRequest, RealtorOffer.
- [x] **Service Tests** — Mock Supabase client tests in `test/services/`.
- [x] **Validator Tests** — Comprehensive validator coverage in `test/utils/`.
- [x] **Error Handler Tests** — Translate and handle Supabase exceptions.

### Widget Tests
- [x] **Screen Tests** — Widget tests for login, signup, request, and offer screens.
- [x] **Component Tests** — Widget tests for shared components.

### Integration Tests
- [x] **Auth Journey** — End-to-end authentication flow.
- [x] **Offer Lifecycle** — Flow: Create Request → Submit Offer → Accept Offer.
- [x] **Verification Workflow** — End-to-end realtor verification submit.

---

## 12. Security & Optimization

- [x] **Audit RLS Policies** — Review all policies against privilege escalation.
- [x] **Rate Limiting** — Enforce rate limits on Edge Functions.
- [x] **Input Sanitization** — Prevent malicious payload injections.
- [x] **Secure Storage** — Secure storage integration for sensitive tokens.
- [x] **Storage Bucket Rules** — Validate access rules for property image buckets.
- [x] **Audit Logging** — Trace sensitive operations (verification, deletion, role modification).
- [x] **Pagination & Lazy Loading** — Implement pagination across requests, offers, and notifications.
- [x] **Image Compression** — Client-side resize and compression before upload.
- [x] **Fix notifications_provider.dart auth check** — In lib/providers/notifications_provider.dart: (1) delete the unused import '../models/pagination.dart'. (2) Replace the call `_service.isAuthenticated()` with `ref.read(authProvider).valueOrNull != null` (authProvider is already imported in this file from 'auth_provider.dart'). Do not change anything else in the file.
- [x] **Remove unused pagination import in offers_provider.dart** — In lib/providers/offers_provider.dart, delete the unused import '../models/pagination.dart' on line 9. Nothing else in the file uses it. Change nothing else.
- [x] **Remove unused geolocator import in create_request_screen.dart** — In lib/screens/buyer/create_request_screen.dart, delete the unused import 'package:geolocator/geolocator.dart' on line 6. Nothing else in the file uses Geolocator. Change nothing else.
- [x] **Remove unused supabase_flutter import in verification_workflow_test.dart** — In integration_test/verification_workflow_test.dart, delete the unused import 'package:supabase_flutter/supabase_flutter.dart' on line 14. The file only uses dabberli's own SupabaseService class, not any supabase_flutter symbol directly. Change nothing else.
- [x] **Fix respondToOffer call in browse_offers_screen.dart** — In lib/screens/buyer/browse_offers_screen.dart line 161, the call `SupabaseService().respondToOffer(offerId, response)` passes positional arguments, but respondToOffer in lib/services/supabase_service.dart requires named parameters `offerId` and `response`. Change the call to `SupabaseService().respondToOffer(offerId: offerId, response: response)`. Do not change the service method. Change nothing else.
- [x] **Fix three unrelated bugs in offer_details_screen.dart** — In lib/screens/buyer/offer_details_screen.dart, fix exactly these three things and nothing else: (1) line 107, change `SupabaseService().respondToOffer(widget.offerId, response)` to `SupabaseService().respondToOffer(offerId: widget.offerId, response: response)` because respondToOffer requires named arguments. (2) line 140, `ConnectionState.loading` does not exist; change it to `ConnectionState.waiting`. (3) line 394, `Icons.furniture` does not exist in Flutter's Icons class; change it to `Icons.chair`.
- [x] **Fix ConnectionState.loading in buyer_home_screen.dart** — In lib/screens/buyer/buyer_home_screen.dart line 69, `ConnectionState.loading` does not exist as a Flutter enum value. Change it to `ConnectionState.waiting`. Change nothing else.
- [x] **Fix three unrelated bugs in create_offer_screen.dart** — In lib/screens/realtor/create_offer_screen.dart, fix exactly these three things and nothing else: (1) line 114, the string interpolation `'${DateTime.now().millisecondsSinceEpoch}_$i_${photo.name}'` is parsed by Dart as referencing an undefined variable named `i_` because `_` is a valid identifier character; change it to `'${DateTime.now().millisecondsSinceEpoch}_${i}_${photo.name}'` so `i` and the literal underscore are separated. (2) line 212, `ConnectionState.loading` does not exist; change it to `ConnectionState.waiting`. (3) around line 335-345, a `TextField` widget is given an `initialValue:` parameter, but plain `TextField` has no such parameter (only `TextFormField` does). Change that `TextField(` widget to `TextFormField(` — keep all of its existing parameters (decoration, keyboardType, initialValue, onChanged) unchanged.
- [x] **Fix variable shadowing in sanitize_test.dart** — In test/functions/sanitize_test.dart inside the `sanitizeInt` function, a local variable is declared as `final num = value is num ? value : double.tryParse(value?.toString() ?? '');` — naming the variable `num` shadows the built-in `num` type and breaks the `is num` type check. Rename only this local variable from `num` to `parsedNum` everywhere it is used within that function (the declaration and its later uses like `num.isFinite`, `num.truncate()`). Do not rename anything else in the file.
- [x] **Fix TextFormField property access in custom_text_field_test.dart** — In test/widgets/custom_text_field_test.dart around line 63-64, the test does `tester.widget<TextFormField>(find.byType(TextFormField))` then reads `.obscureText` on it, but `TextFormField` does not expose `obscureText` as a readable property in this Flutter version (it only forwards it internally to a child `TextField`). Change those two lines to instead find and read it from the inner `TextField`: `tester.widget<TextField>(find.byType(TextField))` and then `expect(field.obscureText, isTrue)` on that. Change nothing else in the file.
- [x] **Fix broken event-handler regex in sanitize_test.dart** — In test/functions/sanitize_test.dart, the `sanitizeString` function has a broken RegExp literal on the line that currently reads exactly: `        RegExp(r'\son[a-z]+\s*=\s*("[^"]*"|''[^'']*''|[^\s>]+)',` — the raw string's embedded `''` sequences accidentally split the literal and corrupted the pattern (verified: it currently compiles to `\son[a-z]+\s*=\s*("[^"]*"|[^]*|[^s>]+)` instead of the intended `\son[a-z]+\s*=\s*("[^"]*"|'[^']*'|[^\s>]+)`). Replace that exact RegExp call (both the pattern string and the following `caseSensitive: false),` line stay conceptually the same, only the pattern string changes) with a non-raw double-quoted string so both quote types can be embedded safely: `        RegExp("\\son[a-z]+\\s*=\\s*(\"[^\"]*\"|'[^']*'|[^\\s>]+)",` — keep the existing `caseSensitive: false),` on the next line unchanged. Do not touch any other regex or line in the file. After the fix, running `flutter test test/functions/sanitize_test.dart` must have zero failures.
- [x] **Fix phone validation regex bounds in validators.dart** — In lib/utils/validators.dart, the `_phoneRegExp` pattern is currently `r'^\+?[0-9][0-9\s\-()]{6,18}[0-9]$'`. This rejects a valid 7-digit phone number like `'1234567'` (needs at least 8 characters total) and rejects numbers starting with `(` like `'(123) 456-7890'` (first character class only allows digits). Replace the pattern with `r'^\+?[0-9(][0-9\s\-()]{5,17}[0-9]$'` (allow first character to be a digit or `(`, and lower the middle-section minimum from 6 to 5). Change nothing else in the file. After the fix, running `flutter test test/utils/validators_test.dart` must have zero failures.
- [x] **Fix two independent bugs in rtl_alignment_test.dart** — In test/rtl_alignment_test.dart, fix exactly these two unrelated things and nothing else: (1) In the `testWidgets('Arabic locale renders right-to-left', ...)` test, the `MaterialApp` is missing localization configuration, so `Locale('ar')` doesn't actually resolve to RTL and the test finds the wrong (default LTR) `Directionality` widget. Add `localizationsDelegates: GlobalMaterialLocalizations.delegates` and `supportedLocales: const [Locale('ar'), Locale('en')]` as named parameters to that test's `MaterialApp` constructor (you will need to add `import 'package:flutter_localizations/flutter_localizations.dart';` at the top of the file for `GlobalMaterialLocalizations`). (2) In the `testWidgets('EdgeInsetsDirectional mirrors under RTL', ...)` test, the assertions have `.left` and `.right` reversed for `EdgeInsetsDirectional.only(start: 4)`: under RTL, `start` maps to the right edge, not the left. Change the four `expect` lines from `expect(padding.resolve(TextDirection.rtl).left, 4); expect(padding.resolve(TextDirection.rtl).right, 0); expect(padding.resolve(TextDirection.ltr).left, 0); expect(padding.resolve(TextDirection.ltr).right, 4);` to `expect(padding.resolve(TextDirection.rtl).left, 0); expect(padding.resolve(TextDirection.rtl).right, 4); expect(padding.resolve(TextDirection.ltr).left, 4); expect(padding.resolve(TextDirection.ltr).right, 0);`. After both fixes, running `flutter test test/rtl_alignment_test.dart` must have zero failures.
- [x] **Fix wrong widget finder in map_picker_test.dart** — In test/widgets/map_picker_test.dart, the test `'reports a coordinate when tapped'` does `await tester.tap(find.byType(CustomPaint).first);` but `CustomPaint` is used internally by many Flutter framework widgets, so `.first` does not reliably hit MapPicker's own tappable surface (a `GestureDetector` with `onTapDown` that wraps the `CustomPaint`, defined in lib/widgets/map_picker.dart). Change that line to `await tester.tap(find.byType(GestureDetector).first);` — this targets the map's own gesture area, which is the first `GestureDetector` in the widget tree per lib/widgets/map_picker.dart's layout. Change nothing else in the file. After the fix, running `flutter test test/widgets/map_picker_test.dart` must have zero failures.
- [x] **Make CI actually gate on analyze and test results** — In .github/workflows/ci.yml, remove the trailing `|| true` from exactly these two lines (they currently mask every analyze/test failure as success, matching the pattern change on both, nothing else): change `run: flutter analyze --no-fatal-infos --no-fatal-warnings || true` to `run: flutter analyze --no-fatal-infos --no-fatal-warnings`, and change `run: flutter test --reporter expanded || true` to `run: flutter test --reporter expanded`. Do not change the `dart format` line or anything else in the file. The project currently has zero analyze errors and zero failing tests, so this change is safe and should not break CI.
- [x] **Create site/js/config.js with Supabase constants** — Create a new file `site/js/config.js` (the `site/` directory does not exist yet — create it) with exactly this content:
```js
export const SUPABASE_URL = "https://ojnhaqpiufgfxusokazb.supabase.co";
export const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qbmhhcXBpdWZnZnh1c29rYXpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg5MjI1NzMsImV4cCI6MjEwNDQ5ODU3M30.D9jYEHSYL45bpmo-7RkxdKz19u-qhRIJNoypSClg3tg";
```
Do not create any other file in this task.

- [BLOCKED] **Create site/js/supabase-client.js** — Create a new file `site/js/supabase-client.js` with exactly this content:
```js
import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/+esm";
import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./config.js";

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
```
Requires site/js/config.js to already exist (it does, from a prior task). Do not create any other file in this task.

- [BLOCKED] **Create site/js/auth.js** — Create a new file `site/js/auth.js` with exactly this content:
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
Do not create any other file in this task.

- [ ] **Create site/js/requests.js** — Create a new file `site/js/requests.js` with exactly this content:
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
Do not create any other file in this task.

- [ ] **Create site/js/offers.js** — Create a new file `site/js/offers.js` with exactly this content:
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
Do not create any other file in this task.

- [ ] **Create site/css/style.css** — Create a new file `site/css/style.css` with exactly this content:
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
Do not create any other file in this task.
