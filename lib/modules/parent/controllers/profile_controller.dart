import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/parent_model.dart';
import '../models/child_model.dart';
import '../services/parent_supabase_service.dart';
import 'auth_controller.dart';

class ProfileController extends GetxController {
  final isDarkMode = false.obs;
  final ParentSupabaseService _supabaseService =
      Get.find<ParentSupabaseService>();
  final parent = Rxn<ParentModel>();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final parentData = await _supabaseService.loadCurrentParent();
      if (parentData != null) {
        // تحميل بيانات الأطفال (الطلاب)
        final childrenData = await _supabaseService.loadChildren();
        final children = childrenData
            .map((child) => ChildModel.fromJson(child))
            .toList();

        parent.value = ParentModel.fromJson(parentData, children: children);
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      Get.snackbar('خطأ', 'فشل تحميل الملف الشخصي');
    }
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  void logout() {
    Get.find<AuthController>().logout();
  }
}
