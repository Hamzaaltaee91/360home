# TODO — خطة عمل مشروع دبّرلي

> خطة عمل شاملة مبنية على فحص هيكل المشروع الحالي.
> الحالة: المرحلة 1 (الإعداد) والمرحلة 2 (الخدمات الخلفية) مكتملتان جزئياً، والمرحلة 3 (Flutter Web) قيد التنفيذ.

---

## 1. البنية التحتية والإعداد (Infrastructure & Setup)

- [ ] **إعداد ملف `.env.local`** — إنشاء ملف البيئة المحلي الفعلي من `.env.example` وتعبئة `SUPABASE_URL` و `SUPABASE_ANON_KEY` لتشغيل التطبيق محلياً.
- [ ] **التحقق من `pubspec.yaml`** — التأكد من وجود جميع الحزم المطلوبة (`supabase_flutter`, `go_router`, `flutter_dotenv`, `intl`, `image_picker`, `geolocator`) وإضافة أي حزمة ناقصة.
- [ ] **إعداد `analysis_options.yaml`** — تفعيل قواعد lint الصارمة (`flutter_lints` + قواعد إضافية) لضمان جودة الكود.
- [ ] **إعداد CI/CD** — إنشاء `.github/workflows/` لتشغيل `flutter analyze` و `flutter test` تلقائياً عند كل push.
- [ ] **إعداد بيئة Supabase المحلية** — تشغيل `supabase start` والتحقق من تطبيق جميع الـ migrations بنجاح.

---

## 2. قاعدة البيانات والـ Migrations (Database)

- [ ] **مراجعة `20260908_001_initial_schema.sql`** — التأكد من وجود جميع الجداول: `users`, `property_requests`, `realtor_offers`, `notifications`, `realtor_verifications`, `property_photos`.
- [ ] **مراجعة `20260908_002_rls_policies.sql`** — التأكد من تغطية جميع الجداول بسياسات RLS صحيحة لكل دور (buyer, realtor, admin).
- [ ] **مراجعة `20260908_003_functions_and_triggers.sql`** — التأكد من وجود triggers لتحديث `updated_at` وإنشاء `users` تلقائياً عند التسجيل.
- [ ] **مراجعة `20260908_004_phase2_rpc_functions.sql`** — التأكد من دوال RPC: `match_offers`, `search_requests`, `get_realtor_stats`, `get_buyer_stats`.
- [ ] **إضافة migration للفهارس (Indexes)** — إنشاء فهارس على الأعمدة الأكثر استخداماً في الاستعلامات (`city`, `category`, `status`, `buyer_id`, `realtor_id`, `request_id`).
- [ ] **إضافة migration لـ PostGIS** — تفعيل إضافة PostGIS لدعم البحث الجغرافي بالمسافة (radius search).
- [ ] **إضافة migration لجدول `notifications`** — التأكد من وجود الجدول مع حقول `user_id`, `type`, `title`, `message`, `data`, `is_read`, `created_at`.
- [ ] **إضافة migration لجدول `realtor_verifications`** — لتخزين طلبات توثيق الوسطاء وحالتها.
- [ ] **كتابة seed data** — إنشاء ملف `supabase/seed.sql` ببيانات تجريبية للاختبار (مستخدمين، طلبات، عروض).

---

## 3. Edge Functions (Supabase Functions)

