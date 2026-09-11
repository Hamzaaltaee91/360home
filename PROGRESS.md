# Progress Log

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
