# اختبار Phase 2 - Backend Services

## بدء الاختبار

### الإعداد الأولي

```bash
# تأكد من أن Supabase مشغل
supabase status

# حدّث الهجرات
supabase migration up

# تحقق من الدوال والـ Functions
supabase functions list
```

---

## 1. اختبار Realtor Verification

### السيناريو: إقرار وسيط

```bash
# احصل على جلسة مسؤول
export TOKEN="admin-jwt-token-here"

# اختبر الموافقة
curl -X POST http://localhost:54321/functions/v1/verify-realtor \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "verification_id": "verification-uuid",
    "status": "approved"
  }'

# التوقع:
# {
#   "success": true,
#   "message": "Verification approved successfully"
# }
```

### التحقق من قاعدة البيانات

```sql
-- تحقق من تحديث حالة التحقق
SELECT id, status, verified_by, reviewed_at
FROM public.verifications
WHERE id = 'verification-uuid';

-- تحقق من تحديث المستخدم
SELECT id, is_verified
FROM public.users
WHERE id = (
  SELECT user_id FROM public.verifications WHERE id = 'verification-uuid'
);

-- تحقق من تحديث الوسيط
SELECT id, verified_at
FROM public.realtors
WHERE user_id = (
  SELECT user_id FROM public.verifications WHERE id = 'verification-uuid'
);
```

---

## 2. اختبار Offer Matching Engine

### السيناريو: احصل على طلبات مطابقة

```bash
# اختبر المطابقة
curl -X POST http://localhost:54321/functions/v1/match-offers \
  -H "Content-Type: application/json" \
  -d '{
    "realtor_id": "realtor-uuid",
    "category": "residential",
    "limit": 5
  }'

# التوقع: مصفوفة من الطلبات المطابقة مع درجات
# {
#   "matches": [
#     {
#       "request_id": "uuid",
#       "match_score": 85
#     }
#   ]
# }
```

### التحقق من الخوارزمية

```sql
-- تحقق من النتيجة اليدوية
SELECT 
  ro.id,
  ro.request_id,
  CASE 
    WHEN DATE_PART('day', NOW() - pr.created_at) < 7 THEN 'حديث'
    ELSE 'قديم'
  END AS age_category,
  COUNT(*) OVER (PARTITION BY ro.request_id) as offers_count
FROM public.realtor_offers ro
JOIN public.property_requests pr ON ro.request_id = pr.id
WHERE ro.realtor_id = 'realtor-uuid'
LIMIT 10;
```

---

## 3. اختبار Notification Service

### السيناريو: إرسال إخطار

```bash
# اختبر الإخطار
curl -X POST http://localhost:54321/functions/v1/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "buyer-uuid",
    "type": "new_offer",
    "title": "عرض جديد",
    "message": "وسيط جديد عرض خاصية مطابقة",
    "data": {
      "offer_id": "offer-uuid"
    }
  }'

# التوقع:
# { "success": true }
```

### التحقق من Realtime

في تطبيق Flutter:
```dart
// استمع للإخطارات
supabase.realtime
  .on('broadcast', { event: 'notifications:$buyerId' }, (payload) {
    print('إخطار جديد: ${payload.payload}');
  })
  .subscribe();
```

---

## 4. اختبار Search & Filtering

### السيناريو: البحث بمعايير متعددة

```bash
# بحث بسيط
curl -X POST http://localhost:54321/functions/v1/search-requests \
  -H "Content-Type: application/json" \
  -d '{
    "city": "Dubai",
    "min_price": 50000,
    "max_price": 150000,
    "bedrooms": 2,
    "limit": 10
  }'

# التوقع: قائمة بالطلبات المطابقة
```

### السيناريو: البحث الجغرافي

```bash
# بحث بالقرب من موقع معين
curl -X POST http://localhost:54321/functions/v1/search-requests \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 25.2048,
    "longitude": 55.2708,
    "radius_km": 5,
    "sort_by": "recent",
    "limit": 20
  }'
```

### اختبار الأداء

```bash
# قس سرعة البحث
time curl -X POST http://localhost:54321/functions/v1/search-requests \
  -H "Content-Type: application/json" \
  -d '{
    "city": "Dubai",
    "limit": 100
  }' | jq '.total_count'

# توقع: أقل من 500ms
```

---

## 5. اختبار Analytics Service

### السيناريو: احصائيات الوسيط

```bash
# احصل على إحصائيات الوسيط
curl -X POST http://localhost:54321/functions/v1/analytics \
  -H "Content-Type: application/json" \
  -d '{
    "type": "realtor",
    "user_id": "realtor-uuid"
  }'

# التوقع:
# {
#   "total_offers": 10,
#   "accepted_offers": 6,
#   "average_response_time": 2.5,
#   ...
# }
```

