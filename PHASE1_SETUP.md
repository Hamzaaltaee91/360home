# Phase 1 Setup Guide - Dabberli

## الإعداد المحلي

### المتطلبات
- Supabase CLI
- Docker (لتشغيل Postgres محليًا)
- Node.js 16+

### خطوات الإعداد

#### 1. تثبيت Supabase CLI
```bash
npm install -g supabase
```

#### 2. تهيئة Supabase محليًا
```bash
supabase init
supabase start
```

#### 3. تطبيق الهجرات (Migrations)
```bash
# الهجرة 1: إنشاء الجداول
supabase migration up

# تحقق من حالة الهجرات
supabase migration list
```

#### 4. عرض قاعدة البيانات
```bash
# الرابط المحلي
supabase studio
```

---

## إعادة تعيين قاعدة البيانات

```bash
# حذف جميع البيانات والهجرات
supabase db reset

# إعادة تطبيق الهجرات من الصفر
supabase migration up
```

---

## اختبار سياسات RLS

### 1. إنشاء مستخدم اختبار
```sql
-- في Supabase Studio SQL Editor
INSERT INTO auth.users (email, password, email_confirmed_at)
VALUES (
  'test@example.com',
  crypt('password123', gen_salt('bf')),
  NOW()
);
```

### 2. التحقق من سياسات الوصول
```sql
-- جرب كمشتري (يجب أن ترى طلباتك فقط)
SELECT * FROM public.property_requests;

-- جرب كوسيط (يجب أن ترى الطلبات النشطة فقط)
SELECT * FROM public.property_requests;
```

---

## الملفات المهمة

```
supabase/
├── migrations/
│   ├── 20260908_001_initial_schema.sql      # الجداول
│   ├── 20260908_002_rls_policies.sql        # سياسات الأمان
│   └── 20260908_003_functions_and_triggers.sql  # الدوال
├── config.toml                               # إعدادات Supabase
└── README.md                                 # هذا الملف
```

---

## نقل إلى الإنتاج (Production)

### 1. إنشاء مشروع Supabase
- زيارة https://supabase.com
- إنشاء مشروع جديد

### 2. الربط مع المشروع الإنتاجي
```bash
supabase link --project-ref <your-project-id>
```

### 3. تطبيق الهجرات
```bash
supabase db push
```

### 4. تعيين متغيرات البيئة
```bash
# في Flutter app أو Backend
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

---

## توثيق الجداول

### Users (المستخدمون)
- **الأعمدة**: id, email, full_name, role, is_verified
- **الأدوار**: buyer, realtor, admin
- **الفهارس**: email, role, auth_id

### Realtors (الوسطاء)
- **الفهرس الأجنبي**: user_id من Users
- **الحقول الخاصة**: license_number, verified_at, average_rating
- **الفهارس**: user_id, verified_at

### Property Requests (طلبات العقارات)
- **الفهرس الأجنبي**: buyer_id من Users
- **الفئات**: residential, commercial, land
- **الحقول الاختيارية**: location, bedrooms, price range
- **الفهارس**: buyer_id, category, city, status

### Realtor Offers (عروض الوسطاء)
- **الفهرس الأجنبي**: realtor_id, request_id
- **انتهاء الصلاحية**: 30 يوم تلقائيًا
- **ردود المشتري**: interested, not_interested, null
- **الفهارس**: realtor_id, request_id, status

### Offer Interactions (التفاعلات)
- **الأنواع**: view, message, call_request, meeting_request
- **الفهرس الأجنبي**: offer_id, buyer_id, realtor_id
- **الغرض**: تتبع المحادثات والتفاعلات

### Verifications (التحقق)
- **الأنواع**: realtor_license, identity, business_registration
- **الحالات**: pending, approved, rejected
- **المدقق**: admin user

---

## الدوال المتاحة

### `get_current_user()`
إرجاع بيانات المستخدم الحالي

```sql
SELECT * FROM public.get_current_user();
```

### `count_verified_realtors()`
عدد الوسطاء المحققة

```sql
SELECT public.count_verified_realtors();
```

### `expire_old_offers()`
منح صلاحية العروض القديمة

```sql
SELECT public.expire_old_offers();
```

### `get_matching_offers(request_id UUID)`
الحصول على عروض مطابقة لطلب معين

```sql
SELECT * FROM public.get_matching_offers('uuid-here');
```

---

## المشاكل الشائعة وحلولها

### المشكلة: "permission denied for schema public"
**الحل**: تحقق من سياسات RLS وتأكد من تعيين `auth.uid()` بشكل صحيح

### المشكلة: الهجرات لم تُطبق
**الحل**:
```bash
supabase migration up --local  # للبيئة المحلية
supabase db push              # للإنتاج
```

### المشكلة: لا يمكن تسجيل الدخول
**الحل**: تحقق من أن جدول المستخدمين قد تم إنشاؤه بواسطة الدالة `handle_new_user()`

---

## الخطوات التالية

- ✅ Phase 1: إعداد قاعدة البيانات
- ⏳ Phase 2: إنشاء خدمات Backend
- ⏳ Phase 3: تطبيق Flutter
- ⏳ Phase 4: لوحة المسؤولين
- ⏳ Phase 5: ميزات متقدمة

---

**تم الإنشاء**: 2026-09-08
**الحالة**: Phase 1 جاهز للاختبار
