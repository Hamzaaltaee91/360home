# Progress Log

## Cycle: site/js/numerals.js

### Accomplished
- Created `site/js/numerals.js` with the exact content specified in the task:
  - `toWesternDigits(str)` — maps Arabic-Indic digits (U+0660 .. U+0669) to
    Western digits 0-9, leaving every other character unchanged.
  - Implemented with a plain `for` loop over `charCodeAt`, no `Map`, no
    `RegExp`, no `String.prototype.replace`.
  - Exported as an ES Module (`export function toWesternDigits(str)`),
    matching the style of `site/js/offers.js`.
  - No `import`/`require`, no default export, no `window` assignment, no
    `try/catch`, no `console.log`, no `TODO`.
- No other file was created or modified in this task (nothing under `lib/`,
  nothing else under `site/`, no `pubspec.yaml` change).
- Marked the task as complete in `TODO.md`.

### Blocked / Failing
- None.

### Next in Queue
- Next `[ ]` task in `TODO.md` (section 13).

## Cycle: property_subtype Column

### Accomplished
- Added a new additive migration
  (`supabase/migrations/20260911000004_property_subtype.sql`) adding the
  nullable `property_subtype` TEXT column to `public.property_requests`,
  with the CHECK constraint required by the task
  (`category <> 'residential' OR property_subtype IN
  ('apartment', 'house', 'villa', 'duplex')`).
- No RLS policy, SQL function, role, or previously applied migration was
  touched.
- Marked the task as complete in `TODO.md`.

### Blocked / Failing
- None.

### Next in Queue
- Next `[ ]` task in `TODO.md` (section 13).

## Cycle: site/js/offers.js

### Accomplished
- Created `site/js/offers.js` with the exact content specified in the task:
  - `listOffersForRequest(requestId)` — lists offers for a request, newest
    first.
  - `getOffer(id)` — fetches a single offer, throwing when not found.
  - `respondToOffer(id, response)` — updates the buyer response on an offer.
- No other files were created or modified in this task.
- Marked the task as complete in `TODO.md`.

### Blocked / Failing
- None.

### Next in Queue
- `Create site/css/style.css`.

## Cycle: Image Compression

### Accomplished
- Added the `flutter_image_compress` dependency to `pubspec.yaml`.
- Added `lib/utils/image_compressor.dart`:
  - `ImageCompressor.compress(bytes, {maxDimension, quality})` downscales the
    longest edge to 1600px and re-encodes as JPEG at quality 80.
  - Best-effort: returns the original bytes when compression is unsupported
    (Flutter Web) or fails, and never returns a larger payload than the input.
- Wired compression into the upload paths:
  - `create_request_screen.dart` compresses each picked photo before
    `uploadPropertyPhoto`.
  - `create_offer_screen.dart` compresses photos at pick time and uploads the
    compressed bytes.
- Added unit tests in `test/utils/image_compressor_test.dart` covering empty
  input, invalid data fallback, and default bounds.
- No schema changes were required; no migrations were edited.
- Marked the task as complete in `TODO.md`.

### Blocked / Failing
- None.

### Next in Queue
- Section 12 (Security & Optimization) is now complete. Proceed to the next
  uncompleted section in `TODO.md`.

## Cycle: Pagination & Lazy Loading

### Accomplished
- Added paginated service methods in `lib/services/supabase_service.dart`:
  - `getActiveRequests({limit, offset})` — pages active property requests
    for the realtor marketplace, replacing the hard-coded `.limit(50)`.
  - `getBuyerOffers({limit, offset})` — fetches all offers received across
    the current buyer's requests in a single query via an inner join on
    `property_requests`, replacing the previous N+1 fetch-all loop.
- Converted `lib/screens/realtor/browse_requests_screen.dart` from a
  one-shot `FutureBuilder` to accumulated paginated state with a
  `ScrollController`-driven infinite scroll (`_loadRequests` / `_loadMore`,
  `_hasMore`, `_isLoadingMore`, trailing spinner row).
- Converted `lib/screens/buyer/browse_offers_screen.dart` the same way,
  removing the per-request offer fetch loop.
