import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:parent/modules/parent/services/supabase_service.dart';
import 'package:parent/modules/parent/services/parent_auth_service.dart';
import 'package:parent/routes/app_routes.dart';

class RegisterController extends GetxController {
  final SupabaseService _supabase = Get.find<SupabaseService>();

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final studentCodeController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirm = true.obs;
  final selectedRelationship = 'أب'.obs;
  final errorMessage = ''.obs;

  // اسم الطالب بعد التحقق من الكود
  final studentName = ''.obs;

  final relationships = ['أب', 'أم', 'وصي', 'أخ', 'أخت'];

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    studentCodeController.dispose();
    super.onClose();
  }

  void togglePassword() => obscurePassword.value = !obscurePassword.value;
  void toggleConfirm() => obscureConfirm.value = !obscureConfirm.value;

  // ── Validators ────────────────────────────────────────────────
  String? validateFullName(String? v) {
    if (v == null || v.trim().isEmpty) return 'الاسم مطلوب';
    if (v.trim().length < 3) return 'الاسم قصير جداً';
    return null;
  }

  String? validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'رقم الهاتف مطلوب';
    return null;
  }

  String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
    if (!GetUtils.isEmail(v.trim())) return 'بريد إلكتروني غير صحيح';
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
    if (v.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  String? validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'تأكيد كلمة المرور مطلوب';
    if (v != passwordController.text) return 'كلمتا المرور غير متطابقتان';
    return null;
  }

  String? validateStudentCode(String? v) {
    if (v == null || v.trim().isEmpty) return 'رمز الطالب مطلوب';
    if (int.tryParse(v.trim()) == null) return 'رمز الطالب يجب أن يكون رقماً';
    return null;
  }

  // ── Register ──────────────────────────────────────────────────
  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final studentCode = int.parse(studentCodeController.text.trim());

      // ── الخطوة 1: استدعاء RPC register_parent_self ────────────
      // تُدرج في parents + parent_students وتتحقق من student_code
      final result = await _supabase.client.rpc(
        'register_parent_self',
        params: {
          'p_full_name': fullNameController.text.trim(),
          'p_phone': phoneController.text.trim(),
          'p_email': emailController.text.trim().toLowerCase(),
          'p_student_code': studentCode,
          'p_relationship': selectedRelationship.value,
        },
      );

      if (result == null) throw Exception('فشل إنشاء الحساب');

      final studentNameResult = result['student_name']?.toString() ?? '';
      studentName.value = studentNameResult;

      // ── الخطوة 2: إنشاء حساب في Supabase Auth ─────────────────
      final authResponse = await _supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        data: {'email_confirm': false},
      );

      if (authResponse.user == null) {
        throw Exception('فشل إنشاء حساب المصادقة');
      }

      // ── الخطوة 3: تسجيل الدخول مباشرة بعد التسجيل ────────────
      final authService = Get.find<ParentAuthService>();
      final success = await authService.signInWithEmail(
        emailController.text.trim(),
        passwordController.text,
      );

      if (success) {
        Get.snackbar(
          'مرحباً! 🎉',
          'تم إنشاء حسابك وربطه بالطالب $studentNameResult',
          backgroundColor: const Color(0xFF22C55E),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
        Get.offAllNamed(AppRoutes.PARENT_MAIN_NAVIGATION);
      } else {
        // نجح التسجيل لكن فشل الدخول — وجّه للـ login
        Get.offAllNamed(AppRoutes.PARENT_LOGIN);
        Get.snackbar(
          'تم التسجيل ✅',
          'يمكنك الآن تسجيل الدخول',
          backgroundColor: const Color(0xFF3B82F6),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } on AuthException catch (e) {
      errorMessage.value = _mapAuthError(e.message);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('لا يوجد طالب')) {
        errorMessage.value =
            'رمز الطالب غير صحيح — تحقق من الرمز وحاول مرة أخرى';
      } else if (msg.contains('مسجل بالفعل')) {
        errorMessage.value =
            'هذا البريد الإلكتروني مسجل بالفعل — يمكنك تسجيل الدخول';
      } else {
        errorMessage.value = 'حدث خطأ: $msg';
      }
    } finally {
      isLoading.value = false;
    }
  }

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('already registered') ||
        msg.contains('already been registered')) {
      return 'هذا البريد الإلكتروني مسجل بالفعل';
    }
    if (msg.contains('invalid email')) return 'البريد الإلكتروني غير صحيح';
    if (msg.contains('weak password')) return 'كلمة المرور ضعيفة جداً';
    return message;
  }
}
