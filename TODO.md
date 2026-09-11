
# TODO — Dabberli Architecture Action Plan

> Comprehensive action plan based on current project architecture.
> Status: Phase 1 (Setup) & Phase 2 (Backend) partially done, Phase 3 (Flutter Web) in progress.

---

## 1. Infrastructure & Setup

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
- [ ] **Implement `forgot_password_screen.dart`** — Password reset flow.
- [ ] **Implement `verify_email_screen.dart`** — Email verification handler screen.

### Buyer Flow
- [ ] **Complete `buyer_home_screen.dart`** — Pull-to-refresh, empty states, and notification badge.
- [ ] **Complete `create_request_screen.dart`** — Image upload, geo-location picker, and field validation.
- [ ] **Complete `browse_offers_screen.dart`** — Search, sort, and filtering controls.
- [ ] **Complete `offer_details_screen.dart`** — Photo viewer, map display, and realtor contact action.
- [ ] **Implement `edit_request_screen.dart`** — Request editing workflow.
- [ ] **Implement `request_details_screen.dart`** — Details view with received offers list.

### Realtor Flow
- [ ] **Complete `realtor_home_screen.dart`** — Dashboard analytics charts integrated with Edge Function.
- [ ] **Complete `browse_requests_screen.dart`** — Map search view and filters.
- [ ] **Complete `create_offer_screen.dart`** — Photo uploads and geo-location picker.
- [ ] **Implement `my_offers_screen.dart`** — List and manage submitted offers.
- [ ] **Implement `verification_screen.dart`** — Verification document submission.
- [ ] **Implement `subscription_screen.dart`** — Tier selection and payment checkout.

### Profile & Settings
- [ ] **Complete `profile_screen.dart`** — Replace placeholder with live profile data display.
- [ ] **Implement `edit_profile_screen.dart`** — Profile edits and avatar upload.
- [ ] **Implement `settings_screen.dart`** — Language, notifications, and dark mode toggles.
- [ ] **Implement `notifications_screen.dart`** — Notification list view.
- [ ] **Implement `about_screen.dart`** — About page and privacy policy view.

### Admin Panel
- [ ] **Implement `admin_dashboard_screen.dart`** — Core metric summaries.
- [ ] **Implement `verify_realtors_screen.dart`** — Review and approve verification requests.
- [ ] **Implement `manage_users_screen.dart`** — User directory and role moderation.

---

## 8. Shared Widgets

- [ ] **Build `loading_indicator.dart`** — Standardized progress loader.
- [ ] **Build `empty_state.dart`** — Uniform empty state with icon and message.
- [ ] **Build `error_widget.dart`** — Reusable error view with retry action.
- [ ] **Build `custom_button.dart`** — Common button supporting loading and disabled states.
- [ ] **Build `custom_text_field.dart`** — Form text input with inline error validation.
- [ ] **Build `property_card.dart`** — Standardized property card.
- [ ] **Build `offer_card.dart`** — Standardized offer item card.
- [ ] **Build `request_card.dart`** — Standardized request item card.
- [ ] **Build `image_picker_widget.dart`** — Multi-image picker and preview component.
- [ ] **Build `map_picker.dart`** — Interactive location selector.

---

## 9. State Management

- [ ] **Establish State Management Choice** — Select and document Riverpod or Bloc.
- [ ] **Implement `auth_provider.dart`** — Global authentication state.
- [ ] **Implement `user_provider.dart`** — Current user session and profile data.
- [ ] **Implement `requests_provider.dart`** — Buyer requests state.
- [ ] **Implement `offers_provider.dart`** — Realtor offers state.
- [ ] **Implement `notifications_provider.dart`** — Notification stream state.

---

## 10. Localization & RTL

- [ ] **Configure `flutter_localizations`** — Ensure dependencies in `pubspec.yaml`.
- [ ] **Setup `l10n.yaml`** — Localization generation configuration.
- [ ] **Create `lib/l10n/app_ar.arb`** — Arabic string catalog.
- [ ] **Create `lib/l10n/app_en.arb`** — English string catalog.
- [ ] **Update `main.dart`** — Register `localizationsDelegates` and `supportedLocales`.
- [ ] **Verify RTL Alignment** — Ensure bidirectional layout support.

---

## 11. Testing

### Unit Tests
- [ ] **Model Tests** — Unit coverage for User, PropertyRequest, RealtorOffer.
- [ ] **Service Tests** — Mock Supabase client tests in `test/services/`.
- [ ] **Validator Tests** — Comprehensive validator coverage in `test/utils/`.
- [ ] **Error Handler Tests** — Translate and handle Supabase exceptions.

### Widget Tests
- [ ] **Screen Tests** — Widget tests for login, signup, request, and offer screens.
- [ ] **Component Tests** — Widget tests for shared components.

### Integration Tests
- [ ] **Auth Journey** — End-to-end authentication flow.
- [ ] **Offer Lifecycle** — Flow: Create Request → Submit Offer → Accept Offer.
- [ ] **Verification Workflow** — End-to-end realtor verification submit.

---

## 12. Security & Optimization

- [ ] **Audit RLS Policies** — Review all policies against privilege escalation.
- [ ] **Rate Limiting** — Enforce rate limits on Edge Functions.
- [ ] **Input Sanitization** — Prevent malicious payload injections.
- [ ] **Secure Storage** — Secure storage integration for sensitive tokens.
- [ ] **Storage Bucket Rules** — Validate access rules for property image buckets.
- [ ] **Audit Logging** — Trace sensitive operations (verification, deletion, role modification).
- [ ] **Pagination & Lazy Loading** — Implement pagination across requests, offers, and notifications.
- [ ] **Image Compression** — Client-side resize and compression before upload.