- Existing pagination in `RealtorOffersNotifier`, `OffersForRequestNotifier`,
  and `NotificationsNotifier` (`loadMore()` + `_hasMore`) was already in
  place and is unchanged.
- No schema changes were required; no migrations were edited.
- Marked the task as complete in `TODO.md`.

### Blocked / Failing
- None.

### Next in Queue
- Section 12 (Security & Optimization) remaining task:
  image compression.

## Cycle: Audit Logging

### Accomplished
- Added a new additive migration
  (`supabase/migrations/20260911000003_audit_logging.sql`) introducing an
  `audit_logs` table to trace sensitive operations:
  - Columns: `actor_id`, `action`, `entity_type`, `entity_id`, `metadata`,
    `created_at`, with indexes on actor, entity, action, and recency.
  - RLS enabled; only admins may read. Writes go through a `security definer`
    helper or the service role.
  - `write_audit_log(...)` helper for triggers and Edge Functions.
  - Triggers capture role modifications (`users`), verification decisions
    (`realtor_verifications`), and account deletions (`users`).
- Added a shared Edge Function helper
  (`supabase/functions/_shared/audit.ts`) exposing `writeAuditLog`, which
  records entries via the service role and never throws.
- Wired audit logging into `verify-realtor` after a successful decision.
- No previously applied migrations were edited.
- Marked the task as complete in `TODO.md`.

### Blocked / Failing
- None.

### Next in Queue
- Section 12 (Security & Optimization) remaining tasks:
  pagination & lazy loading, and image compression.

## Cycle: Storage Bucket Rules

### Accomplished
- Added a new additive migration
  (`supabase/migrations/20260911000002_storage_bucket_rules.sql`) hardening
  access to the `dabberli` storage bucket:
  - Ensures the bucket exists and is private (idempotent upsert).
  - Enables RLS on `storage.objects`.
  - Property photos (`property-photos/{request_id}/{file}`):
    - Readable by any authenticated user (buyers viewing offers, realtors
      viewing requests).
    - Insert/update/delete restricted to the uploader (`owner = auth.uid()`).
  - Profile pictures (`profile-pictures/{user_id}/{file}`):
    - Read/write/delete restricted to the owning user's folder via
      `storage.foldername(name)[2] = auth.uid()::text`.
  - Policies are dropped-if-exists first so the migration is idempotent.
- No previously applied migrations were edited.
- Marked the task as complete in `TODO.md`.

### Blocked / Failing
- None.

### Next in Queue
- Section 12 (Security & Optimization) remaining tasks:
  audit logging, pagination & lazy loading, and image compression.

## Cycle: Secure Storage

### Accomplished
- Added `flutter_secure_storage` dependency.
- Added `lib/services/secure_storage_service.dart`:
  - `SecureStorage` abstraction with `read`/`write`/`delete`/`deleteAll`.
  - `SecureStorageService` backed by `FlutterSecureStorage` (Android
    EncryptedSharedPreferences, iOS/macOS Keychain, encrypted web/desktop
    store). All operations are guarded so storage failures never crash the
    app.
  - `SecureStorageKeys` for the persisted Supabase session and cached role.
  - `SecureLocalStorage`, a Supabase `LocalStorage` adapter so the auth
    session is persisted in the platform secure store instead of the default
    plain local storage.
- Wired secure storage into `SupabaseService`:
  - `initialize` now passes `FlutterAuthClientOptions(localStorage:
    SecureLocalStorage(...))`.
  - The cached user role is persisted securely and cleared on sign-out.
  - Added a `secureStorageOverride` setter for test injection.
- Added unit tests in `test/services/secure_storage_service_test.dart`
  covering the `SecureLocalStorage` adapter (empty state, persist/read,
  remove).
- Marked the task as complete in `TODO.md`.

### Blocked / Failing
- None.

### Next in Queue
- Section 12 (Security & Optimization) remaining tasks:
  storage bucket rules, audit logging, pagination & lazy loading, and image
  compression.

## Cycle: Input Sanitization

