# التقرير التحليلي التقني - تطبيق Parent (ولي الأمر)

**تاريخ التحليل:** 2 مارس 2026  
**إصدار Flutter:** 3.8.1+  
**نمط المعمارية:** GetX Pattern (MVC-Style)

---

## 1. نظرة عامة على المشروع

### الهدف التطبيقي
تطبيق **ولي الأمر** (Parent) هو بوابة لأولياء الأمور لمتابعة أبنائهم الدراسيين، يوفر:
- متابعة الأداء الدراسي والاختبارات
- عرض الحضور والغياب
- التواصل مع المعلمين
- إدارة الأنشطة والواجبات
- استلام الإشعارات المدرسية

### المستخدمون المستهدفون (بناءً على الأدلة)
| الدليل | التحليل |
|--------|---------|
| اسم التطبيق في `main.dart:59` | "Parent - ولي الأمر" |
| حقل `relationship` في `child_model.dart:62` | أب، أم، وصي، أخ، أخت |
| جدول `parents` في Supabase | أولياء أمور مسجلين في النظام |

### الوحدات الرئيسية
```
lib/modules/parent/
├── controllers/     (6 controllers)
├── models/           (10 models)
├── services/         (3 services - Supabase integration)
├── views/            (10 views)
└── widgets/          (10 reusable widgets)
```

---

## 2. بنية المجلدات والكود

### 2.1 هيكل المجلدات

```
parent/
├── lib/
│   ├── config/
│   │   └── supabase_config.dart          # ⚠️ يحتوي على مفاتيح مكشوفة
│   ├── core/utils/                        # helpers و utilities
│   ├── modules/parent/
│   │   ├── controllers/                   # منطق الأعمال (Business Logic)
│   │   ├── models/                        # نماذج البيانات
│   │   ├── services/                      # طبقة الوصول للبيانات
│   │   ├── views/                         # واجهات المستخدم
│   │   └── widgets/                       # مكونات UI reusable
│   ├── routes/
│   │   ├── app_pages.dart                 # تعريف صفحات GetX
│   │   └── app_routes.dart                # الثوابت المسارية
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_text_styles.dart
│   └── main.dart                          # نقطة الدخول
└── supabase/functions/                    # Edge Functions
    └── sync-app-user/                     # ربط Auth user مع app_user
```

### 2.2 الأنماط المعمارية

| النمط | التطبيق | الملفات |
|-------|---------|---------|
| **GetX Pattern** | إدارة الحالة والتنقل | جميع الـ Controllers |
| **Service Layer** | فصل طبقة البيانات | `services/*.dart` |
| **Model Pattern** | تمثيل البيانات | `models/*.dart` |
| **Repository Pattern (partial)** | تجميع استعلامات Supabase | `ParentSupabaseService` |

### 2.3 حقن الاعتمادات (Dependency Injection)

**موقع التسجيل:** `main.dart:42-51`
```dart
void _initParentServices() {
  Get.put<SupabaseService>(SupabaseService(), permanent: true);        // ①
  Get.put<ParentSupabaseService>(ParentSupabaseService(), permanent: true);  // ②
  Get.put<ParentAuthService>(ParentAuthService(), permanent: true);   // ③
}
```

**الترتيب الهرمي:**
1. `SupabaseService` → الـ Client الأساسي
2. `ParentSupabaseService` → يعتمد على ①
3. `ParentAuthService` → يعتمد على ① و ②

---

## 3. تدقيق الواجهات / الشاشات

### جدول الشاشات الكامل

| # | الشاشة | المسار (Route) | الـ Controller | حالة الاكتمال | مصدر البيانات |
|---|--------|---------------|----------------|---------------|---------------|
| 1 | `LoginView` | `/parent/login` | `AuthController` | ✅ مكتمل | Supabase Auth |
| 2 | `MainNavigationView` | `/parent/main-navigation` | متعدد | ✅ مكتمل | - |
| 3 | `DashboardView` | (فرعي) | `DashboardController` | ✅ مربوط | Supabase |
| 4 | `ReportsView` | `/parent/reports` | `ReportsController` | ✅ مربوط | Supabase |
| 5 | `ChildReportView` | `/parent/child-report` | - | ⚠️ جزئي | يعتمد على Arguments |
| 6 | `ChildTestDetailsView` | `/parent/child-test-details` | - | ⚠️ جزئي | يعتمد على Arguments |
| 7 | `CommunicationView` | `/parent/communication` | `CommunicationController` | ✅ مربوط | Supabase |
| 8 | `ChatView` | `/parent/chat` | - | ⚠️ جزئي | Supabase (messages) |
| 9 | `NotificationsView` | `/parent/notifications` | `NotificationController` | ✅ مربوط | Supabase |
| 10 | `ProfileView` | (فرعي) | `ProfileController` | ⚠️ أساسي | Local/Supabase |