- [ ] **اختبار `analytics/index.ts`** — كتابة اختبارات وحدة للتحقق من صحة حساب الإحصائيات للوسيط والمشتري والمنصة.
- [ ] **اختبار `match-offers/index.ts`** — التحقق من منطق مطابقة العروض مع الطلبات بناءً على الفئة والميزانية والموقع.
- [ ] **اختبار `search-requests/index.ts`** — التحقق من البحث بالمسافة الجغرافية والفلترة المتقدمة.
- [ ] **اختبار `send-notification/index.ts`** — التحقق من إرسال الإشعارات (in-app + email) وربطها بـ Resend/SendGrid.
- [ ] **اختبار `verify-realtor/index.ts`** — التحقق من منطق الموافقة/الرفض على توثيق الوسيط.
- [ ] **إضافة Edge Function جديدة: `create-checkout`** — لمعالجة الدفع (اشتراكات الوسطاء) عبر Stripe أو بوابة دفع محلية.
- [ ] **إضافة Edge Function جديدة: `webhook-handler`** — لاستقبال webhooks من بوابة الدفع وتحديث حالة الاشتراك.
- [ ] **إضافة Edge Function جديدة: `delete-account`** — لحذف حساب المستخدم وبياناته (GDPR compliance).
- [ ] **إضافة CORS headers** — التأكد من أن جميع Edge Functions تُرجع headers صحيحة لطلبات Flutter Web.

---

## 4. طبقة الخدمات (Services Layer)

- [ ] **إكمال `supabase_service.dart`** — مراجعة جميع الدوال والتأكد من معالجة الأخطاء (try/catch) وإرجاع رسائل عربية واضحة.
- [ ] **إضافة `notification_service.dart`** — خدمة منفصلة لإدارة الإشعارات (fetch, mark as read, subscribe to realtime).
- [ ] **إضافة `storage_service.dart`** — خدمة منفصلة لرفع/حذف الصور من Supabase Storage.
- [ ] **إضافة `location_service.dart`** — خدمة للحصول على الموقع الحالي وحساب المسافات.
- [ ] **إضافة `payment_service.dart`** — خدمة للتعامل مع الاشتراكات والمدفوعات.
- [ ] **إضافة `analytics_service.dart`** — خدمة لجلب الإحصائيات من Edge Function.
- [ ] **إضافة معالجة الأخطاء المركزية** — إنشاء `lib/utils/error_handler.dart` لتحويل أخطاء Supabase إلى رسائل عربية موحدة.
- [ ] **إضافة التحقق من صحة المدخلات** — إنشاء `lib/utils/validators.dart` للتحقق من البريد، الهاتف، الأسعار، إلخ.

---

## 5. النماذج (Models)

- [ ] **إضافة `Notification` model** — نموذج للإشعارات مع `fromJson` و `toJson`.
- [ ] **إضافة `RealtorVerification` model** — نموذج لطلبات التوثيق.
- [ ] **إضافة `PropertyPhoto` model** — نموذج لصور العقارات.
- [ ] **إضافة `Subscription` model** — نموذج لاشتراكات الوسطاء.
- [ ] **إضافة `copyWith` لجميع النماذج** — لتسهيل تحديث الحالة في State Management.
- [ ] **إضافة `==` و `hashCode` لجميع النماذج** — لضمان عمل المقارنات بشكل صحيح.
- [ ] **إضافة `toJson` للـ `PropertyMatch`** — النموذج الحالي يفتقد دالة `toJson`.

---

## 6. التوجيه (Routing)

- [ ] **مراجعة `app_routes.dart`** — التأكد من وجود جميع المسارات: `/splash`, `/login`, `/signup`, `/buyer`, `/realtor`, `/profile`, `/offer/:id`, `/create-offer/:requestId`, `/create-request`, `/notifications`, `/settings`.
- [ ] **إضافة route guards** — حماية المسارات بناءً على حالة المصادقة والدور (buyer/realtor/admin).
- [ ] **إضافة صفحة 404** — صفحة `NotFoundScreen` للمسارات غير الموجودة.
- [ ] **إضافة deep linking** — دعم الروابط المباشرة للعروض والطلبات.

---

## 7. الشاشات (Screens)

### المصادقة (Auth)
- [ ] **إكمال `login_screen.dart`** — إضافة "نسيت كلمة المرور" و "تذكرني" وربطها بـ Supabase Auth.
- [ ] **إكمال `signup_screen.dart`** — إضافة التحقق من قوة كلمة المرور وشروط الاستخدام.
- [ ] **إضافة `forgot_password_screen.dart`** — شاشة استعادة كلمة المرور.
- [ ] **إضافة `verify_email_screen.dart`** — شاشة تأكيد البريد الإلكتروني.

