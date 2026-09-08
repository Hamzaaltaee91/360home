# Phase 3 - Flutter Web App

## نظرة عامة

بناء تطبيق ويب Flutter مع التركيز على واجهات المستخدم للمشترين والوسطاء.

**المهلة الزمنية**: 3-4 أسابيع

---

## هيكل المشروع

```
lib/
├── main.dart                      # نقطة البداية
├── models/
│   └── models.dart               # Data models
├── services/
│   └── supabase_service.dart     # Supabase integration
├── themes/
│   └── app_theme.dart            # Theme & colors
├── routes/
│   └── app_routes.dart           # Navigation
└── screens/
    ├── splash_screen.dart         # Splash & initialization
    ├── auth/
    │   ├── login_screen.dart     # Login page
    │   └── signup_screen.dart    # Registration page
    ├── buyer/
    │   ├── buyer_home_screen.dart        # Buyer dashboard
    │   ├── create_request_screen.dart    # Create property request
    │   ├── browse_offers_screen.dart     # View offers
    │   └── offer_details_screen.dart     # Offer details
    ├── realtor/
    │   ├── realtor_home_screen.dart      # Realtor dashboard
    │   ├── browse_requests_screen.dart   # Find requests to offer
    │   └── create_offer_screen.dart      # Create offer
    └── profile/
        └── profile_screen.dart            # User profile
```

---

## المكتبات الرئيسية

| المكتبة | الإصدار | الغرض |
|---------|---------|--------|
| supabase_flutter | 1.10.0 | تكامل Supabase |
| go_router | 10.0.0 | الملاحة |
| provider | 6.0.0 | State management |
| riverpod | 2.4.0 | State management (بديل) |
| cached_network_image | 3.3.0 | تخزين الصور |
| intl | 0.19.0 | التعريب |
| flutter_dotenv | 5.1.0 | متغيرات البيئة |

---

## البدء

### 1. تثبيت المكتبات

```bash
flutter pub get
```

### 2. إنشاء ملف .env.local

```bash
cp .env.example .env.local

# أضف قيمك:
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 3. تشغيل التطبيق

```bash
# تطبيق الويب
flutter run -d web

# أو الموبايل (Android/iOS)
flutter run
```

---

## الشاشات الأساسية

### 1. Splash Screen (`splash_screen.dart`)
- عرض الشعار والاسم
- التحقق من حالة المستخدم
- إعادة التوجيه (تسجيل دخول / لوحة تحكم)

### 2. Authentication (`auth/`)
- **Login**: تسجيل دخول بالبريد والكلمة السرية
- **Signup**: إنشاء حساب جديد مع اختيار الدور

### 3. Buyer Dashboard (`buyer/`)
```
buyer_home_screen
├── عرض الطلبات النشطة
├── إنشاء طلب جديد (FAB)
└── الملاحة السفلى
```

#### Create Request Flow
```
create_request_screen
├── اختيار الفئة (residential/commercial/land)
├── إدخال البيانات:
│   ├── العنوان (مطلوب)
│   ├── المدينة (مطلوب)
│   ├── نطاق السعر
│   ├── عدد الغرف
│   └── مواصفات أخرى
└── إرسال → /buyer-home
```

#### Browse Offers
```
browse_offers_screen
├── قائمة العروض المطابقة
├── فلترة وفرز
└── تفاصيل العرض (tap)
```

### 4. Realtor Dashboard (`realtor/`)
```
realtor_home_screen
├── Statistics
│   ├── عدد العروض
│   ├── معدل القبول
│   └── الإيرادات
├── Quick Actions
│   ├── البحث عن طلبات
│   ├── إنشاء عرض جديد
│   └── عرض العروض
```

#### Browse Requests
```
browse_requests_screen
├── طلبات متاحة مع درجات مطابقة
├── فلترة حسب:
│   ├── الفئة
│   ├── المدينة
│   ├── نطاق السعر
│   └── الحالة الجديدة
└── إنشاء عرض (tap)
```

#### Create Offer
```
create_offer_screen
├── تعبئة بيانات العقار:
│   ├── الاسم
│   ├── العنوان
│   ├── الموقع (GPS)
│   ├── السعر
│   ├── نوع التأجير (بيع/إيجار)
│   ├── المدة (شهور)
│   └── الصور والوثائق
└── إرسال → realtor_home
```

### 5. Profile Screen (`profile/`)
- عرض بيانات المستخدم
- تعديل الملف الشخصي
- تسجيل الخروج

---

## Integration مع Backend

### Supabase Service

```dart
final supabase = SupabaseService();

