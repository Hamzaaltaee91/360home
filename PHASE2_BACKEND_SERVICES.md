# Phase 2 - Backend Services & API Layer

## نظرة عامة

مرحلة البناء الخلفي التي تجهز الخدمات المشتركة والعمليات المعقدة.

**المهلة الزمنية**: 2-3 أسابيع (بعد Phase 1)

---

## الخدمات الرئيسية

### 1. Realtor Verification Service ✅
**الملف**: `supabase/functions/verify-realtor/index.ts`

**الوظيفة**: اعتماد/رفض مستندات الوسطاء من قبل المسؤولين

**المدخلات**:
```typescript
{
  verification_id: UUID,
  status: 'approved' | 'rejected',
  rejection_reason?: string
}
```

**المخرجات**:
```typescript
{
  success: boolean,
  message: string
}
```

**الخطوات**:
1. التحقق من أن المستخدم admin
2. تحديث حالة التحقق في جدول verifications
3. إذا تمت الموافقة:
   - حدّث `is_verified` في users
   - حدّث `verified_at` في realtors

**الأمان**: RLS + دور admin فقط

---

### 2. Offer Matching Engine ✅
**الملف**: `supabase/functions/match-offers/index.ts`

**الوظيفة**: تقديم اقتراحات طلبات مطابقة للوسطاء

**المدخلات**:
```typescript
{
  realtor_id: UUID,
  category?: 'residential' | 'commercial' | 'land',
  limit?: number
}
```

**المخرجات**:
```typescript
{
  matches: [
    {
      request_id: UUID,
      buyer_id: UUID,
      category: string,
      title: string,
      city: string,
      match_score: 0-100
    }
  ]
}
```

**خوارزمية المطابقة**:
```
درجة أساسية = 50
+20 إذا كان الطلب حديثًا (<7 أيام)
+15 إذا لم يكن هناك عرض سابق من الوسيط
-10 إذا كان الطلب عاجلًا
النتيجة = min(100, max(0, النتيجة))
```

**الفرز**: حسب درجة المطابقة (الأعلى أولاً)

---

### 3. Notification Service ✅
**الملف**: `supabase/functions/send-notification/index.ts`

**الوظيفة**: إرسال إخطارات فورية عبر Realtime

**أنواع الإخطارات**:
- `new_offer` - عرض جديد على طلب
- `offer_response` - رد المشتري على العرض
- `new_request` - طلب جديد من مشتري
- `verification_status` - تحديث حالة التحقق

**التدفق**:
```
1. استقبال بيانات الإخطار
2. بث عبر Supabase Realtime
3. إرسال بريد إلكتروني (اختياري)
4. حفظ في قاعدة البيانات (مستقبلاً)
```

**القنوات الفورية**:
```typescript
// الاشتراك في تطبيق Flutter:
supabase.realtime
  .on('broadcast', { event: 'notifications:USER_ID' }, (payload) => {
    // معالجة الإخطار
  })
  .subscribe();
```

---

### 4. Search & Filtering Service ✅
**الملف**: `supabase/functions/search-requests/index.ts`

**الوظيفة**: بحث متقدم مع فلاتر وفرز

**المدخلات**:
```typescript
{
  category?: 'residential' | 'commercial' | 'land',
  city?: string,
  min_price?: number,
  max_price?: number,
  bedrooms?: number,
  bathrooms?: number,
  latitude?: number,
  longitude?: number,
  radius_km?: number,
  sort_by?: 'recent' | 'price_low' | 'price_high',
  status?: string,
  limit?: number,
  offset?: number
}
```

**المخرجات**:
```typescript
{
  results: PropertyRequest[],
  total_count: number,
  has_more: boolean
}
```

**الفلاتر المدعومة**:
- ✅ الفئة
- ✅ المدينة
- ✅ نطاق السعر
- ✅ عدد الغرف/الحمامات
- ✅ البحث الجغرافي (نصف قطر)
- ✅ الحالة

**الفرز**:
- `recent` - الأحدث أولاً
- `price_low` - الأرخص أولاً
- `price_high` - الأغلى أولاً

