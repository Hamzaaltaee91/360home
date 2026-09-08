# مخطط قاعدة البيانات - Dabberli

## ERD (Entity Relationship Diagram)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AUTHENTICATION LAYER                         │
│                          auth.users (Supabase)                     │
└─────────────────┬───────────────────────────────────────────────────┘
                  │
                  │ auth_id (UUID FK)
                  ↓
        ┌─────────────────────┐
        │      USERS          │
        ├─────────────────────┤
        │ id (PK) UUID        │
        │ auth_id (FK) UUID   │
        │ email TEXT UNIQUE   │
        │ phone TEXT          │
        │ full_name TEXT      │
        │ role TEXT           │ ─→ 'buyer' | 'realtor' | 'admin'
        │ is_verified BOOL    │
        │ profile_picture_url │
        │ bio TEXT            │
        │ created_at          │
        │ updated_at          │
        └────────┬────────────┘
                 │
      ┌──────────┴──────────┐
      │                     │
      ↓ (1:1)               ↓ (1:N)
  ┌───────────┐         ┌──────────────────┐
  │ REALTORS  │         │   VERIFICATIONS  │
  ├───────────┤         ├──────────────────┤
  │ id (PK)   │         │ id (PK) UUID     │
  │ user_id   │         │ user_id (FK)     │
  │ (FK→Users)│         │ verification_type│
  │ company   │         │ document_url     │
  │ license#  │         │ status           │
  │ verified_ │         │ rejection_reason │
  │ at        │         │ verified_by (FK) │
  │ avg_rating│         │ created_at       │
  │ total_    │         │ reviewed_at      │
  │ offers    │         └──────────────────┘
  │ updated_at│
  └───────────┘

        ↓ (1:N)
  ┌──────────────────────────┐
  │ PROPERTY_REQUESTS        │
  ├──────────────────────────┤
  │ id (PK) UUID             │
  │ buyer_id (FK→Users)      │
  │ category TEXT            │ ─→ 'residential' | 'commercial' | 'land'
  │ title TEXT               │
  │ description TEXT         │
  │ city TEXT                │
  │ area_name TEXT           │
  │ latitude, longitude      │
  │ min_price, max_price     │
  │ currency TEXT            │
  │ min_area_sqft INT        │
  │ max_area_sqft INT        │
  │ bedrooms INT             │
  │ bathrooms INT            │
  │ furnished BOOL           │
  │ status TEXT              │ ─→ 'active' | 'inactive' | 'sold' | 'rented'
  │ is_urgent BOOL           │
  │ preferred_contact []     │
  │ created_at               │
  │ updated_at               │
  │ expires_at               │
  └──────────┬───────────────┘
             │
             ↓ (1:N)
  ┌──────────────────────────┐
  │ REALTOR_OFFERS           │
  ├──────────────────────────┤
  │ id (PK) UUID             │
  │ realtor_id (FK→Users)    │
  │ request_id (FK→Requests) │
  │ property_title TEXT      │
  │ property_description     │
  │ property_address TEXT    │
  │ latitude, longitude      │
  │ offered_price DECIMAL    │
  │ currency TEXT            │
  │ lease_type TEXT          │ ─→ 'rent' | 'sale'
  │ lease_duration_months    │
  │ area_sqft INT            │
  │ bedrooms INT             │
  │ bathrooms INT            │
  │ furnished BOOL           │
  │ photo_urls []            │
  │ document_urls []         │
  │ status TEXT              │ ─→ 'pending' | 'accepted' | 'rejected' | 'expired'
  │ buyer_response TEXT      │ ─→ 'interested' | 'not_interested' | null
  │ message_to_buyer TEXT    │
  │ created_at               │
  │ updated_at               │
  │ expires_at               │
  └──────────┬───────────────┘
             │
             ↓ (1:N)
  ┌──────────────────────────┐
  │ OFFER_INTERACTIONS       │
  ├──────────────────────────┤
  │ id (PK) UUID             │
  │ offer_id (FK)            │
  │ buyer_id (FK→Users)      │
  │ realtor_id (FK→Users)    │
  │ interaction_type TEXT    │ ─→ 'view' | 'message' | 'call_request' | 'meeting_request'
  │ message_content TEXT     │
  │ created_at               │
  └──────────────────────────┘
```

---

## جداول الاتصال (Relationships)

### المستخدمون والوسطاء
- **1:1** - كل وسيط مرتبط بمستخدم واحد
- **إجبارية** - يجب أن يكون هناك ملف user قبل إنشاء ملف realtor
- **الحذف المتسلسل** - حذف المستخدم يحذف ملف الوسيط

### طلبات العقارات
- **1:N** - كل مشتري له عدة طلبات
- **إجبارية** - كل طلب مرتبط بمشتري واحد
- **الحذف المتسلسل** - حذف المشتري يحذف طلباته

### عروض الوسطاء
- **1:N** - كل طلب له عدة عروض
- **إجبارية** - كل عرض مرتبط بطلب واحد وبوسيط واحد
- **الحذف المتسلسل** - حذف الطلب يحذف عروضه

### التفاعلات
- **1:N** - كل عرض له عدة تفاعلات
- **تتبع** - تسجيل كل مشاهدة ورسالة واتصال

---

## الفهارس (Indexes)

### الأداء العالي
```sql
-- البحث السريع بـ user
idx_users_auth_id          → auth_id
idx_users_role             → role (للتصفية حسب الدور)