### المشتري (Buyer)
- [ ] **إكمال `buyer_home_screen.dart`** — إضافة pull-to-refresh، حالة فارغة، وربط الإشعارات.
- [ ] **إكمال `create_request_screen.dart`** — إضافة رفع الصور والموقع الجغرافي والتحقق من المدخلات.
- [ ] **إكمال `browse_offers_screen.dart`** — إضافة البحث والترتيب والتصفية المتقدمة.
- [ ] **إكمال `offer_details_screen.dart`** — إضافة عرض الصور والخريطة والتواصل مع الوسيط.
- [ ] **إضافة `edit_request_screen.dart`** — شاشة تعديل الطلب.
- [ ] **إضافة `request_details_screen.dart`** — شاشة تفاصيل الطلب مع قائمة العروض.

### الوسيط (Realtor)
- [ ] **إكمال `realtor_home_screen.dart`** — إضافة رسوم بيانية للإحصائيات وربطها بـ analytics Edge Function.
- [ ] **إكمال `browse_requests_screen.dart`** — إضافة البحث بالخريطة والفلترة المتقدمة.
- [ ] **إكمال `create_offer_screen.dart`** — إضافة رفع الصور والموقع الجغرافي.
- [ ] **إضافة `my_offers_screen.dart`** — شاشة لعرض جميع عروض الوسيط.
- [ ] **إضافة `verification_screen.dart`** — شاشة لطلب توثيق الوسيط.
- [ ] **إضافة `subscription_screen.dart`** — شاشة لإدارة الاشتراك والدفع.

### الملف الشخصي والإعدادات (Profile & Settings)
- [ ] **إكمال `profile_screen.dart`** — الشاشة الحالية placeholder فقط، تحتاج عرض بيانات المستخدم وتعديلها.
- [ ] **إضافة `edit_profile_screen.dart`** — شاشة تعديل الملف الشخصي مع رفع الصورة.
- [ ] **إضافة `settings_screen.dart`** — شاشة الإعدادات (اللغة، الإشعارات، الوضع الليلي).
- [ ] **إضافة `notifications_screen.dart`** — شاشة عرض الإشعارات.
- [ ] **إضافة `about_screen.dart`** — شاشة "عن التطبيق" و "سياسة الخصوصية".

### الإدارة (Admin)
- [ ] **إضافة `admin_dashboard_screen.dart`** — لوحة تحكم المدير.
- [ ] **إضافة `verify_realtors_screen.dart`** — شاشة مراجعة طلبات توثيق الوسطاء.
- [ ] **إضافة `manage_users_screen.dart`** — شاشة إدارة المستخدمين.

---

## 8. المكونات المشتركة (Shared Widgets)

- [ ] **إضافة `lib/widgets/loading_indicator.dart`** — مؤشر تحميل موحد.
- [ ] **إضافة `lib/widgets/empty_state.dart`** — حالة فارغة موحدة مع أيقونة ورسالة.
- [ ] **إضافة `lib/widgets/error_widget.dart`** — عرض الأخطاء بشكل موحد مع زر إعادة المحاولة.
- [ ] **إضافة `lib/widgets/custom_button.dart`** — زر مخصص بحالات (loading, disabled).
- [ ] **إضافة `lib/widgets/custom_text_field.dart`** — حقل نصي موحد مع التحقق.
- [ ] **إضافة `lib/widgets/property_card.dart`** — بطاقة عرض العقار.
- [ ] **إضافة `lib/widgets/offer_card.dart`** — بطاقة عرض العرض.
- [ ] **إضافة `lib/widgets/request_card.dart`** — بطاقة عرض الطلب.
- [ ] **إضافة `lib/widgets/image_picker_widget.dart`** — مكون لاختيار ورفع الصور.
- [ ] **إضافة `lib/widgets/map_picker.dart`** — مكون لاختيار الموقع على الخريطة.

---

## 9. إدارة الحالة (State Management)

