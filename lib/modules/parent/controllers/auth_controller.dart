import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:parent/routes/app_routes.dart';
import 'package:parent/modules/parent/services/parent_auth_service.dart';
import 'package:parent/modules/parent/services/supabase_service.dart';
import 'package:parent/core/utils/helpers.dart';

class AuthController extends GetxController {
  final ParentAuthService _authService = Get.find<ParentAuthService>();
  final SupabaseService _supabase = Get.find<SupabaseService>();

  final isLoading = false.obs;
  final isLoggedIn = false.obs;

  @override
  void onReady() {
    super.onReady();
  }

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      Helpers.showErrorSnackbar('الرجاء إدخال البريد وكلمة المرور');
      return;
    }

    isLoading.value = true;

    try {
      final success = await _authService.signInWithEmail(
        email.trim(),
        password,
      );

      if (success) {
        isLoggedIn.value = true;
        Helpers.showSuccessSnackbar('تم تسجيل الدخول بنجاح');
        Get.offAllNamed(AppRoutes.PARENT_MAIN_NAVIGATION);
      } else {
        final errorMsg = _authService.errorMessage.value.isNotEmpty
            ? _authService.errorMessage.value
            : 'فشل تسجيل الدخول. تحقق من البيانات';
        Helpers.showErrorSnackbar(errorMsg);
      }
    } catch (e) {
      print('❌ Login error: $e');
      Helpers.showErrorSnackbar('حدث خطأ أثناء تسجيل الدخول');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();

      final storage = GetStorage();
      await storage.remove('user_role');
      await storage.remove('app_entity_id');
      await storage.remove('user_type');

      isLoggedIn.value = false;
      Helpers.showSuccessSnackbar('تم تسجيل الخروج بنجاح');
      Get.offAllNamed(AppRoutes.PARENT_LOGIN);
    } catch (e) {
      print('❌ Logout error: $e');
    }
  }
}
