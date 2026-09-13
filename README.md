<!-- test 2 -->
<!-- test comment -->

# Dabberli (دبّرلي) - Reverse Real Estate Platform

منصة عقارات معاكسة حيث يطلب المشترون ويعرض الوسطاء.

## 📋 نظرة عامة

**دبّرلي** تقلب نموذج البحث عن العقارات التقليدي:

### التدفق التقليدي:
```
الوسطاء/الملاك ← ينشئون قوائم
                  ↓
المشترون ← يبحثون ويصفحون
```

### تدفق دبّرلي:
```
المشترون ← ينشرون احتياجاتهم
            ↓
الوسطاء ← يعرضون عروضًا مطابقة
```

## 🏗️ المعمارية

### التكنولوجيا
- **Frontend**: Flutter (iOS/Android/Web)
- **Backend**: Supabase + PostgreSQL
- **Authentication**: Supabase Auth
- **Real-time**: Supabase Realtime
- **Storage**: Supabase Storage

### الفئات المدعومة
- 🏠 **Residential** (سكني)
- 🏢 **Commercial** (تجاري)
- 📍 **Land** (أراضي)

## 📁 هيكل المشروع

```
dabberli/
├── CLAUDE.md                      # توثيق المشروع الشامل
├── PHASE1_SETUP.md               # دليل إعداد المرحلة الأولى
├── DATABASE_SCHEMA.md            # مخطط قاعدة البيانات (ERD)
├── RLS_TESTING_GUIDE.md          # دليل اختبار الأمان
├── supabase/
│   ├── migrations/               # ملفات الهجرة (SQL)
│   │   ├── 20260908_001_initial_schema.sql
│   │   ├── 20260908_002_rls_policies.sql
│   │   └── 20260908_003_functions_and_triggers.sql
│   ├── config.toml               # إعدادات Supabase
│   └── README.md                 # توثيق Supabase
├── lib/                          # كود Flutter (قريبًا)
├── android/                      # تكوين Android
├── ios/                          # تكوين iOS
├── web/                          # تطبيق الويب
├── pubspec.yaml                  # تبعيات Flutter
└── README.md                     # هذا الملف
```

## 🚀 البدء السريع

### 1. المتطلبات الأساسية
```bash
# تثبيت Supabase CLI
npm install -g supabase

# تثبيت Flutter SDK
# من https://flutter.dev

# تثبيت Git
# من https://git-scm.com
```

### 2. إعداد البيئة المحلية
```bash
# نسخ المشروع
git clone https://github.com/hamzaaltaee91/360home.git
cd 360home

# بدء Supabase محليًا
supabase init
supabase start

# تطبيق ملفات الهجرة
supabase migration up
```

### 3. عرض قاعدة البيانات
```bash
# افتح Supabase Studio
supabase studio

# الرابط: http://localhost:54323
```

## 📚 الوثائق

| الملف | الغرض |
|------|--------|
| **CLAUDE.md** | شرح المعمارية الكاملة والخطة المرحلية |
| **DATABASE_SCHEMA.md** | مخطط الجداول والعلاقات (ERD) |
| **PHASE1_SETUP.md** | خطوات إعداد المرحلة الأولى |
| **RLS_TESTING_GUIDE.md** | سيناريوهات اختبار الأمان |

## 🔐 الأمان

### Row-Level Security (RLS)
- ✅ تشفير الوصول على مستوى قاعدة البيانات
- ✅ كل مستخدم يرى بيانات نفسه فقط
- ✅ سياسات صارمة لمنع التسرب

### المراحل المخطط لها

#### Phase 1 ✅ جاري
- قاعدة البيانات والمصادقة
- سياسات RLS صارمة
- الدوال والـ Triggers

#### Phase 2 ⏳
- خدمات Backend
- محرك مطابقة العروض
- الإخطارات الفورية

#### Phase 3 ⏳
- تطبيق Flutter
- واجهات المستخدم
- التكامل مع Supabase

#### Phase 4 ⏳
- لوحة المسؤولين
- التحقق من الوسطاء
- إدارة النزاعات

#### Phase 5 ⏳
- تقييمات وتقييم الأداء
- المراسلة المباشرة
- التحليلات والإحصائيات

## 👥 الأدوار

### Buyer (المشتري)
- ✍️ إنشاء طلبات عقارات
- 👀 عرض العروض المطابقة
- 💬 التواصل مع الوسطاء
- ⭐ تقييم الوسطاء

### Realtor (الوسيط)
- 📋 عرض الطلبات المتاحة
- 💼 إنشاء عروض مطابقة
- 📞 المتابعة مع المشترين
- 📊 تتبع الأداء

### Admin (المسؤول)
- ✅ التحقق من الوسطاء
- ⚖️ حل النزاعات
- ⚙️ إدارة الإعدادات
- 📈 عرض الإحصائيات

## 🗄️ قاعدة البيانات

### الجداول الرئيسية
1. **users** - ملفات المستخدمين
2. **realtors** - بيانات الوسطاء
3. **property_requests** - طلبات المشترين
4. **realtor_offers** - عروض الوسطاء
5. **offer_interactions** - التفاعلات والمحادثات
6. **verifications** - التحقق من الوسطاء

### الفهارس المحسّنة
- تحسين البحث حسب المدينة والفئة
- تحسين البحث حسب المستخدم
- تحسين البحث حسب تاريخ الانتهاء

## 🧪 الاختبار

### اختبار RLS
```bash
# اتبع دليل RLS_TESTING_GUIDE.md
# اختبر السيناريوهات الأساسية:
# - المشتري يرى طلباته فقط
# - الوسيط يرى العروض الخاصة به فقط
# - لا أحد يستطيع رؤية بيانات الآخرين
```

### اختبار الأداء
```sql
-- تحقق من الفهارس
EXPLAIN ANALYZE
SELECT * FROM property_requests
WHERE buyer_id = auth.uid();
```

## 📝 خطة العمل

### هذا الأسبوع
- [x] توثيق المعمارية
- [x] إنشاء ملفات الهجرة
- [x] تطبيق RLS

### الأسبوع القادم
- [ ] اختبار RLS بالكامل
- [ ] إنشاء خدمات Backend
- [ ] البدء بـ Flutter App

## 🔗 الروابط المهمة

- **[Supabase Docs](https://supabase.com/docs)**
- **[Flutter Docs](https://flutter.dev/docs)**
- **[PostgreSQL RLS](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)**

## 💬 المساهمة

1. نسخ المشروع
2. إنشاء فرع (feature branch)
3. التزام التغييرات
4. فتح Pull Request

## ⚖️ الترخيص

جميع الحقوق محفوظة لمشروع Dabberli

---

**آخر تحديث**: 2026-09-08  
**المرحلة**: Phase 1 - قاعدة البيانات والمصادقة