- [ ] **اختيار حل لإدارة الحالة** — Riverpod أو Bloc أو Provider (يجب توثيق القرار).
- [ ] **إضافة `auth_provider.dart`** — لإدارة حالة المصادقة عبر التطبيق.
- [ ] **إضافة `user_provider.dart`** — لإدارة بيانات المستخدم الحالي.
- [ ] **إضافة `requests_provider.dart`** — لإدارة طلبات المشتري.
- [ ] **إضافة `offers_provider.dart`** — لإدارة العروض.
- [ ] **إضافة `notifications_provider.dart`** — لإدارة الإشعارات.

---

## 10. التعريب والترجمة (Localization)

- [ ] **إضافة `flutter_localizations`** — تفعيل دعم التعريب في `pubspec.yaml`.
- [ ] **إضافة `l10n.yaml`** — إعداد ملفات الترجمة.
- [ ] **إضافة `lib/l10n/app_ar.arb`** — ملف الترجمة العربية.
- [ ] **إضافة `lib/l10n/app_en.arb`** — ملف الترجمة الإنجليزية.
- [ ] **تحديث `main.dart`** — إضافة `localizationsDelegates` و `supportedLocales` بشكل صحيح.
- [ ] **إضافة دعم RTL** — التأكد من أن التطبيق يعمل بشكل صحيح في الاتجاه من اليمين لليسار.

---

## 11. الاختبارات (Testing)

### اختبارات الوحدة (Unit Tests)
- [ ] **اختبار النماذج** — `test/models/user_test.dart`, `property_request_test.dart`, `realtor_offer_test.dart`.
- [ ] **اختبار الخدمات** — `test/services/supabase_service_test.dart` مع mock للـ client.
- [ ] **اختبار الـ validators** — `test/utils/validators_test.dart`.
- [ ] **اختبار الـ error handler** — `test/utils/error_handler_test.dart`.

### اختبارات الـ Widgets (Widget Tests)
- [ ] **اختبار شاشة الدخول** — `test/screens/login_screen_test.dart`.
- [ ] **اختبار شاشة التسجيل** — `test/screens/signup_screen_test.dart`.
- [ ] **اختبار شاشة إنشاء الطلب** — `test/screens/create_request_screen_test.dart`.
- [ ] **اختبار شاشة إنشاء العرض** — `test/screens/create_offer_screen_test.dart`.
- [ ] **اختبار المكونات المشتركة** — `test/widgets/` لجميع المكونات.

### اختبارات التكامل (Integration Tests)
- [ ] **اختبار تدفق التسجيل الكامل** — `integration_test/auth_flow_test.dart`.
- [ ] **اختبار تدفق إنشاء طلب → عرض → رد** — `integration_test/offer_flow_test.dart`.
- [ ] **اختبار تدفق توثيق الوسيط** — `integration_test/verification_flow_test.dart`.

### اختبارات RLS
- [ ] **اختبار سياسات RLS** — تنفيذ سيناريوهات `RLS_TESTING_GUIDE.md` والتحقق من النتائج.
- [ ] **اختبار عزل البيانات** — التأكد من أن كل مستخدم يرى بياناته فقط.

### اختبارات Edge Functions
- [ ] **اختبار `analytics`** — `supabase/functions/analytics/index_test.ts`.
- [ ] **اختبار `match-offers`** — `supabase/functions/match-offers/index_test.ts`.
- [ ] **اختبار `search-requests`** — `supabase/functions/search-requests/index_test.ts`.
- [ ] **اختبار `send-notification`** — `supabase/functions/send-notification/index_test.ts`.
- [ ] **اختبار `verify-realtor`** — `supabase/functions/verify-realtor/index_test.ts`.

---

## 12. الأمان (Security)