### ملاحظات تفصيلية:

**LoginView** `@lib/modules/parent/views/login_view.dart`
- تستخدم `AuthController` للمصادقة
- دعم RTL كامل
- تحقق من Session موجودة في `onReady`

**DashboardView** `@lib/modules/parent/views/dashboard_view.dart:135`
```dart
// TODO: عرض الكل
```
- تحتوي على FloatingActionButton لإضافة طالب
- تدعم Pull-to-Refresh

**ChatView** `@lib/modules/parent/views/chat_view.dart:326`
```dart
// TODO: Handle error - maybe remove optimistic message or show error
```
- رسائل "Optimistic UI" (تظهر قبل تأكيد الإرسال)

---

## 4. تكامل البيانات والـ Backend

### 4.1 بنية Supabase

**الإعدادات:** `@lib/config/supabase_config.dart`
```dart
static const String supabaseUrl = 'https://omkjmtyaodsibyvsqtfo.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1Ni...';  // ⚠️ مكشوف
```

### 4.2 نقاط التكامل (Integration Points)

| الميزة | الجدول/الدالة | حالة الربط |
|--------|---------------|------------|
| **المصادقة** | `supabase.auth` | ✅ مربوط |
| **ربط المستخدم** | Edge Function `sync-app-user` | ✅ مربوط |
| **بيانات ولي الأمر** | `parents` | ✅ مربوط |
| **الأطفال** | `parent_students` + `students` | ✅ مربوط |
| **نتائج الاختبارات** | `exam_results` | ✅ مربوط |
| **الحضور** | `attendance` | ✅ مربوط |
| **الأنشطة** | `activities` | ✅ مربوط |
| **الملخصات اليومية** | `daily_summaries` | ✅ مربوط |
| **الرسائل** | `messages` | ✅ مربوط |
| **الإشعارات** | `notifications` | ✅ مربوط |

### 4.3 تدفق المصادقة (Authentication Flow)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────┐
│  LoginView  │────▶│ ParentAuth  │────▶│ Supabase Auth   │
│  (UI Input) │     │  Service    │     │ (email/password)│
└─────────────┘     └─────────────┘     └─────────────────┘
                                                │
                                                ▼
┌─────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Dashboard  │◀────│  Save to Storage│◀────│ Edge Function   │
│   (Home)    │     │ (app_entity_id) │     │ sync-app-user   │
└─────────────┘     └─────────────────┘     └─────────────────┘
```

### 4.4 طبقة الخدمات (Service Layer)

**الملف:** `@lib/modules/parent/services/parent_supabase_service.dart:447`

الوظائف الرئيسية:
- `loadCurrentParent()` - تحميل بيانات ولي الأمر
- `loadChildren()` - تحميل الأطفال المرتبطين
- `linkChildByStudentCode()` - ربط طفل جديد
- `loadChildExamResults()` - نتائج الاختبارات
- `loadChildAttendance()` - سجلات الحضور
- `loadActivitiesAsModels()` - الأنشطة مع فلترة
- `loadAttendanceAsModels()` - الحضور كـ Models
- `loadDailySummariesAsModels()` - الملخصات اليومية
- `loadMessages()` / `sendMessage()` - الرسائل
- `loadNotifications()` - الإشعارات

---

## 5. خريطة تدفق البيانات

### 5.1 تدفق تسجيل الدخول

```
المستخدم يدخل بياناته
        │
        ▼
┌──────────────────┐
│ AuthController   │
│ .login()         │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ ParentAuthService│
│ .signInWithEmail()│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌─────────────────┐
│ Supabase Auth    │────▶│  Edge Function  │
│ (JWT Token)      │     │  sync-app-user  │
└──────────────────┘     └────────┬────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    ▼                           ▼
            ┌──────────────┐          ┌──────────────┐
            │  app_entity_id │          │  user_type   │
            │   (int)        │          │  ('parent')  │
            └──────┬─────────┘          └──────────────┘
                   │
                   ▼
            ┌──────────────┐
            │  GetStorage  │  ◀── حفظ محلي للـ recovery
            │  (local)     │
            └──────────────┘
```

### 5.2 تحميل لوحة التحكم

```
DashboardController.onInit()
        │
        ▼
