import 'package:get/get.dart';
import 'package:parent/routes/app_routes.dart';
import '../models/admin_model.dart';
import '../services/parent_supabase_service.dart';

/// CommunicationController — MIGRATED TO ADMIN ✅
/// 
/// يدير التواصل بين ولي الأمر والإدارة (Admin)
/// تم التعديل من التواصل مع المعلمين
class CommunicationController extends GetxController {
  final ParentSupabaseService _supabaseService =
      Get.find<ParentSupabaseService>();

  final isLoading = true.obs;
  final admins = <AdminModel>[].obs;
  final errorMessage = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    loadAdmins();
  }

  /// تحميل قائمة الإداريين من Supabase
  Future<void> loadAdmins() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      // تحميل الإداريين من قاعدة البيانات
      final adminsData = await _supabaseService.loadAdmins();
      
      print('📊 CommunicationController: ${adminsData.length} admins loaded');
      
      if (adminsData.isEmpty) {
        errorMessage.value = 'لا يوجد إداريين متاحين. قد تحتاج لإضافة RLS Policy في Supabase.';
      }
      
      final adminList = <AdminModel>[];
      for (final adminData in adminsData) {
        adminList.add(AdminModel.fromJson(adminData));
      }

      admins.value = adminList;
    } catch (e) {
      print('❌ Error loading admins: $e');
      errorMessage.value = 'فشل تحميل قائمة الإداريين: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void openChat(AdminModel admin) {
    Get.toNamed(AppRoutes.PARENT_CHAT, arguments: admin);
  }
}
