# Progress Log

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
