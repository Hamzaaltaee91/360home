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
- [BLOCKED] Update the property_requests schema section in CLAUDE.md to document the five new columns added by the migrations above, matching their exact names, types, and constraints. Touch only CLAUDE.md — nothing under lib/, nothing under site/, no SQL file.
- [x] Create site/js/iraq-locations.js exporting one plain object mapping each of Iraq's 18 governorate slugs to { label: Arabic name, areas: [{ value, label }, ...] }, 8 to 15 common areas per governorate, every list ending with { value: "other", label: "أخرى" }. Touch only this one new file — nothing under lib/, nothing else under site/.
- [x] Create site/js/numerals.js exporting one function toWesternDigits(str) that maps Arabic-Indic digits ٠-٩ to Western digits 0-9 and leaves every other character unchanged. Touch only this one new file — nothing under lib/, nothing else under site/.
- [ ] In site/request-new.html, wrap the existing fields into five fieldset groups with legends: الفئة والغرض, الموقع, الميزانية, المواصفات, تفاصيل إضافية — keep every existing field id used by the submit handler exactly as-is. Touch only site/request-new.html — nothing under lib/, no other file.
- [ ] In site/request-new.html, add a required purpose field (two options: rent/buy, Arabic labels إيجار/شراء) in the الفئة والغرض fieldset with neither option pre-selected, and block form submission until one is chosen. Touch only site/request-new.html — nothing under lib/, no other file.
- [ ] In site/request-new.html, replace the free-text "المدينة" input with a "المحافظة" select populated from site/js/iraq-locations.js, and replace "المنطقة" with a dependent select that repopulates from the chosen governorate's areas list on change, revealing a free-text fallback input when "أخرى" is chosen. Touch only site/request-new.html — nothing under lib/, no other file.
- [ ] In site/request-new.html, replace the separate "أقل سعر" and "أعلى سعر" inputs with a single "سقف الميزانية" number input; in the submit handler compute min_price as the entered value times 0.7 rounded to the nearest integer, and send both min_price and max_price to createRequest. Touch only site/request-new.html — nothing under lib/, no other file.
- [ ] In site/request-new.html, add a "نوع العقار" select (شقة/بيت/فيلا/دوبلكس) shown only when الفئة = سكني and hidden and cleared to null otherwise, wired to the property_subtype field. Touch only site/request-new.html — nothing under lib/, no other file.
- [ ] In site/request-new.html, add a "مدة الإيجار" select (يومي/أسبوعي/شهري/سنوي) defaulting to شهري, shown only when purpose = rent and hidden and cleared to null when purpose = buy. Touch only site/request-new.html — nothing under lib/, no other file.
- [ ] In site/request-new.html, attach site/js/numerals.js's toWesternDigits to the input event of every numeric field (budget, bedrooms, bathrooms) so Arabic-Indic digits convert live as the user types. Touch only site/request-new.html — nothing under lib/, no other file.
- [ ] In site/request-new.html, replace the single generic #error banner with a separate inline error message element under each field that can fail validation. Touch only site/request-new.html — nothing under lib/, no other file.
- [ ] In site/dashboard.html, add tags for المحافظة, الغرض, and سقف الميزانية to the request card rendering loop alongside the existing category/city tags, using the same createElement/textContent pattern already used in that file — do not introduce innerHTML. Touch only site/dashboard.html — nothing under lib/, no other file.
- [ ] In site/request.html, add rendering for purpose, governorate, area, property_subtype, and rental_period (when not null) to the request detail card, using the same safe DOM-building pattern already used in that file. Touch only site/request.html — nothing under lib/, no other file.
