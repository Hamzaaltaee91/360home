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

- [x] **Create site/js/supabase-client.js** — Create a new file `site/js/supabase-client.js` with exactly this content:
```js
import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/+esm";
import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./config.js";

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
```
Requires site/js/config.js to already exist (it does, from a prior task). Do not create any other file in this task.

- [x] **Create site/js/auth.js** — Create a new file `site/js/auth.js` with exactly this content:
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

- [x] **Create site/js/requests.js** — Create a new file `site/js/requests.js` with exactly this content:
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

- [x] **Create site/js/offers.js** — Create a new file `site/js/offers.js` with exactly this content:
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

- [x] **Create site/css/style.css** — Create a new file `site/css/style.css` with exactly this content:
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
- [x] **Create site/index.html (landing/login/signup page)** — Create a new file `site/index.html` with exactly this content:
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
This file depends on site/js/auth.js and site/js/supabase-client.js which already exist from prior tasks. Do not create any other file in this task.

- [x] **Create site/dashboard.html (buyer dashboard page)** — Create a new file `site/dashboard.html` with exactly this content:
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
This file depends on site/js/auth.js and site/js/requests.js which already exist from prior tasks. Do not create any other file in this task.

- [x] **Create site/request-new.html (create-request form page)** — Create a new file `site/request-new.html` with exactly this content:
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
This file depends on site/js/auth.js and site/js/requests.js which already exist from prior tasks. Do not create any other file in this task.

- [x] **Create site/request.html (request detail + offers list page)** — Create a new file `site/request.html` with exactly this content:
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
This file depends on site/js/auth.js, site/js/requests.js, and site/js/offers.js which already exist from prior tasks. Do not create any other file in this task.

- [x] **Create site/offer.html (offer detail + respond page)** — Create a new file `site/offer.html` with exactly this content:
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
This file depends on site/js/auth.js and site/js/offers.js which already exist from prior tasks. Do not create any other file in this task.


## NOTE: web site tasks completed directly by supervisor (2026-09-12)

All `site/*` file-creation tasks above were completed directly by the human
supervisor (not by aider/deepseek) after diagnosing a real pilot bug:
`current_task()` in `auto_pilot.sh` reads only the single `- [ ] ` bullet
line from TODO.md and never passes any content after it (including fenced
code blocks) to aider. Tasks that needed exact multi-line file content
(JS/HTML/CSS files) arrived at the model as truncated, content-less
instructions, causing repeated blocked attempts and one silently
mislabeled "done" task (`site/js/config.js`, commit `0a22bfc`, which
actually made an unrelated — but legitimate — Dart refactor instead).
All 10 `site/` files now exist with the exact content from
`docs/superpowers/plans/2026-09-12-buyer-web-site.md` and were verified
(JS syntax check + live browser signup test against the real Supabase
project). See the corrected lesson in `CONVENTIONS.md` under "دروس
مستفادة تلقائياً" for the root-cause fix guidance going forward.

## 13. request-new.html Redesign — Purpose Field, Iraq Locations, Rental Period

Schema tasks below each require a NEW file under supabase/migrations/ — never edit an already-applied migration.

EVERY task in this section touches ONLY the file(s) it names. None of them concern the Flutter app in lib/ — that is a separate, unrelated codebase. Do not open, read, or modify anything under lib/ for any task in this section, even if it looks related or "out of sync." If a task seems to require a Flutter-side change to be "complete," it does not — stop at the one file named and mark the task done.