### السيناريو: إحصائيات المشتري

```bash
curl -X POST http://localhost:54321/functions/v1/analytics \
  -H "Content-Type: application/json" \
  -d '{
    "type": "buyer",
    "user_id": "buyer-uuid"
  }'
```

### السيناريو: إحصائيات المنصة

```bash
curl -X POST http://localhost:54321/functions/v1/analytics \
  -H "Content-Type: application/json" \
  -d '{
    "type": "platform",
    "date_from": "2026-08-08",
    "date_to": "2026-09-08"
  }'
```

---

## 6. اختبار RPC Functions

### اختبار البحث الجغرافي

```sql
-- ابحث عن الطلبات القريبة
SELECT * FROM public.nearby_requests(25.2048, 55.2708, 10000)
LIMIT 10;

-- التوقع: قائمة بالطلبات ضمن 10 كم
```

### اختبار إحصائيات الوسيط

```sql
SELECT * FROM public.get_realtor_performance('realtor-uuid');

-- التوقع:
-- total_offers | accepted_offers | rejection_rate | avg_response_days
-- 10           | 6               | 40             | 2.5
```

### اختبار حساب درجة المطابقة

```sql
SELECT public.calculate_match_score('request-uuid', 'offer-uuid');

-- التوقع: درجة من 0-100
```

---

## 7. اختبار الأمان (RLS)

### سيناريو: محاولة تجاوز RLS

```bash
# أنشئ حسابين مختلفين
# user1 = وسيط
# user2 = وسيط آخر

# كـ user1: يجب أن ترى عروضك فقط
SELECT * FROM public.realtor_offers 
WHERE realtor_id = auth.uid();
-- النتيجة: عروضك فقط

# كـ user2: لا تستطيع رؤية عروض user1
SELECT * FROM public.realtor_offers
WHERE realtor_id = 'user1-uuid';
-- النتيجة: 0 صفوف (محمية بـ RLS)
```

### اختبار دور Admin

```bash
# جرب تنفيذ دالة التحقق كمستخدم عادي
# توقع: 403 Forbidden

# جرب كـ admin
# توقع: نجح 200 OK
```

---

## 8. اختبار الأداء

### اختبار الحمل

```bash
# قس وقت الاستجابة تحت الحمل
ab -n 100 -c 10 \
  -H "Content-Type: application/json" \
  -p request.json \
  http://localhost:54321/functions/v1/search-requests

# توقع:
# Requests per second: > 50
# Time per request: < 20ms
```

### اختبار الاستعلامات الضخمة

```sql
-- تحقق من سرعة الاستعلامات الكبيرة
EXPLAIN ANALYZE
SELECT * FROM public.nearby_requests(25.2048, 55.2708, 50000)
LIMIT 1000;

-- توقع: Execution Time < 100ms
```

---

## 9. قائمة التحقق

### Edge Functions
- [ ] جميع الملفات موجودة في `supabase/functions/`
- [ ] جميع `deno.json` موجودة
- [ ] لا توجد أخطاء TypeScript
- [ ] تعمل محليًا بدون أخطاء

### قاعدة البيانات
- [ ] الهجرة 004 تطبقت بنجاح
- [ ] جميع الدوال موجودة وتعمل
- [ ] جميع الـ Triggers تعمل
- [ ] الفهارس محسّنة

### الأمان
- [ ] RLS يمنع الوصول غير المصرح
- [ ] Only admins يستطيعون التحقق من الوسطاء
- [ ] العروض محمية بـ RLS

### الأداء
- [ ] البحث الجغرافي سريع (< 100ms)
- [ ] الإحصائيات محسوبة بسرعة
- [ ] الإخطارات فورية

---

## 10. استكشاف الأخطاء الشائعة

### المشكلة: "Function not found"
```bash
# تحقق من المجلد
ls -la supabase/functions/

# تحقق من اسم الملف
# يجب أن يكون: index.ts
```

### المشكلة: خطأ في الاستيراد (Import Error)
```bash
# تحقق من deno.json
cat supabase/functions/verify-realtor/deno.json

# جرب الاستيراد مباشرة
deno eval "import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';"
```

### المشكلة: RLS يرفض الوصول
```sql
-- تحقق من السياسات النشطة
SELECT * FROM pg_policies
WHERE tablename = 'property_requests';

-- تحقق من auth.uid()
SELECT auth.uid();
```

---

## الخطوات التالية

بعد اجتياز جميع الاختبارات:
1. ✅ Phase 1: قاعدة البيانات
2. ✅ Phase 2: Backend Services
3. ⏳ Phase 3: تطبيق Flutter
4. ⏳ Phase 4: لوحة المسؤولين
5. ⏳ Phase 5: ميزات متقدمة

---

**آخر تحديث**: 2026-09-08