### Accomplished
- Added a shared sanitization helper
  (`supabase/functions/_shared/sanitize.ts`) with pure, testable functions:
  `sanitizeString`, `sanitizeEmail`, `sanitizeUuid`, `sanitizeEnum`,
  `sanitizeNumber`, `sanitizeInt`, `sanitizeBoolean`, `sanitizeStringArray`,
  and recursive `sanitizeObject`.
  - Strips control characters, script/style/iframe tags, inline event
    handlers, dangerous URL protocols (`javascript:`, `data:`, `vbscript:`),
    and generic HTML tags; trims and caps length.
- Wired sanitization into all five Edge Functions:
  - `search-requests`: normalizes and clamps all query fields (category, city,
    price range, rooms, lat/lng, radius, sort, status, limit, offset).
  - `match-offers`: validates `realtor_id` as a UUID, sanitizes `category`,
    clamps `limit`.
  - `send-notification`: validates `user_id` UUID, sanitizes `title`/`message`,
    recursively sanitizes `data`, and rejects empty payloads.
  - `analytics`: validates `type` against an allow-list, sanitizes `user_id`
    and date bounds.
  - `verify-realtor`: validates `verification_id` UUID, restricts `status` to
    `approved`/`rejected`, sanitizes `rejection_reason`.
- Added unit tests in `test/functions/sanitize_test.dart` mirroring the
  existing `rate_limit_test.dart` convention.
- No previously applied migrations were edited (no schema changes required).
- Marked the task as complete in `TODO.md`.

### Blocked / Failing
- None.

### Next in Queue
- Section 12 (Security & Optimization) remaining tasks:
  secure storage, storage bucket rules, audit logging, pagination & lazy
  loading, and image compression.

## Cycle: Edge Function Rate Limiting

### Accomplished
- Added a new additive migration
  (`supabase/migrations/20260911000001_rate_limiting.sql`) introducing a
  generic fixed-window rate limiter:
  - New `rate_limits` table keyed by `(bucket, identifier, window_start)`.
  - `check_rate_limit(bucket, identifier, limit, window_seconds)` RPC that
    atomically increments the current window's counter, prunes stale windows,
    and returns `(allowed, remaining, reset_at)`.
  - RLS enabled; execute granted only to `service_role`.
- Added a shared helper `supabase/functions/_shared/rate_limit.ts` with
  per-function `RATE_LIMITS` config, identifier resolution (user → IP →
  anonymous), result parsing, a standard 429 response, and a fail-open
  `enforceRateLimit` wrapper.
- Wired rate limiting into all five Edge Functions: `search-requests`,
  `match-offers`, `send-notification`, `analytics`, and `verify-realtor`.
- Added unit tests for the pure helpers in `test/functions/rate_limit_test.dart`.
- No previously applied migrations were edited.
- Marked the task as complete in `TODO.md`.

### Blocked / Failing
- None.

### Next in Queue
- Section 12 (Security & Optimization) remaining tasks:
  input sanitization, secure storage, storage bucket rules, audit logging,
  pagination & lazy loading, and image compression.

## Cycle: RLS Privilege Escalation Audit

### Accomplished
- Added a new additive migration
  (`supabase/migrations/20260911000000_rls_privilege_escalation_audit.sql`)
  that hardens RLS policies against privilege escalation:
  - Users can no longer change their own `role` (blocks self-promotion to
    `admin`); only admins may modify roles.
  - Buyers may only update/delete their own property requests.
  - Realtors may only update/delete their own offers, and only while the
    parent request is still `open`.
  - Realtors may only insert/update their own verification row and can never
    self-approve (`status` must remain `pending` on their writes); only admins
    may approve/reject.
  - Direct writes to `subscriptions` are removed (writes go through Edge
    Functions using the service role).
  - Users may only mark their own notifications as read.
  - Photo deletion is restricted to the owner of the parent request/offer.
- No previously applied migrations were edited.
- Marked the task as complete in `TODO.md`.

### Blocked / Failing
- None.

### Next in Queue
- Section 12 (Security & Optimization) remaining tasks:
  rate limiting, input sanitization, secure storage, storage bucket rules,
  audit logging, pagination & lazy loading, and image compression.

