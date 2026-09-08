# دليل اختبار سياسات RLS - Dabberli

## ملخص السياسات

### الجدول: Users (المستخدمون)
```
┌──────────────────────────────────────────────────────────────┐
│ POLICY NAME           │ OPERATION │ WHO CAN ACCESS           │
├──────────────────────────────────────────────────────────────┤
│ users_select_own      │ SELECT    │ المستخدم نفسه فقط         │
│ users_update_own      │ UPDATE    │ المستخدم نفسه فقط         │
│ users_select_realtor_ │ SELECT    │ أي شخص يرى الوسطاء       │
│ public                │           │ المحققين فقط              │
└──────────────────────────────────────────────────────────────┘
```

### الجدول: Property Requests (طلبات العقارات)
```
┌──────────────────────────────────────────────────────────────┐
│ POLICY NAME           │ OPERATION │ WHO CAN ACCESS           │
├──────────────────────────────────────────────────────────────┤
│ select_own            │ SELECT    │ المشتري صاحب الطلب        │
│ insert_own            │ INSERT    │ المشتري فقط               │
│ update_own            │ UPDATE    │ المشتري فقط               │
│ delete_own            │ DELETE    │ المشتري فقط               │
│ select_active_for_    │ SELECT    │ الوسطاء المحققين         │
│ realtor               │           │ يرون الطلبات النشطة فقط    │
└──────────────────────────────────────────────────────────────┘
```

### الجدول: Realtor Offers (عروض الوسطاء)
```
┌──────────────────────────────────────────────────────────────┐
│ POLICY NAME           │ OPERATION │ WHO CAN ACCESS           │
├──────────────────────────────────────────────────────────────┤
│ select_own            │ SELECT    │ الوسيط صاحب العرض         │
│ insert_own            │ INSERT    │ الوسيط المحقق فقط          │
│ update_own            │ UPDATE    │ الوسيط فقط                │
│ select_for_buyer      │ SELECT    │ المشتري يرى عروضه فقط     │
│ update_buyer_response │ UPDATE    │ المشتري يرد على العروض    │
└──────────────────────────────────────────────────────────────┘
```

---

## سيناريوهات الاختبار

### سيناريو 1: المشتري ينشئ طلب عقار

#### الخطوات
1. تسجيل دخول المشتري (user_id = A)
2. إنشاء طلب عقار (سكني، 2 غرفة نوم، 50,000 درهم)
3. التحقق من أن الطلب ظهر في قائمتي

#### التوقع
✅ يظهر الطلب للمشتري  
✅ يظهر للوسطاء المحققين  
✅ لا يظهر لمشتري آخر

#### الكود
```sql
-- كمشتري A
INSERT INTO public.property_requests (
  buyer_id, category, title, city,
  min_price, max_price, bedrooms
) VALUES (
  'a-uuid-here', 'residential', '2BR Apartment',
  'Dubai', 50000, 100000, 2
);

-- يجب أن يظهر
SELECT * FROM public.property_requests WHERE id = 'request-id';

-- تبديل إلى مشتري B - لا يجب أن يظهر
SET request.jwt.claims.sub = 'b-uuid-here';
SELECT * FROM public.property_requests WHERE id = 'request-id';
-- النتيجة: 0 صفوف (فشل RLS)
```

---

### سيناريو 2: الوسيط يعرض العرض على الطلب

#### الخطوات
1. تسجيل دخول الوسيط (محقق)
2. رؤية طلب عقار نشط
3. إنشاء عرض مطابق
4. التحقق من أن المشتري يرى العرض

#### التوقع
✅ الوسيط يرى الطلب النشط فقط  
✅ المشتري يرى عرض الوسيط  
✅ وسيط آخر لا يرى عرض الوسيط الأول

#### الكود
```sql
-- كوسيط مُحقق
INSERT INTO public.realtor_offers (
  realtor_id, request_id, property_title,
  property_address, offered_price
) VALUES (
  'realtor-uuid', 'request-uuid', 'Marina Apt',
  'Dubai Marina', 75000
);

-- المشتري يرى العرض
SELECT * FROM public.realtor_offers WHERE request_id = 'request-uuid';
-- النتيجة: 1 صف (العرض مرئي)

-- وسيط آخر لا يرى العرض
SET request.jwt.claims.sub = 'other-realtor-uuid';
SELECT * FROM public.realtor_offers WHERE id = 'offer-uuid';
-- النتيجة: 0 صفوف (فشل RLS)
```

---

### سيناريو 3: المشتري يرد على العرض

#### الخطوات
1. المشتري يفتح العرض
2. الرد بـ "مهتم" أو "غير مهتم"
3. التحقق من أن الوسيط يرى الرد

#### التوقع
✅ المشتري يستطيع تحديث الرد فقط  
✅ الوسيط يرى الرد في العرض الخاص به  
✅ الوسيط الآخر لا يرى العرض

#### الكود
```sql
-- كمشتري
UPDATE public.realtor_offers
SET buyer_response = 'interested'
WHERE id = 'offer-uuid'
  AND request_id = (
    SELECT id FROM public.property_requests
    WHERE buyer_id = auth.uid()
  );

-- كوسيط - يرى تحديث الرد
SELECT buyer_response FROM public.realtor_offers
WHERE id = 'offer-uuid';
-- النتيجة: 'interested'
```

