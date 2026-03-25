import 'package:get/get.dart';

// Parent controllers
import 'package:parent/modules/parent/controllers/auth_controller.dart';
import 'package:parent/modules/parent/controllers/dashboard_controller.dart';
import 'package:parent/modules/parent/controllers/notification_controller.dart';
import 'package:parent/modules/parent/controllers/communication_controller.dart';
import 'package:parent/modules/parent/controllers/reports_controller.dart';
import 'package:parent/modules/parent/controllers/profile_controller.dart';
import 'package:parent/modules/parent/controllers/register_controller.dart'; // ✅ جديد
import 'package:parent/modules/parent/views/report_detail_view.dart';

// Parent views
import 'package:parent/modules/parent/views/splash_view.dart';
import 'package:parent/modules/parent/views/login_view.dart';
import 'package:parent/modules/parent/views/register_view.dart'; // ✅ جديد
import 'package:parent/modules/parent/views/main_navigation_view.dart';
import 'package:parent/modules/parent/views/chat_view.dart';
import 'package:parent/modules/parent/views/child_report_view.dart';
import 'package:parent/modules/parent/views/child_test_details_view.dart';
import 'package:parent/modules/parent/views/notifications_view.dart';
import 'package:parent/modules/parent/views/reports_view.dart';
import 'package:parent/modules/parent/views/communication_view.dart';
import 'package:parent/modules/parent/views/onboarding_screen.dart';

import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.SPLASH;

  static final pages = [
    // Splash
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),

    // Onboarding
    GetPage(
      name: AppRoutes.PARENT_ONBOARDING,
      page: () => const OnboardingScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),

    // Login
    GetPage(
      name: AppRoutes.PARENT_LOGIN,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AuthController());
      }),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 400),
    ),

    // ✅ Register — شاشة التسجيل الجديدة
    GetPage(
      name: AppRoutes.PARENT_REGISTER,
      page: () => const RegisterView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => RegisterController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
    ),

    // Main Navigation
    GetPage(
      name: AppRoutes.PARENT_MAIN_NAVIGATION,
      page: () => const MainNavigationView(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthController>()) {
          Get.put(AuthController(), permanent: true);
        }
        Get.lazyPut(() => DashboardController());
        Get.lazyPut(() => NotificationController(), fenix: true);
        Get.lazyPut(() => CommunicationController());
        Get.lazyPut(() => ReportsController());
        Get.lazyPut(() => ProfileController());
      }),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 400),
    ),

    // Reports
    GetPage(name: AppRoutes.PARENT_REPORTS, page: () => const ReportsView()),

    // Child report detail
    GetPage(
      name: AppRoutes.PARENT_CHILD_REPORT,
      page: () => const ChildReportView(),
    ),

    // Child test details
    GetPage(
      name: AppRoutes.PARENT_CHILD_TEST_DETAILS,
      page: () => const ChildTestDetailsView(),
    ),

    // Chat
    GetPage(name: AppRoutes.PARENT_CHAT, page: () => const ChatView()),

    // Notifications
    GetPage(
      name: AppRoutes.PARENT_NOTIFICATIONS,
      page: () => const NotificationsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => NotificationController(), fenix: true);
      }),
    ),
    GetPage(
      name: AppRoutes.PARENT_REPORT_DETAIL,
      page: () => ReportDetailView(notification: Get.arguments),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    // Communication
    GetPage(
      name: AppRoutes.PARENT_COMMUNICATION,
      page: () => const CommunicationView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CommunicationController());
      }),
    ),
  ];
}
