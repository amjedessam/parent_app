import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:parent/routes/app_pages.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:parent/theme/app_theme.dart';
import 'package:parent/modules/parent/services/supabase_service.dart';
import 'package:parent/modules/parent/services/parent_supabase_service.dart';
import 'package:parent/modules/parent/services/parent_auth_service.dart';
import 'package:parent/modules/parent/controllers/auth_controller.dart';
import 'package:parent/routes/app_routes.dart';
import 'package:parent/config/supabase_config.dart';
import 'package:parent/core/services/push_notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await GetStorage.init();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    debug: SupabaseConfig.enableLogging,
  );

  _initParentServices();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ParentApp());
}

void _initParentServices() {
  // ① الأساس — يجب أن يكون أولاً
  Get.put<SupabaseService>(SupabaseService(), permanent: true);

  // ② يعتمد على SupabaseService
  Get.put<ParentSupabaseService>(ParentSupabaseService(), permanent: true);

  // ③ يعتمد على SupabaseService و ParentSupabaseService
  Get.put<ParentAuthService>(ParentAuthService(), permanent: true);

  // ④ Push Notifications (Firebase + token registration)
  Get.put<PushNotificationsService>(PushNotificationsService(), permanent: true);
  // Fire-and-forget init (mobile only internally)
  Get.find<PushNotificationsService>().init();

  // ④ يحتاج للـ Services السابقة - مهم للتحقق من حالة الدخول عند البداية
  Get.put<AuthController>(AuthController(), permanent: true);
}

class ParentApp extends StatelessWidget {
  const ParentApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Parent - ولي الأمر',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('ar', 'SA'),
      fallbackLocale: const Locale('ar', 'SA'),
      initialRoute: AppRoutes.SPLASH,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      unknownRoute: GetPage(
        name: '/not-found',
        page: () =>
            const Scaffold(body: Center(child: Text('الصفحة غير موجودة'))),
      ),
    );
  }
}