---

### سيناريو 4: الأمان - منع الالتفاف على RLS

#### الاختبار: محاولة عرض طلب شخص آخر
```sql
-- كمشتري A - أحاول عرض طلب المشتري B
SELECT * FROM public.property_requests
WHERE buyer_id = 'b-uuid-here';
-- النتيجة المتوقعة: 0 صفوف ❌ (فشل RLS)

-- لا يمكنني الوصول حتى لو عرفت UUID الطلب
SELECT * FROM public.property_requests
WHERE id = 'b-request-uuid';
-- النتيجة المتوقعة: 0 صفوف ❌ (فشل RLS)
```

#### الاختبار: محاولة تعديل عرض آخر
```sql
-- كوسيط A - أحاول تعديل عرض الوسيط B
UPDATE public.realtor_offers
SET message_to_buyer = 'hackers message'
WHERE realtor_id = 'realtor-b-uuid';
-- النتيجة المتوقعة: 0 صفوف محدثة ❌ (فشل RLS)
```

---

## أدوات الاختبار

### 1. استخدام Supabase Studio

```bash
# افتح Supabase Studio (محلي)
supabase studio

# انتقل إلى SQL Editor
# اختبر الاستعلامات مع مستخدمين مختلفين
```

### 2. استخدام `curl` مع API

```bash
# احصل على JWT token
curl -X POST https://your-project.supabase.co/auth/v1/token \
  -H "apikey: your-anon-key" \
  -d "grant_type=password&email=user@example.com&password=password123"

# استخدم الـ token في الطلب
curl -H "Authorization: Bearer $TOKEN" \
  https://your-project.supabase.co/rest/v1/property_requests
```

### 3. استخدام Postman

1. إنشاء متغير `token` بـ JWT
2. إضافة Header: `Authorization: Bearer {{token}}`
3. اختبار GET/POST/UPDATE على الـ endpoints

---

## اختبارات الوحدة (Unit Tests)

### مثال: اختبار قراءة الطلبات
```dart
// في Flutter
test('Buyer can only see own requests', () async {
  final user1 = await supabase.auth.signUp(
    email: 'buyer1@test.com',
    password: 'password123',
  );

  // إنشاء طلب
  await supabase.from('property_requests').insert({
    'buyer_id': user1.user!.id,
    'category': 'residential',
    'title': 'Test Request',
    'city': 'Dubai',
  });

  // التبديل إلى مستخدم آخر
  await supabase.auth.signOut();
  await supabase.auth.signUp(
    email: 'buyer2@test.com',
    password: 'password123',
  );

  // محاولة رؤية طلب المستخدم الأول
  final requests = await supabase
    .from('property_requests')
    .select()
    .eq('buyer_id', user1.user!.id);

  expect(requests.length, 0); // يجب أن يكون فارغًا
});
```

---

## قائمة التحقق (Checklist)

- [ ] المستخدم يرى ملفه الخاص فقط
- [ ] المشتري يرى طلباته فقط
- [ ] الوسيط المحقق يرى الطلبات النشطة فقط
- [ ] المشتري يرى عروض طلبه فقط
- [ ] الوسيط يرى عروضه فقط
- [ ] لا أحد يستطيع رؤية بيانات الآخرين
- [ ] لا أحد يستطيع تحديث بيانات الآخرين
- [ ] العروض تنتهي صلاحيتها تلقائيًا بعد 30 يوم
- [ ] الدوال تعمل بشكل صحيح (log_interaction، update timestamp)
- [ ] الفهارس تحسّن الأداء (تحقق من EXPLAIN)

---

## استكشاف الأخطاء

### خطأ: "policy with check option violation"
**السبب**: محاولة إدراج بيانات لا تحقق شرط الفحص  
**الحل**: تحقق من أن القيم تطابق معايير الـ WITH CHECK

### خطأ: "permission denied"
**السبب**: سياسة RLS تحظر الوصول  
**الحل**:
```sql
-- تحقق من السياسات النشطة
SELECT * FROM pg_policies
WHERE tablename = 'property_requests';

-- تعطيل مؤقتًا (للاختبار فقط)
ALTER TABLE property_requests DISABLE ROW LEVEL SECURITY;
-- أعد التفعيل
ALTER TABLE property_requests ENABLE ROW LEVEL SECURITY;
```

### خطأ: "column "auth.uid()" does not exist"
**السبب**: `auth.uid()` لم يُعرّف بعد  
**الحل**: تحقق من أن المستخدم مسجل دخول وأن JWT صحيح

---

## الأوامر المفيدة

```sql
-- عرض جميع سياسات جدول معين
SELECT * FROM pg_policies
WHERE tablename = 'property_requests';

-- اختبار الأداء (EXPLAIN)
EXPLAIN ANALYZE
SELECT * FROM public.property_requests
WHERE buyer_id = auth.uid();

-- عرض عدد الصفوف في جدول
SELECT COUNT(*) FROM public.property_requests;

-- حذف جميع البيانات (للاختبار)
TRUNCATE TABLE public.property_requests CASCADE;
```

---

**آخر تحديث**: 2026-09-08  
**الحالة**: جاهز للاختبار