---

### 5. Analytics Service ✅
**الملف**: `supabase/functions/analytics/index.ts`

**الوظيفة**: تحليل الأداء والإحصائيات

**أنواع التحليلات**:

#### أ) إحصائيات الوسيط
```typescript
{
  total_offers: number,
  accepted_offers: number,
  rejected_offers: number,
  pending_offers: number,
  average_response_time: number, // بالساعات
  total_interactions: number
}
```

#### ب) إحصائيات المشتري
```typescript
{
  total_requests: number,
  active_requests: number,
  total_offers_received: number,
  total_offers_accepted: number,
  response_rate: number // 0-100
}
```

#### ج) إحصائيات المنصة
```typescript
{
  period: { from, to },
  new_users: { total, buyers, realtors },
  property_requests: number,
  realtor_offers: number,
  offer_acceptance_rate: number,
  average_offers_per_request: number
}
```

---

## RPC Functions (PostgreSQL)

### 1. `nearby_requests(lat, lng, radius_m)`
بحث جغرافي عن الطلبات القريبة

```sql
SELECT * FROM nearby_requests(25.2048, 55.2708, 10000);
-- يرجع الطلبات ضمن 10 كم
```

### 2. `get_buyer_offer_stats(buyer_id)`
إحصائيات العروض للمشتري

```sql
SELECT * FROM get_buyer_offer_stats('uuid-here');
-- يرجع: total_offers, accepted, rejected, pending, response_rate
```

### 3. `get_realtor_performance(realtor_id)`
مقاييس الأداء للوسيط

```sql
SELECT * FROM get_realtor_performance('uuid-here');
-- يرجع: total_offers, accepted, rejection_rate, avg_response_time, interactions
```

### 4. `calculate_match_score(request_id, offer_id)`
حساب درجة المطابقة بين طلب وعرض

```sql
SELECT public.calculate_match_score('request-uuid', 'offer-uuid');
-- يرجع: درجة من 0-100
```

### 5. `auto_expire_offers()`
تنتهي صلاحية العروض القديمة تلقائيًا

```sql
SELECT public.auto_expire_offers();
-- يمكن جدولته كـ Cron Job
```

---

## الـ Triggers الجديدة

### 1. `on_offer_created_update_stats`
عند إنشاء عرض جديد، حدّث عدد العروض للوسيط

### 2. `on_offer_insert_check_realtor`
تحقق من أن الوسيط مُحقق قبل إنشاء عرض

---

## إعداد Edge Functions

### التثبيت المحلي
```bash
# تأكد من نسخ الملفات في supabase/functions/
ls supabase/functions/
# verify-realtor/
# match-offers/
# send-notification/
# search-requests/
# analytics/
```

### التطوير المحلي
```bash
# بدء Supabase مع دعم Edge Functions
supabase start

# اختبر دالة محددة
supabase functions invoke verify-realtor \
  --local \
  --body '{"verification_id":"...","status":"approved"}'
```

### النشر للإنتاج
```bash
# أولاً، تحقق من الدوال محليًا
supabase functions test

# ثم ادفع إلى الإنتاج
supabase functions deploy verify-realtor
supabase functions deploy match-offers
supabase functions deploy send-notification
supabase functions deploy search-requests
supabase functions deploy analytics
```

---

## الاستدعاءات من Flutter

### مثال 1: طلب التحقق من الوسيط
```dart
final response = await supabase.functions.invoke(
  'verify-realtor',
  body: {
    'verification_id': verificationId,
    'status': 'approved',
  },
);
```

### مثال 2: الحصول على طلبات مطابقة
```dart
final response = await supabase.functions.invoke(
  'match-offers',
  body: {
    'realtor_id': realtorId,
    'category': 'residential',
    'limit': 10,
  },
);
final matches = response.data['matches'];
```

### مثال 3: إرسال إخطار
```dart
await supabase.functions.invoke(
  'send-notification',
  body: {
    'user_id': buyerId,
    'type': 'new_offer',
    'title': 'عرض جديد',
    'message': 'وسيط جديد عرض خاصية مطابقة',
    'data': {'offer_id': offerId},
  },
);
```