## Cycle: Verification Workflow Integration Test

### Accomplished
- Implemented the **Verification Workflow** integration test
  (`integration_test/verification_workflow_test.dart`) covering the end-to-end
  realtor verification submit flow:
  Sign Up Realtor → Submit Verification → Assert `pending` → Fetch Back.
- The test skips gracefully when `SUPABASE_URL` / `SUPABASE_ANON_KEY` are not
  set, matching the existing integration test convention.
- Marked the task as complete in `TODO.md`.

### Blocked / Failing
- None.

### Next in Queue
- Section 12 (Security & Optimization) tasks remain outstanding:
  RLS audit, rate limiting, input sanitization, secure storage, storage bucket
  rules, audit logging, pagination, and image compression.

## Cycle: Offer Lifecycle Integration Test

### Accomplished
- Implemented the **Offer Lifecycle** integration test
  (`integration_test/offer_lifecycle_test.dart`) covering the end-to-end flow:
  Create Request → Submit Offer → Accept Offer.
- Added the `integration_test` dev dependency to `pubspec.yaml`.
- The test skips gracefully when `SUPABASE_URL` / `SUPABASE_ANON_KEY` are not
  set, so CI without a live backend does not fail.
- Marked the task as complete in `TODO.md`.

### Blocked / Failing
- None.

### Next in Queue
- **Verification Workflow** — End-to-end realtor verification submit
  (section 11, Integration Tests).
- Section 12 (Security & Optimization) tasks remain outstanding:
  RLS audit, rate limiting, input sanitization, secure storage, storage bucket
  rules, audit logging, pagination, and image compression.

## BLOCKED: **Move admin Supabase calls to service layer** — In lib/screens/admin/manage_users_screen.dart, move the two direct Supabase calls (list users, update role) into lib/services/supabase_service.dart as listUsers() and updateUserRole(), then use them from the screen. Do not change any RLS policy or SQL.
التاريخ: 2026-09-12 14:12:48
آخر سبب فشل:
```
SANITY FAILED
  - أمان: استخدام service_role key في الكود — lib/screens/admin/manage_users_screen.dart
  - خرق طبقات: نداء Supabase مباشر داخل lib/screens/admin/manage_users_screen.dart
```

## BLOCKED: **Add price formatting helper** — Create lib/utils/formatters.dart with a single top-level function formatPrice(num value) that returns the value grouped with commas and suffixed with ' IQD'. Pure Dart only, no new packages, no Flutter imports. Add a matching test in test/utils/formatters_test.dart.
التاريخ: 2026-09-12 14:17:12
آخر سبب فشل:
```
SANITY FAILED
  - خرق طبقات: نداء Supabase مباشر داخل lib/screens/admin/manage_users_screen.dart
```

## BLOCKED: **Remove unused imports** — Delete every import flagged as unused_import by flutter analyze. Remove nothing else.
التاريخ: 2026-09-12 15:29:49
آخر سبب فشل:
```
SANITY FAILED
  - خرق طبقات: نداء Supabase مباشر داخل lib/screens/admin/manage_users_screen.dart
```

## BLOCKED: **Fix notifications_provider.dart auth check** — In lib/providers/notifications_provider.dart: (1) delete the unused import '../models/pagination.dart'. (2) Replace the call `_service.isAuthenticated()` with `ref.read(authProvider).valueOrNull != null` (authProvider is already imported in this file from 'auth_provider.dart'). Do not change anything else in the file.
التاريخ: 2026-09-12 17:09:52
آخر سبب فشل:
```
SANITY FAILED
  - خرق طبقات: نداء Supabase مباشر داخل lib/screens/admin/manage_users_screen.dart
```

## BLOCKED: **Remove unused pagination import in offers_provider.dart** — In lib/providers/offers_provider.dart, delete the unused import '../models/pagination.dart' on line 9. Nothing else in the file uses it. Change nothing else.
التاريخ: 2026-09-12 17:10:05
آخر سبب فشل:
```
SANITY FAILED
  - خرق طبقات: نداء Supabase مباشر داخل lib/screens/admin/manage_users_screen.dart
```