┌──────────────────────────────────────┐
│ loadData()                           │
│ ├─ loadCurrentParent()               │
│ ├─ loadChildren()                    │
│ │   └─ _enrichChildrenData()         │
│ │       └─ loadChildExamResults()    │
│ ├─ loadNotifications(unreadOnly: true) │
│ └─ loadMessages()                    │
└──────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────┐
│ UI تحديث (Obx)                       │
└──────────────────────────────────────┘
```

---

## 6. تحديد الفجوات والمخاطر

### 6.1 علامات TODO المكتشفة

| الملف | السطر | المهمة غير المكتملة |
|-------|-------|---------------------|
| `dashboard_view.dart:135` | 135 | "عرض الكل" للأطفال |
| `communication_view.dart:197` | 197 | تطبيق فلتر المواد |
| `chat_view.dart:326` | 326 | معالجة أخطاء إرسال الرسائل |
| `communication_controller.dart:45` | 45 | تحميل المعلمين من `section_subjects` |
| `score_chart.dart` | 75 | تحسين عرض الرسم البياني |

### 6.2 المخاطر والفجوات

| الخطر | الموقع | التأثير |
|-------|--------|---------|
| **مفاتيح Supabase مكشوفة** | `supabase_config.dart` | أمان - يمكن استخراج المفاتيح من APK |
| **لا يوجد معالجة أخطاء شبكة مركزية** | متفرق | فشل صامت عند انقطاع الإنترنت |
| **كود معلق (Commented) كثير** | جميع الملفات | صعوبة الصيانة والقراءة |
| **TODO في معالجة الأخطاء** | `chat_view.dart:326` | UX سيئة عند فشل الإرسال |
| **فلترة المعلمين غير مكتملة** | `communication_controller.dart:45` | لا يمكن إيجاد معلمين جدد |

### 6.3 الارتباطات الخطرة (Tight Coupling)

```dart
// @lib/modules/parent/controllers/dashboard_controller.dart:171
// طباعات调试 مباشرة في Console - لا يمكن إيقافها في الإنتاج
print('👤 parentData: $parentData');
print('👶 childrenData count: ${childrenData.length}');
```

---

## 7. لمحة الدين التقني (Technical Debt)

### 7.1 الكود الميت (Dead Code)

| الملف | الأسطر | الوصف |
|-------|--------|-------|
| `supabase_service.dart` | 1-75 | نسخة معلقة كاملة من الكود |
| `parent_supabase_service.dart` | 1-437 | نسخة معلقة كاملة من الكود |
| `parent_auth_service.dart` | 1-99 | نسخة معلقة كاملة من الكود |
| `auth_controller.dart` | 1-62 | نسخة معلقة كاملة من الكود |
| `dashboard_controller.dart` | 1-165 | نسخة معلقة كاملة من الكود |

### 7.2 البيانات المضمنة (Hardcoded)

| الموقع | القيمة | الاستخدام |
|--------|--------|-----------|
| `main.dart:62` | `Locale('ar', 'SA')` | اللغة العربية |
| `dashboard_view.dart:181` | `['أب', 'أم', 'وصي', 'أخ', 'أخت']` | علاقات الوالدية |
| `main_navigation_view.dart:53-58` | أسماء التبويب | التنقل السفلي |
| `login_view.dart:62` | `'Quiz Master'` | اسم التطبيق |

### 7.3 التبعيات الخارجية (Dependencies)

**الملف:** `@pubspec.yaml`

| الحزمة | النسخة | الاستخدام |
|--------|--------|-----------|
| `get` | ^4.6.6 | إدارة الحالة والتنقل |
| `supabase_flutter` | ^2.12.0 | Backend / Database |
| `get_storage` | ^2.1.1 | تخزين محلي بسيط |
| `sqflite` | ^2.4.2 | قاعدة بيانات محلية (SQLite) |
| `fl_chart` | ^0.65.0 | الرسوم البيانية |
| `cached_network_image` | ^3.3.1 | تحميل الصور |

---

## ملخص التقرير

### ✅ ما هو مكتمل ومربوط بالكامل
1. نظام المصادقة (Auth) مع Supabase
2. Edge Function `sync-app-user`
3. تحميل بيانات الأطفال من `parent_students`
4. عرض نتائج الاختبارات
5. نظام الحضور والغياب
6. قائمة الأنشطة والواجبات
7. نظام الإشعارات (قراءة/تحديث)
8. المحادثات مع المعلمين

### ⚠️ ما هو مربوط جزئيًا
1. `CommunicationController` - يحتاج تحميل المعلمين من `section_subjects`
2. `ChatView` - يحتاج معالجة أخطاء أفضل
3. `ProfileView` - وظائف أساسية فقط

### ❌ ما هو غير مربوط/غير مكتمل
1. فلترة المواد في شاشة التواصل
2. زر "عرض الكل" في قائمة الأطفال
3. معالجة مركزية لأخطاء الشبكة

---

**خاتمة:** التطبيق يستخدم بنية **GetX Pattern** مع **Supabase** كـ Backend. معظم الميزات الأساسية مربوطة بالكامل، لكن يوجد دين تقني يحتاج تنظيفًا (إزالة الكود المعلق) وتحسينات في معالجة الأخطاء.