### مثال 4: البحث المتقدم
```dart
final response = await supabase.functions.invoke(
  'search-requests',
  body: {
    'city': 'Dubai',
    'min_price': 50000,
    'max_price': 200000,
    'bedrooms': 2,
    'limit': 20,
  },
);
final results = response.data['results'];
```

### مثال 5: الحصول على التحليلات
```dart
final response = await supabase.functions.invoke(
  'analytics',
  body: {
    'type': 'realtor',
    'user_id': realtorId,
  },
);
final stats = response.data;
```

---

## جدولة المهام (Cron Jobs)

### تنتهي صلاحية العروض - يوميًا الساعة 1 صباحًا UTC
```bash
supabase cron install
# أضف وظيفة مجدولة في Supabase Dashboard
# كل يوم → استدعِ auto_expire_offers()
```

### تنظيف الطلبات المنتهية - أسبوعيًا
```sql
-- اختبر محليًا
SELECT COUNT(*) FROM property_requests
WHERE expires_at < NOW() AND status = 'active';

-- ثم حدّث الحالة
UPDATE property_requests
SET status = 'expired'
WHERE expires_at < NOW() AND status = 'active';
```

---

## الاختبار

### اختبار الوحدة (Unit Tests)

```bash
# في supabase/
supabase test
```

### اختبار التكامل (Integration Tests)

```bash
# استخدم Postman أو curl
curl -X POST http://localhost:54321/functions/v1/verify-realtor \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"verification_id":"...","status":"approved"}'
```

### اختبار الأداء

```sql
-- تحقق من سرعة البحث الجغرافي
EXPLAIN ANALYZE
SELECT * FROM nearby_requests(25.2048, 55.2708, 10000);

-- تحقق من سرعة حساب الإحصائيات
EXPLAIN ANALYZE
SELECT * FROM get_realtor_performance('realtor-uuid');
```

---

## الأمان والتصاريح

### متطلبات الأمان

| الخدمة | الدور | التحقق |
|--------|-------|--------|
| verify-realtor | admin | تحقق من auth.uid() لديه دور admin |
| match-offers | realtor | تحقق من أن المستخدم مُحقق |
| send-notification | system | استخدم SERVICE_ROLE_KEY |
| search-requests | public | متاح لجميع الوسطاء المُحققين |
| analytics | owner | اعرض إحصائياتك فقط (RLS) |

### JWT Custom Claims
```json
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "user_role": "buyer" | "realtor" | "admin",
  "is_verified": true | false
}
```

---

## قائمة التحقق

- [ ] نسخ ملفات Edge Functions
- [ ] تطبيق ملف الهجرة 004
- [ ] اختبار كل دالة محليًا
- [ ] اختبار RLS والأمان
- [ ] توثيق API endpoints
- [ ] إضافة معالجة الأخطاء
- [ ] اختبار الأداء
- [ ] إعداد المراقبة والتسجيل
- [ ] نشر في بيئة التطوير
- [ ] اختبار شامل
- [ ] نشر في الإنتاج

---

## المشاكل الشائعة

### المشكلة: "Function not found"
**الحل**: تأكد من أن الملفات موجودة في `supabase/functions/`

### المشكلة: "Permission denied"
**الحل**: تحقق من JWT token والأدوار

### المشكلة: استعلام جغرافي بطيء
**الحل**: تأكد من أن الفهارس GiST موجودة:
```sql
CREATE INDEX idx_property_location ON public.property_requests
USING GIST (ll_to_earth(latitude, longitude));
```

---

## الخطوات التالية

- ✅ Phase 1: قاعدة البيانات والمصادقة
- ✅ Phase 2: خدمات Backend
- ⏳ Phase 3: تطبيق Flutter
- ⏳ Phase 4: لوحة المسؤولين
- ⏳ Phase 5: ميزات متقدمة

---

**آخر تحديث**: 2026-09-08  
**الحالة**: جاهز للتطوير