- [x] Add `purpose` column to `public.property_requests`: TEXT NOT NULL CHECK (purpose IN ('rent', 'buy')), no default going forward — but existing rows must be backfilled to 'rent' first in the same migration before the NOT NULL constraint is applied.
- [x] Create supabase/migrations/20260911000006_add_governorate_to_property_requests.sql adding a `governorate` column to `public.property_requests`: TEXT, storing one of Iraq's 18 governorates as an English slug (e.g. baghdad, basra, nineveh — not Arabic text); keep the existing `city` column untouched. Touch only this one new file — nothing under lib/, nothing under site/.
- [x] Create supabase/migrations/20260911000007_add_area_to_property_requests.sql adding an `area` column to `public.property_requests`: TEXT, nullable, holding the selected sub-area within a governorate or free text when the user picks "أخرى"; keep the existing `area_name` column untouched. Touch only this one new file — nothing under lib/, nothing under site/.
- [x] Add `property_subtype` column to `public.property_requests`: TEXT, nullable, CHECK (category <> 'residential' OR property_subtype IN ('apartment', 'house', 'villa', 'duplex')).
- [x] Create supabase/migrations/20260911000008_add_rental_period_to_property_requests.sql adding a `rental_period` column to `public.property_requests`: TEXT, nullable, CHECK (rental_period IN ('daily', 'weekly', 'monthly', 'yearly')), no DB-level default — a buy request must have this NULL. Touch only this one new file — nothing under lib/, nothing under site/.
- [x] Update the property_requests schema section in CLAUDE.md to document the five new columns added by the migrations above, matching their exact names, types, and constraints. Touch only CLAUDE.md — nothing under lib/, nothing under site/, no SQL file.
- [x] Create site/js/iraq-locations.js exporting one plain object mapping each of Iraq's 18 governorate slugs to { label: Arabic name, areas: [{ value, label }, ...] }, 8 to 15 common areas per governorate, every list ending with { value: "other", label: "أخرى" }. Touch only this one new file — nothing under lib/, nothing else under site/.
- [x] Create site/js/numerals.js exporting one function toWesternDigits(str) that maps Arabic-Indic digits ٠-٩ to Western digits 0-9 and leaves every other character unchanged. Touch only this one new file — nothing under lib/, nothing else under site/.
- [x] In site/request-new.html, wrap the existing fields into five fieldset groups with legends: الفئة والغرض, الموقع, الميزانية, المواصفات, تفاصيل إضافية — keep every existing field id used by the submit handler exactly as-is. Touch only site/request-new.html — nothing under lib/, no other file.
- [x] In site/request-new.html, add a required purpose field (two options: rent/buy, Arabic labels إيجار/شراء) in the الفئة والغرض fieldset with neither option pre-selected, and block form submission until one is chosen. Touch only site/request-new.html — nothing under lib/, no other file.
- [x] In site/request-new.html, replace the free-text "المدينة" input with a "المحافظة" select populated from site/js/iraq-locations.js, and replace "المنطقة" with a dependent select that repopulates from the chosen governorate's areas list on change, revealing a free-text fallback input when "أخرى" is chosen. Touch only site/request-new.html — nothing under lib/, no other file.
- [x] In site/request-new.html, replace the separate "أقل سعر" and "أعلى سعر" inputs with a single "سقف الميزانية" number input; in the submit handler compute min_price as the entered value times 0.7 rounded to the nearest integer, and send both min_price and max_price to createRequest. Touch only site/request-new.html — nothing under lib/, no other file.
- [x] In site/request-new.html, add a "نوع العقار" select (شقة/بيت/فيلا/دوبلكس) shown only when الفئة = سكني and hidden and cleared to null otherwise, wired to the property_subtype field. Touch only site/request-new.html — nothing under lib/, no other file.
- [x] In site/request-new.html, add a "مدة الإيجار" select (يومي/أسبوعي/شهري/سنوي) defaulting to شهري, shown only when purpose = rent and hidden and cleared to null when purpose = buy. Touch only site/request-new.html — nothing under lib/, no other file.
- [x] In site/request-new.html, attach site/js/numerals.js's toWesternDigits to the input event of every numeric field (budget, bedrooms, bathrooms) so Arabic-Indic digits convert live as the user types. Touch only site/request-new.html — nothing under lib/, no other file.
- [x] In site/request-new.html, replace the single generic #error banner with a separate inline error message element under each field that can fail validation. Touch only site/request-new.html — nothing under lib/, no other file.
- [x] In site/dashboard.html, add tags for المحافظة, الغرض, and سقف الميزانية to the request card rendering loop alongside the existing category/city tags, using the same createElement/textContent pattern already used in that file — do not introduce innerHTML. Touch only site/dashboard.html — nothing under lib/, no other file.
- [x] In site/request.html, add rendering for purpose, governorate, area, property_subtype, and rental_period (when not null) to the request detail card, using the same safe DOM-building pattern already used in that file. Touch only site/request.html — nothing under lib/, no other file.
- [x]  أضف تعليق توضيحي بسيط في أعلى ملف README.md يقول "test comment"
- [x] - [ ] **Add second top-of-file comment to README.md** — Add a second HTML comment above the existing `<!-- test comment -->` line at the top of README.md, containing the text "test 2". Touch only README.md — nothing under lib/, no other file.
- [x] **Add contact-us link to site footer** — Add a `<footer>` section to `site/dashboard.html` with a link to a contact page (mirror the footer pattern already used in `site/index.html`). Touch only site/dashboard.html — nothing under lib/, no other file.
- [x] In site/request-new.html, fix the submit handler payload sent to createRequest: include `purpose` (currently missing entirely — the column is NOT NULL), rename the `rent_duration` key to `rental_period` (the actual column name — the wrong key currently makes every submission fail), and add `governorate` (the city select's slug value) and `area` (the area select's slug value, or the free-text override when "other" is chosen) alongside the existing legacy city/area_name label fields. Touch only site/request-new.html — nothing under lib/, no other file.
- [x] In site/request-new.html, change the "عنوان الطلب" label to "عنوان مختصر للطلب" and add a placeholder example (e.g. "مثلاً: شقة 3 غرف قريبة من الجامعة") to distinguish it clearly from the location fields. Touch only site/request-new.html — nothing under lib/, no other file.
- [x] In site/request-new.html, change the "سقف الميزانية" label to clarify the currency and expected format (e.g. "سقف الميزانية (دينار عراقي — الرقم الكامل)") with a placeholder example like "500000", and strip any non-digit character from the max-price input as the user types, alongside the existing Arabic-numeral conversion. Touch only site/request-new.html — nothing under lib/, no other file.
- [x] In site/request-new.html, replace the free-text "عدد غرف النوم" and "عدد الحمامات" inputs with `<select>` dropdowns offering options 1 through 5, defaulting to 2 for bedrooms and 1 for bathrooms; keep the same element ids so the submit handler needs no other change. Touch only site/request-new.html — nothing under lib/, no other file.
- [x] In site/css/style.css, exclude checkbox inputs from the generic `.form-field input` width/padding/border rule, and style the label wrapping the furnished checkbox as a flex row with a small gap so the checkbox sits directly next to "مفروش". Touch only site/css/style.css — nothing under lib/, no other file.
- [BLOCKED] In site/js/auth.js, add an exported async function signUpRealtor(...) — WRONGLY MARKED DONE BY PILOT, NO CODE WAS WRITTEN. aider self-refused per CONVENTIONS.md §5 ("قبول حقل دور من جهة العميل ممنوع") and left a NEEDS CLARIFICATION note in PROGRESS.md instead of implementing, but the task still got marked [x]. This task's design is wrong: it asked the client to set role:"realtor" and insert directly into public.users/public.realtors, which is a client-controlled role assignment — a hard security red line. Needs human redesign (likely: signup always creates role='buyer'; becoming a realtor goes through the existing verifications table + admin approval flow, matching CLAUDE.md's documented Realtor Verification Service, with the actual role change done server-side by an admin action, never by the signing-up client). Do not retry as originally worded.
- [x] In site/js/offers.js, add two exported async functions: createOffer(fields) that gets the current user via supabase.auth.getUser() and inserts { ...fields, realtor_id: user.id } into the realtor_offers table (select().single(), throw on error, matching the pattern already used by createRequest in site/js/requests.js), and listMyOffers() that selects "*" from realtor_offers filtered to the current user's realtor_id and ordered by created_at descending. Touch only site/js/offers.js — nothing under lib/, no other file.
- [x] In site/js/requests.js, add an exported async function listActiveRequestsForRealtor() that selects "*" from property_requests where status equals "active", ordered by created_at descending, following the same query/error-handling pattern as the existing listMyRequests function in this file. Touch only site/js/requests.js — nothing under lib/, no other file.
- [x] In site/auth.html, after a successful sign-in or sign-up, query the current user's role with `supabase.from("users").select("role").eq("auth_id", (await supabase.auth.getUser()).data.user.id).single()` and redirect to realtor-dashboard.html when the role is "realtor", admin-realtors.html when it is "admin", otherwise keep redirecting to dashboard.html exactly as today. Do not add any way to choose or set a role on this page — signup must keep calling signUpBuyer exactly as it does today, unchanged. Touch only site/auth.html — nothing under lib/, no other file.
- [x] Create site/realtor-dashboard.html as the realtor landing page, following the same structure, nav markup, and css/style.css classes already used in site/dashboard.html (site nav with brand link and a sign-out button calling signOut from site/js/auth.js, guarded by requireSession). Its main content is a simple welcome heading plus two prominent link buttons: "تصفح الطلبات" linking to realtor-requests.html, and "عروضي" linking to my-offers.html. Touch only this one new file — nothing under lib/, no other file.
- [x] Create site/realtor-requests.html listing active property requests for realtors to browse, reusing the same page structure, nav, and request-card rendering pattern (createElement/textContent, no innerHTML) already used in site/dashboard.html. Populate the list by calling listActiveRequestsForRealtor from site/js/requests.js. Each card shows the request's title, category, city/governorate, and budget, with a "قدم عرض" button that navigates to `create-offer.html?request_id=${id}`. Touch only this one new file — nothing under lib/, no other file.
- [x] Create site/create-offer.html with a form for a realtor to submit an offer against one property request. Read request_id from the URL query string; if missing, show an inline error and do not render the form. Fields: عنوان العقار (property_title, required text), وصف العقار (property_description, optional textarea), عنوان الموقع (property_address, required text), السعر المعروض (offered_price, required numeric, applying the same Arabic-numeral conversion pattern used in site/request-new.html), نوع العرض (lease_type: rent/sale select), مساحة العقار (area_sqft, optional numeric), عدد الغرف and عدد الحمامات (bedrooms/bathrooms, optional numeric), مفروش (furnished checkbox, styled the same fixed way already used in site/css/style.css), رسالة للمشتري (message_to_buyer, optional textarea). On submit, call createOffer from site/js/offers.js with request_id plus these fields, then redirect to my-offers.html. Follow the same fieldset/form-field markup and inline validation pattern already used in site/request-new.html. Touch only this one new file — nothing under lib/, no other file.
- [x] Create site/my-offers.html listing the signed-in realtor's own offers by calling listMyOffers from site/js/offers.js, reusing the same page structure, nav, and card-rendering pattern (createElement/textContent, no innerHTML) already used in site/dashboard.html. Each card shows property_title, offered_price, lease_type, and a status badge reflecting the offer's status column (pending/accepted/rejected/expired) plus buyer_response when not null. Touch only this one new file — nothing under lib/, no other file.
- [x] Create site/js/verification.js exporting two async functions: submitRealtorApplication(companyName, licenseNumber, licenseExpiry, documentUrl) that calls supabase.rpc("submit_realtor_application", { p_company_name: companyName, p_license_number: licenseNumber, p_license_expiry: licenseExpiry, p_document_url: documentUrl }) and throws on error, and getMyVerificationStatus() that calls supabase.rpc("get_my_verification_status") and returns the first row of the returned array (or null if empty). These are the only two calls in this file — no direct reads or writes to the users, realtors, or realtor_verifications tables, and no role field anywhere. Touch only this one new file — nothing under lib/, no other file.
- [x] Create site/become-realtor.html, a page for a signed-in buyer to apply to become a realtor. Guard with requireSession from site/js/auth.js and reuse the same nav/page-head/card/form-field markup and css/style.css classes already used in site/dashboard.html and site/request-new.html. On load, call getMyVerificationStatus from site/js/verification.js: if it returns a row, hide the form and show the request's status (pending/approved/rejected, with rejection_reason when rejected) instead. Otherwise show a form with fields اسم الشركة (company name, required text), رقم الرخصة (license number, required text), تاريخ انتهاء الرخصة (license expiry, required date), and رابط مستند الرخصة (document URL, required text/url) with a short helper note that this is a link to the license document for now. On submit, call submitRealtorApplication from site/js/verification.js and then re-render the status view. Touch only this one new file — nothing under lib/, no other file.
- [x] In site/dashboard.html, add a single nav link "سجل كوسيط" pointing to become-realtor.html, placed next to the existing "طلباتي" link in the nav-links list. Change nothing else in the file. Touch only site/dashboard.html — nothing under lib/, no other file.
- [x] Create site/js/admin.js exporting three async functions: listPendingRealtorApplications() calling supabase.rpc("list_pending_realtor_applications") and returning the resulting array, approveRealtorApplication(verificationId) calling supabase.rpc("approve_realtor_application", { p_verification_id: verificationId }), and rejectRealtorApplication(verificationId, reason) calling supabase.rpc("reject_realtor_application", { p_verification_id: verificationId, p_reason: reason }). Each throws on error. These three RPC calls are the only content of this file — no direct reads or writes to the users, realtors, or realtor_verifications tables, and no role field anywhere; all of that logic lives server-side in the RPC functions already. Touch only this one new file — nothing under lib/, no other file.
- [x] Create site/admin-realtors.html, an admin page listing pending realtor applications. Guard with requireSession from site/js/auth.js, reuse the same nav/page-head/card markup and css/style.css classes already used in site/dashboard.html. On load, call listPendingRealtorApplications from site/js/admin.js and render one card per application (createElement/textContent, no innerHTML) showing full_name, email, company_name, license_number, license_expiry, and a link to document_url, with two buttons: "قبول" calling approveRealtorApplication(verification_id) and "رفض" calling rejectRealtorApplication(verification_id, reason) after prompting for a rejection reason with a plain `prompt()` call. After either action succeeds, remove that card from the list (or reload the list). This page only ever calls the two functions from site/js/admin.js — it never reads or writes the users, realtors, or realtor_verifications tables directly, and never references a role field. Touch only this one new file — nothing under lib/, no other file.
- [x] Create site/contact.html, a simple contact page matching the same page structure, nav, and css/style.css classes already used in site/index.html (site nav with brand link, footer). Body content: a heading "اتصل بنا", a short paragraph inviting the visitor to reach out, and a mailto link to support@dabberli.com. This single new file resolves the dead "اتصل بنا" links already present in several pages' footers, which currently 404. Touch only this one new file — nothing under lib/, no other file.
- [x] Create site/js/notifications.js exporting three async functions: listMyNotifications() selecting "*" from the notifications table for the current signed-in user (via supabase.auth.getUser()), ordered by created_at descending; unreadCount() returning the count of that user's rows where is_read is false (use { count: "exact", head: true } with the same filters); and markAsRead(id) updating is_read to true on the notification row matching that id. Follow the same query/error-handling pattern already used in site/js/offers.js. Touch only this one new file — nothing under lib/, no other file.
- [x] Create site/notifications.html listing the signed-in user's notifications by calling listMyNotifications from site/js/notifications.js, reusing the same page structure, nav, and card-rendering pattern (createElement/textContent, no innerHTML) already used in site/dashboard.html. Each card shows title, message, and created_at, visually distinguished (e.g. an extra CSS class) when is_read is false. Clicking a card calls markAsRead(id) from site/js/notifications.js and then removes the unread styling from that card. Touch only this one new file — nothing under lib/, no other file.
- [x] In site/dashboard.html, add a nav link "الإشعارات" pointing to notifications.html, placed next to the existing "طلباتي" link in the nav-links list. On page load, call unreadCount from site/js/notifications.js and, when it is greater than zero, append the count in parentheses to that link's text (e.g. "الإشعارات (3)"). Change nothing else in the file. Touch only site/dashboard.html — nothing under lib/, no other file.
- [x] In site/realtor-dashboard.html, add a nav link "الإشعارات" pointing to notifications.html, placed next to the existing "تصفح الطلبات" link in the nav-links list. On page load, call unreadCount from site/js/notifications.js and, when it is greater than zero, append the count in parentheses to that link's text (e.g. "الإشعارات (3)"). Change nothing else in the file. Touch only site/realtor-dashboard.html — nothing under lib/, no other file.
- [x] In site/js/verification.js, add an exported async function uploadLicenseDocument(userId, file) that uploads the given File object to Supabase Storage bucket "dabberli" at path `realtor-documents/${userId}/${file.name}` using supabase.storage.from("dabberli").upload(...), then returns the public URL via getPublicUrl on that same path, following the same bucket name and path-prefix convention already used in lib/services/supabase_service.dart's uploadPropertyPhoto. Throw on upload error. Touch only site/js/verification.js — nothing under lib/, no other file.
- [x] In site/become-realtor.html, replace the "رابط مستند الرخصة" text/url input with a file input (input type="file", accept="application/pdf,image/*") plus its label "مستند الرخصة", removing the helper note about pasting a link. On submit, first get the current user's id via supabase.auth.getUser() (import supabase from ./js/supabase-client.js), call uploadLicenseDocument(userId, file) from site/js/verification.js to get a document URL, then pass that URL into submitRealtorApplication exactly as before. Show the existing document-url field's validation error under the new file input instead if no file is chosen. Touch only site/become-realtor.html — nothing under lib/, no other file.
- [x] In site/realtor-requests.html, add filter controls above the request list: a "الفئة" select (الكل/سكني/تجاري/أرض matching the category values already used elsewhere), a "المحافظة" select populated from the default export of site/js/iraq-locations.js (with a leading "الكل" option), and a "الحد الأقصى للميزانية" number input. Fetch the full list from listActiveRequestsForRealtor once as today, keep it in a variable, and re-render the visible cards by filtering that in-memory array (by category, governorate, and max_price <= the entered budget when provided) every time any filter control changes, without re-fetching. Touch only site/realtor-requests.html — nothing under lib/, no other file.
- [x] Create lib/utils/iraq_locations.dart exporting a top-level `const Map<String, Map<String, dynamic>> iraqLocations` mapping each of Iraq's 18 governorate slugs (the same slugs already used in site/js/iraq-locations.js: baghdad, basra, nineveh, erbil, sulaymaniyah, duhok, kirkuk, anbar, babil, karbala, najaf, diyala, wasit, maysan, dhi_qar, muthanna, qadisiyyah, saladin) to a map with a `label` (the Arabic governorate name) and an `areas` list of maps each with `value` and `label`, mirroring the same areas already listed per governorate in site/js/iraq-locations.js, every areas list ending with {"value": "other", "label": "أخرى"}. Pure Dart only, no Flutter imports, no new packages. Touch only this one new file — nothing under site/, no other file.
- [x] In lib/services/supabase_service.dart, add five new optional named parameters to createPropertyRequest — purpose (String?), governorate (String?), area (String?), propertySubtype (String?), rentalPeriod (String?) — and include them (as purpose, governorate, area, property_subtype, rental_period) in the map passed to the property_requests insert only when non-null, leaving every existing parameter and existing call sites unchanged. Touch only lib/services/supabase_service.dart — nothing under site/, no other file.
- [x] In lib/screens/buyer/create_request_screen.dart, add to the existing form: a required "الغرض" choice between إيجار (rent) and شراء (buy); a "المحافظة" dropdown populated from lib/utils/iraq_locations.dart with a dependent "المنطقة" dropdown that repopulates from the selected governorate's areas (revealing a free-text field when "أخرى" is chosen), replacing reliance on the free-text city field for this new data; when الفئة is سكني (residential), a "نوع العقار" dropdown (شقة/بيت/فيلا/دوبلكس); when الغرض is إيجار, a "مدة الإيجار" dropdown (يومي/أسبوعي/شهري/سنوي). Pass all of these through to the existing call to createPropertyRequest using its new purpose/governorate/area/propertySubtype/rentalPeriod parameters. Keep every existing field (title, description, min/max price, bedrooms, bathrooms, location picker, photos, urgent flag) exactly as it is today. Touch only lib/screens/buyer/create_request_screen.dart — nothing under site/, no other file.
- [x] In site/js/offers.js, add an exported async function uploadOfferPhotos(offerId, files) that uploads each File in the given FileList/array to Supabase Storage bucket "dabberli" at path `offer-photos/${offerId}/${file.name}` (following the same bucket and path-prefix convention already used in lib/services/supabase_service.dart's uploadPropertyPhoto), collects each resulting public URL via getPublicUrl, then updates the realtor_offers row matching offerId to set photo_urls to that array of URLs. Throw on any upload or update error. Touch only site/js/offers.js — nothing under lib/, no other file.
- [x] In site/create-offer.html, add a "صور العقار" file input (input type="file", multiple, accept="image/*") to the "تفاصيل العقار" fieldset. On successful submit, after createOffer resolves with the new offer, if any files were chosen call uploadOfferPhotos(offer.id, files) from site/js/offers.js before redirecting to my-offers.html; if no files were chosen, skip that call and redirect as today. Touch only site/create-offer.html — nothing under lib/, no other file.
- [x] In site/offer.html, render a photo gallery when the offer's photo_urls array is non-empty: a row of `<img>` elements (createElement, no innerHTML) built from photo_urls, each with reasonable width/height styling consistent with the rest of the page, placed above the existing offer details. When photo_urls is empty or missing, render nothing extra. Touch only site/offer.html — nothing under lib/, no other file.
- [x] In site/auth.html, replace the hardcoded `window.location.href = "dashboard.html"` inside the `supabase.auth.getSession().then(...)` callback (the one that runs for an already-signed-in visitor) with a call to the existing redirectAfterAuth() function already defined later in the same script, so an already-signed-in realtor or admin lands on their own page instead of the buyer dashboard. If redirectAfterAuth is defined after this callback in the file, move the callback's execution after the function definition (or hoist the function) so it can be called; change nothing else in the file. Touch only site/auth.html — nothing under lib/, no other file.
- [x] In site/js/notifications.js, add an exported function subscribeToUnreadCount(callback) that gets the current user via supabase.auth.getUser(), opens a Supabase Realtime channel subscribed to postgres_changes (event: "*", schema: "public", table: "notifications", filter: `user_id=eq.${user.id}`), and on every change calls unreadCount() again and invokes callback with the new count; return the channel object so callers can unsubscribe later. Touch only site/js/notifications.js — nothing under lib/, no other file.
- [x] In site/dashboard.html, replace the one-time unreadCount() call with subscribeToUnreadCount from site/js/notifications.js, updating the "الإشعارات" link text the same way as today (with the count in parentheses when greater than zero, plain "الإشعارات" when zero) every time the callback fires. Touch only site/dashboard.html — nothing under lib/, no other file.
- [x] In site/realtor-dashboard.html, replace the one-time unreadCount() call with subscribeToUnreadCount from site/js/notifications.js, updating the "الإشعارات" link text the same way as today (with the count in parentheses when greater than zero, plain "الإشعارات" when zero) every time the callback fires. Touch only site/realtor-dashboard.html — nothing under lib/, no other file.
- [x] In site/js/requests.js, add two exported async functions: updateRequest(id, fields) that updates the property_requests row matching id with the given fields object (select().single(), throw on error, same pattern as createRequest), and deleteRequest(id) that deletes the property_requests row matching id (throw on error). Touch only site/js/requests.js — nothing under lib/, no other file.
- [x] (written by hand, pilot blocked twice on size gate — form matches request-new.html at 365 lines) Create site/edit-request.html, a page for a signed-in buyer to edit one of their own property requests. Guard with requireSession from site/js/auth.js, reuse the same nav/page-head/form-field markup and css/style.css classes already used in site/request-new.html, including the same فئة/عنوان/وصف/المحافظة+المنطقة cascading dropdowns from site/js/iraq-locations.js/نوع العقار/مدة الإيجار/الحد الأدنى والأقصى للسعر/غرف/حمامات fields and the same Arabic-numeral conversion pattern for numeric inputs. Read id from the URL query string; on load call getRequest(id) from site/js/requests.js and prefill every field with the returned values. On submit, call updateRequest(id, fields) from site/js/requests.js with the edited values, then redirect to request.html?id=<id>. Touch only this one new file — nothing under lib/, no other file.
- [x] In site/request.html, add two buttons next to the existing "→ رجوع لطلباتي" link: "تعديل الطلب" linking to `edit-request.html?id=${requestId}`, and "حذف الطلب" that calls window.confirm with a short Arabic confirmation message, and if confirmed calls deleteRequest(requestId) from site/js/requests.js then redirects to dashboard.html. Touch only site/request.html — nothing under lib/, no other file.
- [x] In lib/services/supabase_service.dart, add five new optional named parameters to updatePropertyRequest — purpose (String?), governorate (String?), area (String?), propertySubtype (String?), rentalPeriod (String?) — and include them (as purpose, governorate, area, property_subtype, rental_period) in the map passed to the property_requests update only when non-null, leaving every existing parameter and existing call sites unchanged. Touch only lib/services/supabase_service.dart — nothing under site/, no other file.
- [x] (written by hand — pilot's 2 attempts failed CI because lib/models/models.dart's PropertyRequest had no purpose/governorate/area/propertySubtype/rentalPeriod fields to read back; added those to the model too) In lib/screens/buyer/edit_request_screen.dart, add the same fields already present in lib/screens/buyer/create_request_screen.dart that this screen is currently missing: الغرض (purpose) choice between إيجار/شراء, المحافظة/المنطقة cascading dropdowns from lib/utils/iraq_locations.dart (replacing reliance on the free-text city field for this data), a نوع العقار dropdown shown only when الفئة is سكني, and a مدة الإيجار dropdown shown only when الغرض is إيجار, prefilled from the request being edited. Pass all of these through to the existing call to updatePropertyRequest using its purpose/governorate/area/propertySubtype/rentalPeriod parameters. Keep every existing field on this screen exactly as it is today. Touch only lib/screens/buyer/edit_request_screen.dart — nothing under site/, no other file.
- [x] (written by hand — same model gap as edit_request_screen.dart, now fixed) In lib/screens/realtor/browse_requests_screen.dart, add a purpose tag (إيجار/شراء) and a governorate tag next to the existing city tag on each request card, and add "الغرض" and "المحافظة" filter dropdowns above the list (المحافظة populated from lib/utils/iraq_locations.dart) that filter the already-fetched in-memory list of requests, matching the same filtering approach already used in site/realtor-requests.html. Keep every existing field, tag, and filter on this screen exactly as it is today. Touch only lib/screens/realtor/browse_requests_screen.dart — nothing under site/, no other file.
- [x] Create site/js/reviews.js exporting three async functions: submitReview(offerId, rating, comment) calling supabase.rpc("submit_realtor_review", { p_offer_id: offerId, p_rating: rating, p_comment: comment }) and throwing on error; listRealtorReviews(realtorId) calling supabase.rpc("list_realtor_reviews", { p_realtor_id: realtorId }) and returning the resulting array; and getMyReviewForOffer(offerId) calling supabase.rpc("get_my_review_for_offer", { p_offer_id: offerId }) and returning the first row of the returned array (or null if empty). Follow the same query/error-handling pattern already used in site/js/offers.js. Touch only this one new file — nothing under lib/, no other file.
- [x] In site/offer.html, when the loaded offer's status is "accepted" and the signed-in user is the buyer viewing it, render a review section below the existing offer details: a 1-5 star rating control (five buttons or a select, no external library) and a comment textarea, prefilled from getMyReviewForOffer(offerId) from site/js/reviews.js if a review already exists, with a submit button that calls submitReview(offerId, rating, comment) from site/js/reviews.js and shows a short confirmation message on success. When the offer's status is not "accepted", render nothing extra. Touch only site/offer.html — nothing under lib/, no other file.
- [x] In lib/services/supabase_service.dart, add three new methods mirroring the existing RPC-wrapper pattern already used for verifications: submitReview({required String offerId, required int rating, String? comment}) calling the "submit_realtor_review" RPC with p_offer_id/p_rating/p_comment; listRealtorReviews(String realtorId) calling the "list_realtor_reviews" RPC with p_realtor_id and returning the list of rows; and getMyReviewForOffer(String offerId) calling the "get_my_review_for_offer" RPC with p_offer_id and returning the first row as a Map, or null if the result is empty. These three methods only ever call those three RPCs — no direct reads or writes to any table. Touch only lib/services/supabase_service.dart — nothing under site/, no other file.
- [x] In lib/screens/buyer/offer_details_screen.dart, when the loaded offer's status is "accepted", render a review section below the existing offer details: a 1-5 star rating control (e.g. a Row of five IconButtons toggling Icons.star/Icons.star_border) and a comment TextField, prefilled by calling getMyReviewForOffer from lib/services/supabase_service.dart if a review already exists, with a submit button that calls submitReview from lib/services/supabase_service.dart and shows a SnackBar confirmation on success. When the offer's status is not "accepted", render nothing extra. Touch only lib/screens/buyer/offer_details_screen.dart — nothing under site/, no other file.
- [x] Create site/js/messages.js exporting five async functions, following the same query/error-handling pattern already used in site/js/notifications.js: sendMessage(offerId, body) calling supabase.rpc("send_message", { p_offer_id: offerId, p_body: body }) and throwing on error; listMessages(offerId) calling supabase.rpc("list_messages", { p_offer_id: offerId }) and returning the resulting array; markMessagesRead(offerId) calling supabase.rpc("mark_messages_read", { p_offer_id: offerId }); unreadMessageCount() calling supabase.rpc("unread_message_count") and returning the numeric result (or 0 if null); and subscribeToMessages(offerId, callback) that opens a Supabase Realtime channel subscribed to postgres_changes (event: "INSERT", schema: "public", table: "messages", filter: `offer_id=eq.${offerId}`) and calls callback with the new row on every insert, returning the channel object so callers can unsubscribe. Touch only this one new file — nothing under lib/, no other file.
- [x] Create site/messages.html, a chat page for one offer's conversation between its buyer and realtor. Guard with requireSession from site/js/auth.js, reuse the same nav/page-head/css/style.css classes already used in site/dashboard.html. Read offer_id from the URL query string. On load: call listMessages(offerId) from site/js/messages.js and render each message as a simple bubble (createElement/textContent, no innerHTML), aligned to one side when sender_id equals the current signed-in user's id (via supabase.auth.getUser()) and the other side otherwise, each showing body and a short time label from created_at; then call markMessagesRead(offerId) from site/js/messages.js. Below the message list, a text input and a "إرسال" send button that calls sendMessage(offerId, body) from site/js/messages.js, clears the input, and appends the new message bubble on success. Touch only this one new file — nothing under lib/, no other file.
- [x] In site/offer.html, add a "الرسائل" link/button near the existing offer details, navigating to `messages.html?offer_id=${offerId}`. Change nothing else in the file. Touch only site/offer.html — nothing under lib/, no other file.
- [x] In site/my-offers.html, add a "الرسائل" link/button to each offer card, navigating to `messages.html?offer_id=${o.id}` (using each offer's id from the existing listMyOffers() data already rendered on this page). Change nothing else in the file. Touch only site/my-offers.html — nothing under lib/, no other file.
- [x] In lib/services/supabase_service.dart, add four new methods mirroring the existing RPC-wrapper pattern already used for reviews: sendMessage({required String offerId, required String body}) calling the "send_message" RPC with p_offer_id/p_body; listMessages(String offerId) calling the "list_messages" RPC with p_offer_id and returning the list of rows; markMessagesRead(String offerId) calling the "mark_messages_read" RPC with p_offer_id; and unreadMessageCount() calling the "unread_message_count" RPC and returning it as an int (0 if null). These four methods only ever call those four RPCs — no direct reads or writes to any table. Touch only lib/services/supabase_service.dart — nothing under site/, no other file.
- [x] Create lib/screens/messages_screen.dart, a chat screen for one offer's conversation between its buyer and realtor, mirroring the structure/size of lib/screens/notifications_screen.dart. Class MessagesScreen extends StatefulWidget with a required `offerId` (String) constructor parameter. On init: call SupabaseService().listMessages(offerId), render each as a ListTile-style bubble in a ListView, aligned/colored differently when its sender_id equals SupabaseService().getCurrentUserId() than otherwise, each showing body and a short formatted time from created_at; then call SupabaseService().markMessagesRead(offerId). Below the list, a TextField plus a send IconButton that calls SupabaseService().sendMessage(offerId: offerId, body: text), clears the field, and appends the new bubble on success. No realtime subscription needed for this first version. Touch only this one new file — nothing under site/, no other file.
- [x] In lib/routes/app_routes.dart, add a new route for the messages screen: a `static const String messages = '/messages/:offerId';` constant on RouteNames (placed near the existing offerDetails constant), an import for lib/screens/messages_screen.dart, and a GoRoute entry (placed near the existing offerDetails GoRoute) whose builder reads `state.pathParameters['offerId']!` and returns `MessagesScreen(offerId: offerId)`. Change nothing else in the file. Touch only lib/routes/app_routes.dart — nothing under site/, no other file.
- [x] In lib/screens/buyer/offer_details_screen.dart, add a "الرسائل" button near the existing offer details that navigates to `context.push('/messages/${widget.offerId}')` (import package:go_router/go_router.dart if not already imported). Change nothing else in the file. Touch only lib/screens/buyer/offer_details_screen.dart — nothing under site/, no other file.
- [x] In lib/screens/realtor/my_offers_screen.dart, add a "الرسائل" button to each offer card that navigates to `context.push('/messages/${offer.id}')` (using each offer's id from the already-loaded offers list on this screen; import package:go_router/go_router.dart if not already imported). Change nothing else in the file. Touch only lib/screens/realtor/my_offers_screen.dart — nothing under site/, no other file.
- [x] In lib/services/supabase_service.dart, add an exported method Future<void> deleteAccount() that calls `_client.functions.invoke('delete-account')` inside the existing `_guard` wrapper (same pattern as other functions.invoke calls in this file), throwing on error. Touch only lib/services/supabase_service.dart — nothing under site/, no other file.
- [x] In lib/services/supabase_service.dart, add four new methods mirroring the existing RPC-wrapper pattern already used for reviews: reportContent({String? reportedUserId, String? messageId, required String reason, String? details}) calling the "report_content" RPC with p_reported_user_id/p_message_id/p_reason/p_details; blockUser(String userId) calling the "block_user" RPC with p_user_id; unblockUser(String userId) calling the "unblock_user" RPC with p_user_id; and listBlockedUsers() calling the "list_blocked_users" RPC and returning the list of rows. These four methods only ever call those four RPCs — no direct reads or writes to any table. Touch only lib/services/supabase_service.dart — nothing under site/, no other file.
- [x] In lib/screens/profile/profile_screen.dart, add a "حذف الحساب" (delete account) option below the existing sign-out action, styled to stand out as destructive (e.g. red text/icon). Tapping it opens a confirmation AlertDialog explaining this permanently deletes the account and all its data and cannot be undone, with "إلغاء" and a destructive "حذف نهائياً" button. On confirm, call deleteAccount() from lib/services/supabase_service.dart; on success navigate to '/login' the same way _signOut already does; on failure show a SnackBar with the error message and keep the user on this screen. Touch only lib/screens/profile/profile_screen.dart — nothing under lib/services/, no other file.
- [x] In lib/screens/messages_screen.dart, add a PopupMenuButton to the AppBar's actions with two items: "الإبلاغ عن المستخدم" and "حظر المستخدم". Compute the other party's user id from the currently loaded messages list: the first message's sender_id if it differs from SupabaseService().getCurrentUserId(), otherwise its recipient_id; disable both menu items (or hide the PopupMenuButton) when the message list is empty and this id cannot be determined yet. "الإبلاغ عن المستخدم" opens an AlertDialog with a required reason TextField and an optional details TextField; on confirm, call SupabaseService().reportContent(reportedUserId: thatUserId, reason: reason, details: details) and show a confirmation SnackBar. "حظر المستخدم" opens a confirmation AlertDialog, and on confirm calls SupabaseService().blockUser(thatUserId) then pops this screen. Keep the existing message list/send functionality exactly as it is. Touch only lib/screens/messages_screen.dart — nothing under lib/services/, no other file.
- [x] In lib/routes/app_routes.dart, register the three missing admin routes. Add imports for lib/screens/admin/admin_dashboard_screen.dart, lib/screens/admin/verify_realtors_screen.dart, and lib/screens/admin/manage_users_screen.dart. Add two new path constants to RouteNames near the existing `adminDashboard` constant: `static const String adminVerifications = '/admin/verifications';` and `static const String adminUsers = '/admin/users';` (matching VerifyRealtorsScreen.routeName and ManageUsersScreen.routeName exactly). Add three GoRoute entries near the end of the routes list: one for RouteNames.adminDashboard returning `const AdminDashboardScreen()`, one for RouteNames.adminVerifications returning `const VerifyRealtorsScreen()`, and one for RouteNames.adminUsers returning `const ManageUsersScreen()`. Currently RouteNames.adminDashboard exists as a constant but has no matching GoRoute at all, so any admin who signs in is redirected to a path that matches nothing and lands on the 404 screen — this fixes that. Change nothing else in the file. Touch only lib/routes/app_routes.dart — nothing under lib/screens/, no other file.
- [x] In lib/screens/admin/admin_dashboard_screen.dart, add two navigation entries below the existing stats content (e.g. two ListTiles or Cards in a Column, or two items in the existing layout): "توثيق الوسطاء" navigating to '/admin/verifications' (matching VerifyRealtorsScreen.routeName) and "إدارة المستخدمين" navigating to '/admin/users' (matching ManageUsersScreen.routeName), using context.push from package:go_router/go_router.dart (import it if not already imported). These two screens exist in the codebase but have no way to reach them from this dashboard today. Keep all existing stats/refresh functionality exactly as it is. Touch only lib/screens/admin/admin_dashboard_screen.dart — nothing under lib/routes/, no other file.
- [x] In lib/screens/auth/signup_screen.dart, remove the role-selection SegmentedButton (the one with "مشتري"/"وسيط" segments) and the `_selectedRole` state variable entirely; change the call to `supabase.signUp(...)` to pass `role: 'buyer'` as a hardcoded literal instead of `role: _selectedRole`; change the subtitle text "اختر دورك في المنصة" to something appropriate for a buyer-only signup (e.g. "أنشئ حسابك وابدأ بنشر طلبك"). Every account created here must always be a buyer — becoming a realtor happens later through a separate verification flow, not at signup. Keep every other field on this screen exactly as it is today. Touch only lib/screens/auth/signup_screen.dart — nothing under lib/services/, no other file.
- [x] In lib/routes/app_routes.dart, register the missing verification route: add `static const String verification = '/verification';` to RouteNames (placed near the existing realtor routes), an import for lib/screens/realtor/verification_screen.dart, and a GoRoute entry (placed near the existing realtor routes) returning `const VerificationScreen()`. VerificationScreen exists in the codebase but has no route at all today, so it can never be reached. Change nothing else in the file. Touch only lib/routes/app_routes.dart — nothing under lib/screens/, no other file.
- [x] In lib/screens/profile/profile_screen.dart, add a "سجّل كوسيط" navigation entry (e.g. a ListTile or button, placed above the existing sign-out action) that navigates to '/verification' using context.push (import package:go_router/go_router.dart if not already imported), shown only when the loaded user's role (from the existing `_userFuture`/AppUser data already used on this screen) is 'buyer' — hidden entirely for 'realtor' or 'admin' users. This is the only way for a buyer to reach the realtor-application screen from the app today. Keep every existing field and action on this screen exactly as it is. Touch only lib/screens/profile/profile_screen.dart — nothing under lib/routes/, no other file.
- [x] Create site/js/safety.js exporting six async functions, following the same query/error-handling pattern already used in site/js/reviews.js: reportContent(reportedUserId, messageId, reason, details) calling supabase.rpc("report_content", { p_reported_user_id: reportedUserId, p_message_id: messageId, p_reason: reason, p_details: details }) and throwing on error; blockUser(userId) calling supabase.rpc("block_user", { p_user_id: userId }); unblockUser(userId) calling supabase.rpc("unblock_user", { p_user_id: userId }); listBlockedUsers() calling supabase.rpc("list_blocked_users") and returning the resulting array; listOpenReports() calling supabase.rpc("list_open_reports") and returning the resulting array; and resolveReport(reportId, status) calling supabase.rpc("resolve_report", { p_report_id: reportId, p_status: status }). Touch only this one new file — nothing under lib/, no other file.
- [x] In site/messages.html, add two buttons near the existing "→" back link or page heading: "الإبلاغ عن المستخدم" and "حظر المستخدم". Compute the other party's user id the same way the message bubbles already determine alignment (the loaded messages' sender_id/recipient_id relative to the current signed-in user's id); hide both buttons when no messages are loaded yet and this id cannot be determined. "الإبلاغ عن المستخدم" prompts for a reason via a plain `prompt()` call (cancel if empty) and calls reportContent(otherUserId, null, reason, null) from site/js/safety.js, then shows a confirmation via a simple on-page message. "حظر المستخدم" calls window.confirm for confirmation, then calls blockUser(otherUserId) from site/js/safety.js and redirects to dashboard.html on success. Keep the existing message list/send functionality exactly as it is. Touch only site/messages.html — nothing under lib/, no other file.
- [x] Create site/admin-reports.html, an admin page listing open content reports. Guard with requireSession from site/js/auth.js, reuse the same nav/page-head/card markup and css/style.css classes already used in site/admin-realtors.html. On load, call listOpenReports from site/js/safety.js and render one card per report (createElement/textContent, no innerHTML) showing reporter_name, reported_user_name, message_body (when present), reason, details, and created_at, with two buttons: "تمت المراجعة" calling resolveReport(report_id, "reviewed") and "رفض البلاغ" calling resolveReport(report_id, "dismissed") from site/js/safety.js. After either action succeeds, remove that card from the list. This page only ever calls the two functions from site/js/safety.js — it never reads or writes the reports table directly. Touch only this one new file — nothing under lib/, no other file.
- [x] In site/admin-realtors.html, add a "البلاغات" nav link pointing to admin-reports.html, placed next to the existing nav links. Change nothing else in the file. Touch only site/admin-realtors.html — nothing under lib/, no other file.
- [x] Create lib/screens/chats_list_screen.dart, a "chats" tab listing the current user's open conversations, mirroring the structure/size of lib/screens/messages_screen.dart. Class ChatsListScreen extends StatefulWidget (no constructor parameters). On init, call SupabaseService().getMyConversations(), which returns Future<List<Map<String, dynamic>>>, each map having keys: offer_id, other_party_id, other_party_name, property_title, last_message, last_message_at, unread_count. Render each as a ListTile in a ListView: title = other_party_name, subtitle = "$property_title — $last_message" (truncate last_message with an ellipsis if long), trailing = a small Badge or colored circle showing unread_count only when unread_count > 0, onTap navigating via context.push('/messages/${offer_id}') (import package:go_router/go_router.dart). Show a centered "لا توجد محادثات" message when the list is empty, and a CircularProgressIndicator while loading. Give the Scaffold an AppBar titled "الدردشات". Touch only this one new file — nothing under lib/routes/, no other file.
- [x] In lib/routes/app_routes.dart, register a new route for the chats list: add `static const String chats = '/chats';` to RouteNames (placed near the existing messages constant), an import for lib/screens/chats_list_screen.dart, and a GoRoute entry (placed near the existing messages GoRoute) returning `const ChatsListScreen()`. Change nothing else in the file. Touch only lib/routes/app_routes.dart — nothing under lib/screens/, no other file.
- [x] In lib/screens/buyer/buyer_home_screen.dart, make two changes to the existing bottomNavigationBar's BottomNavigationBar (currently 3 items: الرئيسية/العروض/الملف الشخصي, onTap handling index 1 → '/browse-offers' and index 2 → '/profile'): (1) insert a new BottomNavigationBarItem with icon Icons.chat_bubble_outline and label 'الدردشات' between the existing 'العروض' and 'الملف الشخصي' items, and update onTap so index 2 now navigates to context.go('/chats') and index 3 (was 2) navigates to context.go('/profile'); (2) wrap the existing 'العروض' item's icon in a Badge (isLabelVisible: true only when the count is greater than 0, label showing the count) sourced from calling SupabaseService().getBuyerStats() in initState and reading the int at key 'pending_offers' from the returned Map into a new int state field defaulting to 0, updated via setState when the future completes (wrap the getBuyerStats() call in a try/catch that leaves the field at 0 on error, so a stats failure never blocks the rest of the screen). Keep every other existing field, action, and item on this screen exactly as it is. Touch only lib/screens/buyer/buyer_home_screen.dart — nothing under lib/services/, no other file.
- [x] In lib/screens/realtor/realtor_home_screen.dart, insert a new BottomNavigationBarItem with icon Icons.chat_bubble_outline and label 'الدردشات' into the existing bottomNavigationBar's BottomNavigationBar (currently 3 items: الرئيسية/الطلبات/الملف الشخصي, onTap handling index 1 → '/browse-requests' and index 2 → '/profile'), placed between the existing 'الطلبات' and 'الملف الشخصي' items, and update onTap so index 2 now navigates to context.go('/chats') and index 3 (was 2) navigates to context.go('/profile'). Keep every other existing field and action on this screen exactly as it is. Touch only lib/screens/realtor/realtor_home_screen.dart — nothing under lib/routes/, no other file.
- [x] (written by hand — root cause identified during manual testing: every screen navigates to '/profile' via context.go, which replaces the navigation stack, so profile_screen.dart has no back stack and today renders no bottomNavigationBar at all, leaving the user stuck with no way off the screen) In lib/screens/profile/profile_screen.dart, add a bottomNavigationBar to the Scaffold, built from the already-loaded user's role (the same `_userFuture`/AppUser data this screen already uses — build it inside the FutureBuilder once the user has loaded, not before): when role == 'buyer', render a BottomNavigationBar with the same 4 items/order as lib/screens/buyer/buyer_home_screen.dart (الرئيسية/العروض/الدردشات/الملف الشخصي) with currentIndex: 3, and onTap navigating via context.go to '/buyer-home', '/browse-offers', '/chats', or nothing (already on '/profile') respectively; when role == 'realtor', render the same 4 items/order as lib/screens/realtor/realtor_home_screen.dart (الرئيسية/الطلبات/الدردشات/الملف الشخصي) with currentIndex: 3, and onTap navigating to '/realtor-home', '/browse-requests', '/chats', or nothing respectively; when role == 'admin', render no bottomNavigationBar (leave as null, matching today's behavior for that role only). Keep every existing field and action on this screen exactly as it is. Touch only lib/screens/profile/profile_screen.dart — nothing under lib/routes/, no other file.
- [x] In lib/services/supabase_service.dart, add three new methods following the existing `_guard`-wrapped query pattern already used in this file: Future<List<Map<String, dynamic>>> getListOptions(String listName) selecting code, label from the list_options table where list_name = listName and active = true, ordered by sort_order; Future<List<Map<String, dynamic>>> getGovernorates() selecting slug, label from the governorates table where active = true, ordered by sort_order; Future<List<Map<String, dynamic>>> getAreas(String governorateSlug) selecting value, label from the areas table where governorate_slug = governorateSlug and active = true, ordered by sort_order. These three tables already exist in the live database with public SELECT RLS policies — no migration needed. Touch only lib/services/supabase_service.dart — nothing under supabase/, no other file.
- [x] In lib/services/supabase_service.dart, add two admin-only methods for the list_options table (already exists, admin-write RLS policy already applied): Future<void> adminUpsertListOption({required String listName, required String code, required String label, int sortOrder = 0, bool active = true}) calling `.from('list_options').upsert({...})` with onConflict: 'list_name,code'; Future<void> adminDeleteListOption(String listName, String code) calling `.from('list_options').delete().eq('list_name', listName).eq('code', code)`. Wrap both in the existing `_guard` pattern. Touch only lib/services/supabase_service.dart — nothing under supabase/, no other file.
- [x] In lib/services/supabase_service.dart, add four admin-only methods for the governorates and areas tables (already exist, admin-write RLS policies already applied): Future<void> adminUpsertGovernorate({required String slug, required String label, int sortOrder = 0, bool active = true}) upserting into 'governorates'; Future<void> adminDeleteGovernorate(String slug) deleting from 'governorates' where slug matches; Future<void> adminUpsertArea({String? id, required String governorateSlug, required String value, required String label, int sortOrder = 0, bool active = true}) upserting into 'areas' (include 'id' in the payload only when id is non-null, so a null id lets the table's default gen_random_uuid() assign one on insert); Future<void> adminDeleteArea(String id) deleting from 'areas' where id matches. Wrap all four in the existing `_guard` pattern. Touch only lib/services/supabase_service.dart — nothing under supabase/, no other file.
- [x] In lib/services/supabase_service.dart, add two admin-only methods for the existing reports table (columns: id, reporter_id, reported_user_id, message_id, reason, details, status ('open'/'reviewed'/'dismissed'), created_at, reviewed_at, reviewed_by): Future<List<Map<String, dynamic>>> adminListReports({String? status}) selecting '*, reporter:users!reports_reporter_id_fkey(full_name), reported:users!reports_reported_user_id_fkey(full_name)' from 'reports', filtering by status when provided, ordered by created_at descending; Future<void> adminResolveReport({required String reportId, required String status}) (status is 'reviewed' or 'dismissed') updating 'reports' set status, reviewed_at to now, and reviewed_by to the current user id (from the existing getCurrentUserId() helper already in this file) where id matches. Wrap both in the existing `_guard` pattern. Touch only lib/services/supabase_service.dart — nothing under supabase/, no other file.
- [x] In lib/services/supabase_service.dart, add two admin-only methods for the property_requests table: Future<List<Map<String, dynamic>>> adminListPropertyRequests({String? statusFilter, String? searchText}) selecting '*, buyer:users!property_requests_buyer_id_fkey(full_name, email)' from 'property_requests', filtering by status when statusFilter is provided and by title ilike '%searchText%' when searchText is provided, ordered by created_at descending, limited to 100 rows; Future<void> adminSetPropertyRequestStatus({required String requestId, required String status}) updating 'property_requests' set status where id matches (status must be one of the existing CHECK constraint values: active/inactive/sold/rented). Wrap both in the existing `_guard` pattern. Touch only lib/services/supabase_service.dart — nothing under supabase/, no other file.
- [x] In lib/services/supabase_service.dart, add two admin-only methods for the realtor_offers table: Future<List<Map<String, dynamic>>> adminListRealtorOffers({String? statusFilter}) selecting '*, realtor:users!realtor_offers_realtor_id_fkey(full_name, email)' from 'realtor_offers', filtering by status when statusFilter is provided, ordered by created_at descending, limited to 100 rows; Future<void> adminDeleteRealtorOffer(String offerId) deleting from 'realtor_offers' where id matches. Wrap both in the existing `_guard` pattern. Touch only lib/services/supabase_service.dart — nothing under supabase/, no other file.
- [x] In lib/services/supabase_service.dart, add one admin-only method: Future<List<Map<String, dynamic>>> adminListRealtors({String? searchText}) selecting '*, user:users!realtors_user_id_fkey(full_name, email, phone, is_verified)' from 'realtors', filtering by company_name ilike '%searchText%' or license_number ilike '%searchText%' when searchText is provided, ordered by created_at descending. Wrap in the existing `_guard` pattern. Touch only lib/services/supabase_service.dart — nothing under supabase/, no other file.
- [x] In lib/services/supabase_service.dart, add one admin-only method: Future<List<Map<String, dynamic>>> adminGetAuditLogs({int limit = 100}) selecting '*, actor:users!audit_logs_actor_id_fkey(full_name)' from 'audit_logs', ordered by created_at descending, limited to `limit` rows. Wrap in the existing `_guard` pattern. Touch only lib/services/supabase_service.dart — nothing under supabase/, no other file.
- [x] Create lib/screens/admin/manage_lists_screen.dart, an admin screen for editing the four small dropdown lists stored in the list_options table (list_name values: 'category', 'purpose', 'rental_period', 'currency'). StatefulWidget ManageListsScreen (no constructor params), static const String routeName = '/admin/lists'. Use a DropdownButton or SegmentedButton to pick the active list_name (default 'category'), then load its rows via SupabaseService().getListOptions(listName) into a ListView, each row a ListTile showing label/code/sort_order with edit and delete IconButtons. Edit and a floating '+' add button open the same AlertDialog with TextFormFields for code, label, sort_order (int), and a Switch for active; on save call SupabaseService().adminUpsertListOption(...) with the currently selected list_name, then reload the list. Delete opens a confirm AlertDialog then calls SupabaseService().adminDeleteListOption(listName, code) and reloads. Show a loading spinner while fetching and an error state with a retry button on failure, following the same patterns already used in lib/screens/admin/manage_users_screen.dart. Touch only this one new file — nothing under lib/routes/, no other file.
- [x] Create lib/screens/admin/manage_governorate_areas_screen.dart, an admin screen listing and editing the areas of one governorate. StatefulWidget ManageGovernorateAreasScreen({required String governorateSlug, required String governorateLabel}) (both required constructor params). AppBar title = governorateLabel. Load areas via SupabaseService().adminListAreas(governorateSlug) into a ListView, each row a ListTile showing label/value/sort_order with edit and delete IconButtons. Edit and a floating '+' add button open an AlertDialog with TextFormFields for value, label, sort_order (int), and a Switch for active; on save call SupabaseService().adminUpsertArea(id: the row's existing 'id' when editing, otherwise null, governorateSlug: governorateSlug, value: ..., label: ..., sortOrder: ..., active: ...), then reload. Delete opens a confirm AlertDialog then calls SupabaseService().adminDeleteArea(id) and reloads. Show a loading spinner while fetching and an error state with retry, following the same patterns already used in lib/screens/admin/manage_lists_screen.dart. Touch only this one new file — nothing under lib/routes/, no other file.
- [x] Create lib/screens/admin/manage_locations_screen.dart, an admin screen listing governorates. StatefulWidget ManageLocationsScreen (no constructor params), static const String routeName = '/admin/locations'. Import lib/screens/admin/manage_governorate_areas_screen.dart (already exists). Load governorates via SupabaseService().adminListGovernorates() into a ListView, each row a ListTile showing label/slug/sort_order with edit and delete IconButtons, onTap navigating via Navigator.of(context).push(MaterialPageRoute(builder: (_) => ManageGovernorateAreasScreen(governorateSlug: row's slug, governorateLabel: row's label))) — the same Navigator.push pattern already used in lib/screens/profile/profile_screen.dart for EditProfileScreen. Edit and a floating '+' add button open an AlertDialog with TextFormFields for slug (read-only/disabled when editing an existing row, editable when adding), label, sort_order (int), and a Switch for active; on save call SupabaseService().adminUpsertGovernorate(slug: ..., label: ..., sortOrder: ..., active: ...), then reload. Delete opens a confirm AlertDialog then calls SupabaseService().adminDeleteGovernorate(slug) and reloads. Show a loading spinner while fetching and an error state with retry, following the same patterns already used in lib/screens/admin/manage_lists_screen.dart. Touch only this one new file — nothing under lib/routes/, no other file.
- [x] Create lib/screens/admin/reports_screen.dart, an admin screen for moderating user reports. StatefulWidget ReportsScreen (no constructor params), static const String routeName = '/admin/reports'. On init, call SupabaseService().adminListReports(status: 'open') and render each report as a Card showing the reporter's and reported user's full_name (from the joined data), reason, details, and created_at, with two buttons: 'تمت المراجعة' calling SupabaseService().adminResolveReport(reportId: id, status: 'reviewed') and 'رفض البلاغ' calling SupabaseService().adminResolveReport(reportId: id, status: 'dismissed'); after either action succeeds, remove that card from the list (no full reload needed). Show 'لا توجد بلاغات مفتوحة' when the list is empty, a loading spinner while fetching, and an error state with retry on failure, following the same patterns already used in lib/screens/admin/verify_realtors_screen.dart. Touch only this one new file — nothing under lib/routes/, no other file.
- [x] Create lib/screens/admin/manage_requests_screen.dart, an admin screen for browsing and moderating property requests. StatefulWidget ManageRequestsScreen (no constructor params), static const String routeName = '/admin/requests'. Include a search TextField (title search) and a status filter DropdownButton (all/active/inactive/sold/rented). On init and on filter change, call SupabaseService().adminListPropertyRequests(statusFilter: ..., searchText: ...) and render each row as a ListTile showing title, the joined buyer's full_name, status, and created_at, with a trailing PopupMenuButton offering 'تعطيل' (set status 'inactive') and 'تفعيل' (set status 'active'), each calling SupabaseService().adminSetPropertyRequestStatus(...) then reloading. Show a loading spinner while fetching and an empty/error state, following the same patterns already used in lib/screens/admin/manage_users_screen.dart. Touch only this one new file — nothing under lib/routes/, no other file.
- [x] Create lib/screens/admin/manage_offers_screen.dart, an admin screen for browsing and moderating realtor offers. StatefulWidget ManageOffersScreen (no constructor params), static const String routeName = '/admin/offers'. Include a status filter DropdownButton (all/pending/accepted/rejected/expired). On init and on filter change, call SupabaseService().adminListRealtorOffers(statusFilter: ...) and render each row as a ListTile showing property_title, the joined realtor's full_name, offered_price + currency, status, and created_at, with a trailing delete IconButton that opens a confirm AlertDialog then calls SupabaseService().adminDeleteRealtorOffer(id) and reloads. Show a loading spinner while fetching and an empty/error state, following the same patterns already used in lib/screens/admin/manage_users_screen.dart. Touch only this one new file — nothing under lib/routes/, no other file.
- [x] Create lib/screens/admin/realtors_directory_screen.dart, an admin screen listing all realtors. StatefulWidget RealtorsDirectoryScreen (no constructor params), static const String routeName = '/admin/realtors-directory'. Include a search TextField (company name / license number). On init and on search change, call SupabaseService().adminListRealtors(searchText: ...) and render each row as a Card/ListTile showing the joined user's full_name and email, company_name, license_number, license_expiry, average_rating, total_offers, and a verified badge/icon when the joined user's is_verified is true. Show a loading spinner while fetching and an empty/error state, following the same patterns already used in lib/screens/admin/manage_users_screen.dart. Touch only this one new file — nothing under lib/routes/, no other file.
- [x] Create lib/screens/admin/audit_log_screen.dart, an admin screen listing recent audit log entries. StatefulWidget AuditLogScreen (no constructor params), static const String routeName = '/admin/audit-log'. On init, call SupabaseService().adminGetAuditLogs() and render each entry as a ListTile: title = action, subtitle = 'entity_type: entity_id · actor full_name (from the joined data) · created_at formatted with intl DateFormat'. Show a loading spinner while fetching and an empty/error state with retry, following the same patterns already used in lib/screens/admin/manage_users_screen.dart. Touch only this one new file — nothing under lib/routes/, no other file.
- [x] In lib/routes/app_routes.dart, register 7 new admin routes for screens that already exist in the codebase but have no route: add imports for lib/screens/admin/manage_lists_screen.dart, lib/screens/admin/manage_locations_screen.dart, lib/screens/admin/reports_screen.dart, lib/screens/admin/manage_requests_screen.dart, lib/screens/admin/manage_offers_screen.dart, lib/screens/admin/realtors_directory_screen.dart, and lib/screens/admin/audit_log_screen.dart; add 7 matching path constants to RouteNames near the existing adminUsers constant (adminLists = '/admin/lists', adminLocations = '/admin/locations', adminReports = '/admin/reports', adminRequests = '/admin/requests', adminOffers = '/admin/offers', adminRealtorsDirectory = '/admin/realtors-directory', adminAuditLog = '/admin/audit-log', matching each screen's own routeName constant exactly); add 7 matching GoRoute entries near the existing admin routes. Change nothing else in the file. Touch only lib/routes/app_routes.dart — nothing under lib/screens/, no other file.
- [ ] In lib/screens/admin/admin_dashboard_screen.dart, add 7 new navigation entries below the existing 'توثيق الوسطاء'/'إدارة المستخدمين' cards (same ListTile/Card style already used there): 'القوائم المنسدلة' → context.push('/admin/lists'), 'المحافظات والمناطق' → context.push('/admin/locations'), 'البلاغات' → context.push('/admin/reports'), 'طلبات العقارات' → context.push('/admin/requests'), 'عروض الوسطاء' → context.push('/admin/offers'), 'دليل الوسطاء' → context.push('/admin/realtors-directory'), 'سجل النشاطات' → context.push('/admin/audit-log'). Keep all existing stats/refresh functionality and the two existing nav entries exactly as they are. Touch only lib/screens/admin/admin_dashboard_screen.dart — nothing under lib/routes/, no other file.
