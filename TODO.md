
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
- [ ] **Audit Logging** — Trace sensitive operations (verification, deletion, role modification).
- [ ] **Pagination & Lazy Loading** — Implement pagination across requests, offers, and notifications.
- [ ] **Image Compression** — Client-side resize and compression before upload.
