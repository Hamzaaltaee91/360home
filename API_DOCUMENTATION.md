# Dabberli API Documentation

## نقاط النهاية (Endpoints)

جميع الـ endpoints استضافة على:
```
https://your-project.supabase.co/functions/v1/
```

---

## 1. Realtor Verification

### POST `/verify-realtor`

**تحقق من وسيط من قبل مسؤول**

#### الطلب
```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/verify-realtor \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "verification_id": "uuid-here",
    "status": "approved",
    "rejection_reason": null
  }'
```

#### رؤوس الطلب (Headers)
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

#### جسم الطلب (Body)
```json
{
  "verification_id": "string (UUID)",
  "status": "approved | rejected",
  "rejection_reason": "string (optional, required if rejected)"
}
```

#### الرد (Response)
```json
{
  "success": true,
  "message": "Verification approved successfully"
}
```

#### رموز الخطأ
- `401` - غير مصرح (غير مسجل دخول)
- `403` - ممنوع (ليس مسؤول)
- `404` - التحقق غير موجود
- `500` - خطأ الخادم

---

## 2. Offer Matching

### POST `/match-offers`

**احصل على طلبات مطابقة للوسيط**

#### الطلب
```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/match-offers \
  -H "Content-Type: application/json" \
  -d '{
    "realtor_id": "uuid-here",
    "category": "residential",
    "limit": 10
  }'
```

#### جسم الطلب
```json
{
  "realtor_id": "string (UUID, required)",
  "category": "residential | commercial | land (optional)",
  "limit": "number (default: 10, max: 100)"
}
```

#### الرد
```json
{
  "matches": [
    {
      "request_id": "uuid",
      "buyer_id": "uuid",
      "category": "residential",
      "title": "2BR Apartment",
      "city": "Dubai",
      "min_price": 50000,
      "max_price": 100000,
      "bedrooms": 2,
      "bathrooms": 1,
      "match_score": 85
    }
  ]
}
```

#### رموز الخطأ
- `404` - الوسيط غير موجود
- `500` - خطأ الخادم

---

## 3. Notifications

### POST `/send-notification`

**إرسال إخطار فوري**

#### الطلب
```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/send-notification \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "uuid-here",
    "type": "new_offer",
    "title": "عرض جديد",
    "message": "وسيط جديد عرض خاصية مطابقة",
    "data": {
      "offer_id": "uuid-here"
    }
  }'
```

#### جسم الطلب
```json
{
  "user_id": "string (UUID, required)",
  "type": "new_offer | offer_response | new_request | verification_status",
  "title": "string (required)",
  "message": "string (required)",
  "data": "object (optional)"
}
```

#### الرد
```json
{
  "success": true
}
```

---

## 4. Search & Filter

### POST `/search-requests`

**بحث متقدم عن طلبات العقارات**

#### الطلب
```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/search-requests \
  -H "Content-Type: application/json" \
  -d '{
    "category": "residential",
    "city": "Dubai",
    "min_price": 50000,
    "max_price": 200000,
    "bedrooms": 2,
    "sort_by": "recent",
    "limit": 20,
    "offset": 0
  }'
```

#### جسم الطلب
```json
{
  "category": "residential | commercial | land (optional)",
  "city": "string (optional)",
  "min_price": "number (optional)",
  "max_price": "number (optional)",
  "bedrooms": "number (optional)",
  "bathrooms": "number (optional)",
  "latitude": "number (optional)",
  "longitude": "number (optional)",
  "radius_km": "number (default: 10, for geospatial)",
  "sort_by": "recent | price_low | price_high (default: recent)",
  "status": "active | inactive | sold | rented (default: active)",
  "limit": "number (default: 20, max: 100)",
  "offset": "number (default: 0)"
}
```

#### الرد
```json
{
  "results": [
    {
      "id": "uuid",
      "buyer_id": "uuid",
      "category": "residential",
      "title": "2BR Apartment",
      "city": "Dubai",
      "min_price": 50000,
      "max_price": 100000,
      "status": "active",
      "created_at": "2026-09-08T10:00:00Z"
    }
  ],
  "total_count": 150,
  "has_more": true
}
```

---

## 5. Analytics

### POST `/analytics`

**احصل على إحصائيات الأداء**

#### الطلب - إحصائيات الوسيط
```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/analytics \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "realtor",
    "user_id": "uuid-here",
    "date_from": "2026-08-08",
    "date_to": "2026-09-08"
  }'
```

#### الرد - إحصائيات الوسيط
```json
{
  "total_offers": 25,
  "accepted_offers": 15,
  "rejected_offers": 8,
  "pending_offers": 2,
  "average_response_time": 4.5,
  "total_interactions": 50
}
```

#### الطلب - إحصائيات المشتري
```json
{
  "type": "buyer",
  "user_id": "uuid-here",
  "date_from": "2026-08-08",
  "date_to": "2026-09-08"
}
```

#### الرد - إحصائيات المشتري
```json
{
  "total_requests": 5,
  "active_requests": 2,
  "total_offers_received": 20,
  "total_offers_accepted": 8,
  "response_rate": 65
}
```

#### الطلب - إحصائيات المنصة
```json
{
  "type": "platform",
  "date_from": "2026-08-08",
  "date_to": "2026-09-08"
}
```

#### الرد - إحصائيات المنصة
```json
{
  "period": {
    "from": "2026-08-08",
    "to": "2026-09-08"
  },
  "new_users": {
    "total": 150,
    "buyers": 100,
    "realtors": 50
  },
  "property_requests": 500,
  "realtor_offers": 1200,
  "offer_acceptance_rate": 72,
  "average_offers_per_request": 2.4
}
```