// المصادقة
await supabase.signUp(
  email: 'user@example.com',
  password: 'password',
  fullName: 'احمد',
  role: 'buyer',
);

// إنشاء طلب عقار
final request = await supabase.createPropertyRequest(
  category: 'residential',
  title: '2BR في الإمارات',
  city: 'Dubai',
  minPrice: 50000,
  maxPrice: 150000,
);

// الحصول على عروض مطابقة
final offers = await supabase.getOffersForRequest(requestId);

// الحصول على إحصائيات
final stats = await supabase.getRealtorStats();
```

---

## State Management

### استخدام Provider

```dart
class UserProvider extends ChangeNotifier {
  User? _user;
  
  User? get user => _user;
  
  Future<void> loadUser() async {
    _user = await SupabaseService().getCurrentUser();
    notifyListeners();
  }
  
  Future<void> logout() async {
    await SupabaseService().signOut();
    _user = null;
    notifyListeners();
  }
}

// في الـ UI:
Consumer<UserProvider>(
  builder: (context, userProvider, child) {
    if (userProvider.user == null) {
      return const LoginScreen();
    }
    return const DashboardScreen();
  },
)
```

---

## التصميم

### Color Palette
- **Primary**: Indigo (#6366F1)
- **Secondary**: Emerald (#10B981)
- **Error**: Red (#EF4444)
- **Background**: Gray 50 (#F9FAFB)
- **Surface**: White (#FFFFFF)

### Typography
- **Display**: Bold, 32px-24px
- **Heading**: Semi-bold, 20px-16px
- **Body**: Regular, 16px-12px
- **Caption**: Regular, 12px

### Spacing & Borders
- **Border Radius**: 8px (inputs), 12px (cards)
- **Spacing**: 8px, 16px, 24px increments
- **Shadow**: Minimal (0-8px elevation)

---

## الاختبار

### اختبار الوحدة

```bash
flutter test
```

### اختبار التكامل

```bash
# تشغيل على ويب
flutter run -d web

# تشغيل على محاكي Android
flutter run -d emulator-5554

# تشغيل على iPhone
flutter run -d simulator
```

### اختبار الأداء

```bash
flutter run --profile
```

---

## أفضل الممارسات

### 1. النمذجة (Null Safety)
```dart
// ✅ جيد
final String name;
final String? phone;

// ❌ سيء
final String? name;
```

### 2. معالجة الأخطاء
```dart
try {
  final request = await supabase.createPropertyRequest(...);
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطأ: $e')),
    );
  }
}
```

### 3. الملاحة
```dart
// ✅ استخدام Go Router
context.go('/buyer-home');

// ❌ تجنب Navigator.push
Navigator.of(context).push(...);
```

### 4. التخزين المؤقت (Caching)
```dart
// استخدم cached_network_image
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
)
```

---

## قائمة التحقق

- [ ] تثبيت Flutter SDK
- [ ] تثبيت المكتبات (`flutter pub get`)
- [ ] إنشاء `.env.local` مع بيانات Supabase
- [ ] تشغيل Splash screen
- [ ] اختبار Login/Signup
- [ ] اختبار Buyer workflow
- [ ] اختبار Realtor workflow
- [ ] اختبار Profile و Logout
- [ ] اختبار على الويب
- [ ] اختبار على الموبايل
- [ ] تحسين الأداء
- [ ] اختبار على أجهزة مختلفة

---

## المشاكل الشائعة

### خطأ: "Missing Supabase credentials"
**الحل**: تأكد من وجود `.env.local` مع القيم الصحيحة

### خطأ: "context.go not working"
**الحل**: تأكد من استخدام GoRouter في `MaterialApp.router`

### خطأ: "Null safety"
**الحل**: استخدم `!` أو `??` بحذر فقط عند التأكد من القيمة

### الأداء بطيئ
**الحل**: استخدم `const` و `shouldRebuild` في State

---

## التطورات المستقبلية

### Phase 3B (إذا لزم)
- تحسينات UI/UX
- عرض الخريطة (google_maps_flutter)
- المراسلة المباشرة (chat)
- الإشعارات (notifications)

### Phase 4
- لوحة المسؤولين
- نظام التقييمات

---

## الموارد

- [Flutter Docs](https://flutter.dev/docs)
- [Supabase Flutter](https://supabase.com/docs/reference/flutter)
- [Go Router](https://pub.dev/packages/go_router)
- [Flutter Web](https://flutter.dev/multi-platform/web)

---

**آخر تحديث**: 2026-09-08  
**الحالة**: Phase 3 - البنية الأساسية جاهزة