- [ ] **مراجعة RLS policies** — التأكد من عدم وجود ثغرات تسمح بالوصول غير المصرح.
- [ ] **إضافة rate limiting** — على Edge Functions لمنع الإساءة.
- [ ] **إضافة input sanitization** — لمنع XSS و SQL Injection.
- [ ] **إضافة secure storage** — لتخزين tokens بشكل آمن (`flutter_secure_storage`).
- [ ] **مراجعة صلاحيات Storage** — التأكد من أن buckets الصور محمية بسياسات صحيحة.
- [ ] **إضافة audit log** — لتتبع العمليات الحساسة (توثيق، حذف، تعديل).

---

## 13. الأداء (Performance)

- [ ] **إضافة pagination** — لجميع القوائم (الطلبات، العروض، الإشعارات).
- [ ] **إضافة caching** — لتخزين البيانات المتكررة محلياً.
- [ ] **تحسين الصور** — ضغط الصور قبل الرفع واستخدام thumbnails.
- [ ] **إضافة lazy loading** — للقوائم الطويلة.
- [ ] **تحسين استعلامات قاعدة البيانات** — مراجعة `EXPLAIN ANALYZE` للاستعلامات البطيئة.

---

## 14. تجربة المستخدم (UX)

- [ ] **إضافة splash screen محسّن** — مع animation.
- [ ] **إضافة onboarding** — شاشات تعريفية للمستخدمين الجدد.
- [ ] **إضافة empty states** — لكل شاشة قائمة.
- [ ] **إضافة error states** — مع رسائل واضحة وزر إعادة المحاولة.
- [ ] **إضافة loading states** — skeleton loaders بدلاً من CircularProgressIndicator.
- [ ] **إضافة haptic feedback** — للتفاعلات المهمة.
- [ ] **إضافة dark mode** — التأكد من عمل الوضع الليلي بشكل صحيح (موجود في theme لكن غير مفعّل).

---

## 15. النشر (Deployment)

- [ ] **إعداد Supabase production** — إنشاء مشروع production وربطه.
- [ ] **تطبيق migrations على production** — تشغيل `supabase db push`.
- [ ] **نشر Edge Functions** — تشغيل `supabase functions deploy` لجميع الدوال.
- [ ] **بناء Flutter Web** — تشغيل `flutter build web --release`.
- [ ] **إعداد استضافة** — نشر Flutter Web على Vercel/Netlify/Firebase Hosting.
- [ ] **إعداد النطاق (Domain)** — ربط النطاق المخصص.
- [ ] **إعداد SSL** — التأكد من تفعيل HTTPS.
- [ ] **إعداد monitoring** — Sentry للأخطاء و Supabase Analytics للأداء.

---

## 16. التوثيق (Documentation)

- [ ] **تحديث `README.md`** — إضافة تعليمات التشغيل والنشر.
- [ ] **تحديث `API_DOCUMENTATION.md`** — توثيق جميع Edge Functions والـ RPC.
- [ ] **تحديث `DATABASE_SCHEMA.md`** — توثيق جميع الجداول والعلاقات.
- [ ] **تحديث `PROJECT_PROGRESS.md`** — تحديث نسبة الإنجاز.
- [ ] **إضافة `CONTRIBUTING.md`** — إرشادات المساهمة.
- [ ] **إضافة `CHANGELOG.md`** — سجل التغييرات.

---

## 17. الميزات المستقبلية (Future Features)

- [ ] **إضافة دردشة مباشرة** — بين المشتري والوسيط عبر Supabase Realtime.
- [ ] **إضافة تقييمات ومراجعات** — للوسطاء والعقارات.
- [ ] **إضافة مفضلة** — لحفظ العقارات المفضلة.
- [ ] **إضافة مقارنة العقارات** — لمقارنة عدة عروض جنباً إلى جنب.
- [ ] **إضافة تنبيهات ذكية** — إشعار المستخدم عند توفر عقار يطابق معاييره.
- [ ] **إضافة تقارير PDF** — لتوليد تقارير عن الطلبات والعروض.
- [ ] **إضافة دعم متعدد اللغات** — العربية والإنجليزية.
- [ ] **إضافة تطبيق موبايل** — iOS و Android من نفس الكود.