---

## RPC Functions (مباشرة عبر SQL)

### استدعاء RPC من Flutter/Dart

```dart
// مثال: البحث الجغرافي
final response = await supabase.rpc(
  'nearby_requests',
  params: {
    'lat': 25.2048,
    'lng': 55.2708,
    'radius_m': 10000,
  },
);
final nearbyRequests = response as List;
```

### الدوال المتاحة

#### 1. `nearby_requests(lat, lng, radius_m)`
```sql
SELECT * FROM nearby_requests(25.2048, 55.2708, 10000);
```

#### 2. `get_buyer_offer_stats(buyer_id)`
```sql
SELECT * FROM get_buyer_offer_stats('uuid-here');
```

#### 3. `get_realtor_performance(realtor_id)`
```sql
SELECT * FROM get_realtor_performance('uuid-here');
```

#### 4. `calculate_match_score(request_id, offer_id)`
```sql
SELECT public.calculate_match_score('req-uuid', 'offer-uuid');
```

#### 5. `auto_expire_offers()`
```sql
SELECT public.auto_expire_offers();
```

---

## معالجة الأخطاء

### رموز الحالة (Status Codes)

| الرمز | المعنى |
|-------|--------|
| 200 | نجح |
| 201 | تم الإنشاء |
| 400 | طلب خاطئ |
| 401 | غير مصرح |
| 403 | ممنوع |
| 404 | غير موجود |
| 500 | خطأ الخادم |

### مثال على الخطأ
```json
{
  "error": "Realtor not found"
}
```

---

## المصادقة (Authentication)

### JWT Token
```bash
# احصل على token
curl -X POST \
  https://your-project.supabase.co/auth/v1/token \
  -d "grant_type=password&email=user@example.com&password=password123"

# استخدمه في الطلبات
-H "Authorization: Bearer $TOKEN"
```

### SERVICE_ROLE_KEY
للعمليات التي تتطلب صلاحيات عالية (مثل الإخطارات):
```bash
-H "Authorization: Bearer $SERVICE_ROLE_KEY"
```

---

## معدل الطلبات (Rate Limiting)

- **الحد**: 10 طلبات/ثانية لكل المستخدم
- **التجاوز**: سيتلقى رمز `429 Too Many Requests`

---

## أمثلة متقدمة

### مثال 1: إنشاء عرض وإرسال إخطار

```dart
// 1. أنشئ العرض
final offer = await supabase.from('realtor_offers').insert({
  'realtor_id': realtorId,
  'request_id': requestId,
  'property_title': 'Marina Apartment',
  'offered_price': 75000,
});

// 2. احصل على معلومات المشتري
final request = await supabase
  .from('property_requests')
  .select('buyer_id')
  .eq('id', requestId)
  .single();

// 3. أرسل إخطار
await supabase.functions.invoke(
  'send-notification',
  body: {
    'user_id': request['buyer_id'],
    'type': 'new_offer',
    'title': 'عرض جديد',
    'message': 'وسيط عرض خاصية مطابقة لطلبك',
    'data': {'offer_id': offer[0]['id']},
  },
);
```

### مثال 2: البحث والعرض في خريطة

```dart
// 1. ابحث عن الطلبات
final response = await supabase.functions.invoke(
  'search-requests',
  body: {
    'latitude': userLat,
    'longitude': userLng,
    'radius_km': 5,
    'category': 'residential',
  },
);

// 2. عرض على خريطة
final requests = (response.data['results'] as List)
  .map((r) => PropertyRequest.fromJson(r))
  .toList();

// استخدم flutter_map أو google_maps_flutter
for (var req in requests) {
  addMarker(lat: req.latitude, lng: req.longitude);
}
```

### مثال 3: تتبع الأداء

```dart
// احصل على إحصائيات يومية
final response = await supabase.functions.invoke(
  'analytics',
  body: {
    'type': 'realtor',
    'user_id': realtorId,
    'date_from': DateTime.now()
      .subtract(Duration(days: 7))
      .toIso8601String(),
  },
);

final stats = response.data as Map<String, dynamic>;
print('العروض المقبولة: ${stats['accepted_offers']}');
print('معدل الرد: ${stats['average_response_time']} ساعات');
```

---

## أفضل الممارسات

### 1. معالجة الأخطاء
```dart
try {
  final response = await supabase.functions.invoke(...);
  // معالجة النتيجة
} catch (e) {
  print('خطأ: $e');
  // عرض رسالة للمستخدم
}
```

### 2. التخزين المؤقت (Caching)
```dart
// استخدم shared_preferences للتخزين المؤقت
final prefs = await SharedPreferences.getInstance();
final cachedMatches = prefs.getString('matches_cache');
```

### 3. الإشعارات الفورية
```dart
// اشترك في الإخطارات
supabase.realtime
  .on('broadcast', { event: 'notifications:$userId' }, (payload) {
    // معالجة الإخطار
  })
  .subscribe();
```

---

## اختبار الـ API

### استخدام Postman
1. استورد متغيرات البيئة
2. استخدم `{{SUPABASE_URL}}/functions/v1/...`
3. أضف رأس `Authorization` مع token

### استخدام cURL
```bash
export TOKEN="your-jwt-token"
export URL="https://your-project.supabase.co"

curl -X POST "$URL/functions/v1/match-offers" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"realtor_id":"...","limit":10}'
```

---

**آخر تحديث**: 2026-09-08