-- البحث عن طلبات المشتري
idx_property_requests_buyer_id    → buyer_id
idx_property_requests_category    → category
idx_property_requests_city        → city
idx_property_requests_status      → status
idx_property_requests_expires_at  → expires_at (للعروض المنتهية)

-- البحث عن عروض الوسيط
idx_realtor_offers_realtor_id     → realtor_id
idx_realtor_offers_request_id     → request_id
idx_realtor_offers_status         → status
idx_realtor_offers_expires_at     → expires_at

-- التحقق من الوسطاء
idx_realtors_verified_at          → verified_at (الوسطاء المحققين)
idx_realtors_license_number       → license_number (التحقق من الفريدية)
```

---

## الأنواع والقيود (Types & Constraints)

### أنواع الأدوار (Role Types)
| الدور | الوصف | الأذونات |
|------|-------|---------|
| `buyer` | مشتري عقارات | إنشاء طلبات، عرض عروض، الرد على العروض |
| `realtor` | وسيط/مالك عقار | عرض الطلبات النشطة، إنشاء عروض، تتبع الردود |
| `admin` | مسؤول المنصة | إدارة التحقق، حل النزاعات، إعدادات النظام |

### حالات الطلبات (Request Status)
| الحالة | المعنى |
|--------|--------|
| `active` | الطلب نشط، يرى الوسطاء |
| `inactive` | الطلب محفوظ، لا يرى الوسطاء |
| `sold` | تم شراء العقار |
| `rented` | تم استئجار العقار |

### حالات العروض (Offer Status)
| الحالة | المعنى |
|--------|--------|
| `pending` | في انتظار رد المشتري |
| `accepted` | المشتري مهتم |
| `rejected` | المشتري غير مهتم |
| `expired` | انتهت صلاحية العرض بعد 30 يوم |

### أنواع التفاعلات (Interaction Types)
| النوع | المعنى |
|-------|--------|
| `view` | المشتري شاهد العرض |
| `message` | تبادل رسائل |
| `call_request` | طلب اتصال |
| `meeting_request` | طلب لقاء |

---

## القيود والقواعد

### القيود الأساسية
- **NOT NULL**: جميع الحقول الإجبارية معلمة
- **UNIQUE**: email في Users، license_number في Realtors
- **CHECK**: تحقق من القيم المسموحة (role، category، status، إلخ)
- **FOREIGN KEY**: جميع الاتصالات بين الجداول

### القيود المخصصة
```sql
-- role يجب أن يكون أحد هذه القيم
CHECK (role IN ('buyer', 'realtor', 'admin'))

-- category يجب أن يكون أحد هذه القيم
CHECK (category IN ('residential', 'commercial', 'land'))

-- status يجب أن يكون أحد هذه القيم
CHECK (status IN ('active', 'inactive', 'sold', 'rented'))

-- buyer_response يجب أن يكون أحد هذه القيم
CHECK (buyer_response IN ('interested', 'not_interested'))
```

---

## حقول التاريخ والوقت

### updated_at (التحديث التلقائي)
جميع الجداول الرئيسية لها `updated_at` يتحدث تلقائيًا عند التعديل:
```sql
CREATE TRIGGER update_<table>_updated_at
  BEFORE UPDATE ON public.<table>
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### expires_at (انتهاء الصلاحية)
- **property_requests**: يمكن تعيينها يدويًا
- **realtor_offers**: تُعيّن افتراضيًا بـ 30 يوم من الآن

---

## التخزين (Storage)

### Supabase Storage Buckets
```
dabberli/
├── property-photos/      # صور العقارات من العروض
├── property-documents/   # المستندات (صكوك، شهادات)
├── profile-pictures/     # صور المستخدمين
└── verification-docs/    # مستندات التحقق من الوسطاء
```

---

## البيانات الافتراضية

### قيم DEFAULT
```sql
-- Users
role DEFAULT 'buyer'
is_verified DEFAULT false
created_at DEFAULT NOW()

-- Realtor Offers
status DEFAULT 'pending'
currency DEFAULT 'AED'
expires_at DEFAULT NOW() + INTERVAL '30 days'

-- Verifications
status DEFAULT 'pending'

-- Property Requests
status DEFAULT 'active'
is_urgent DEFAULT false
currency DEFAULT 'AED'
```

---

## ملاحظات الأمان

- ✅ **RLS فعّل**: جميع الجداول محمية بسياسات صارمة
- ✅ **الفهارس محسّنة**: للبحث السريع والآمن
- ✅ **الحذف المتسلسل**: لمنع البيانات اليتيمة
- ✅ **التشفير**: يتم التعامل مع كلمات المرور بواسطة Supabase Auth
- ✅ **الحقول الحساسة**: (الهاتف، العنوان) محمية بـ RLS

**آخر تحديث**: 2026-09-08