## BLOCKED: **Remove unused geolocator import in create_request_screen.dart** — In lib/screens/buyer/create_request_screen.dart, delete the unused import 'package:geolocator/geolocator.dart' on line 6. Nothing else in the file uses Geolocator. Change nothing else.
التاريخ: 2026-09-12 17:10:19
آخر سبب فشل:
```
SANITY FAILED
  - خرق طبقات: نداء Supabase مباشر داخل lib/screens/admin/manage_users_screen.dart
```

## BLOCKED: **Remove unused supabase_flutter import in verification_workflow_test.dart** — In integration_test/verification_workflow_test.dart, delete the unused import 'package:supabase_flutter/supabase_flutter.dart' on line 14. The file only uses dabberli's own SupabaseService class, not any supabase_flutter symbol directly. Change nothing else.
التاريخ: 2026-09-12 17:10:32
آخر سبب فشل:
```
SANITY FAILED
  - خرق طبقات: نداء Supabase مباشر داخل lib/screens/admin/manage_users_screen.dart
```

## BLOCKED: **Fix respondToOffer call in browse_offers_screen.dart** — In lib/screens/buyer/browse_offers_screen.dart line 161, the call `SupabaseService().respondToOffer(offerId, response)` passes positional arguments, but respondToOffer in lib/services/supabase_service.dart requires named parameters `offerId` and `response`. Change the call to `SupabaseService().respondToOffer(offerId: offerId, response: response)`. Do not change the service method. Change nothing else.
التاريخ: 2026-09-12 17:10:46
آخر سبب فشل:
```
SANITY FAILED
  - خرق طبقات: نداء Supabase مباشر داخل lib/screens/admin/manage_users_screen.dart
```

## BLOCKED: **Fix three unrelated bugs in offer_details_screen.dart** — In lib/screens/buyer/offer_details_screen.dart, fix exactly these three things and nothing else: (1) line 107, change `SupabaseService().respondToOffer(widget.offerId, response)` to `SupabaseService().respondToOffer(offerId: widget.offerId, response: response)` because respondToOffer requires named arguments. (2) line 140, `ConnectionState.loading` does not exist; change it to `ConnectionState.waiting`. (3) line 394, `Icons.furniture` does not exist in Flutter's Icons class; change it to `Icons.chair`.
التاريخ: 2026-09-12 17:11:00
آخر سبب فشل:
```
SANITY FAILED
  - خرق طبقات: نداء Supabase مباشر داخل lib/screens/admin/manage_users_screen.dart
```

## BLOCKED: Add `governorate` column to `public.property_requests`: TEXT, storing one of Iraq's 18 governorates as an English slug (e.g. baghdad, basra, nineveh — not Arabic text); keep the existing `city` column untouched for backward compatibility.
التاريخ: 2026-09-13 08:27:36
آخر سبب فشل:
```
تجاوز الحد: 12 ملف (الحد 5)
```

## BLOCKED: Add `area` column to `public.property_requests`: TEXT, nullable, holding the selected sub-area within a governorate or free text when the user picks "أخرى"; keep the existing `area_name` column untouched.
التاريخ: 2026-09-13 08:29:02
آخر سبب فشل:
```
تجاوز الحد: 12 ملف (الحد 5)
```

## BLOCKED: Update the property_requests schema section in CLAUDE.md to document the five new columns added by the migrations above, matching their exact names, types, and constraints. Touch only CLAUDE.md — nothing under lib/, nothing under site/, no SQL file.
التاريخ: 2026-09-13 08:47:52
آخر سبب فشل:
```
تجاوز الحد: 12 ملف (الحد 5)
```

## BLOCKED: Create site/js/numerals.js exporting one function toWesternDigits(str) that maps Arabic-Indic digits ٠-٩ to Western digits 0-9 and leaves every other character unchanged. Touch only this one new file — nothing under lib/, nothing else under site/.
التاريخ: 2026-09-13 09:25:53
آخر سبب فشل:
```
```
