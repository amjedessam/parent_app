import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parent/theme/app_theme.dart';
import 'package:parent/routes/app_routes.dart';
import 'package:parent/theme/parent_app_colors.dart';
import '../controllers/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // ── خلفية متدرجة ───────────────────────────────
            Container(
              height: size.height * 0.38,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.gradientStart, AppColors.primaryLight],
                ),
              ),
            ),

            // ── الجزء السفلي ───────────────────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: size.height * 0.66,
                color: const Color(0xFFF5F7FA),
              ),
            ),

            // ── موجة فاصلة ─────────────────────────────────
            Positioned(
              top: size.height * 0.30,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: _WaveClipper(),
                child: Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [AppColors.gradientStart, AppColors.primaryLight],
                    ),
                  ),
                ),
              ),
            ),

            // ── دوائر زخرفية ───────────────────────────────
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // ── المحتوى ────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // ── الشعار ─────────────────────────
                      _buildLogo(),
                      const SizedBox(height: 14),

                      // ── العنوان ─────────────────────────
                      const Text(
                        'إنشاء حساب جديد',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'بوابة ولي الأمر',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ── كارد النموذج ────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0D6EBD,
                                ).withOpacity(0.12),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // عنوان الكارد
                              const Text(
                                'بيانات الحساب',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A2B4A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'أدخل بياناتك لإنشاء حسابك',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── رسالة الخطأ ───────────────
                              Obx(() {
                                if (controller.errorMessage.value.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          controller.errorMessage.value,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              // ── الاسم الكامل ──────────────
                              _buildLabel('الاسم الكامل', required: true),
                              _buildStyledField(
                                child: TextFormField(
                                  controller: controller.fullNameController,
                                  validator: controller.validateFullName,
                                  decoration: _inputDecoration(
                                    hint: 'محمد علي',
                                    icon: Icons.person_outline_rounded,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // ── رقم الهاتف ────────────────
                              _buildLabel('رقم الهاتف', required: true),
                              _buildStyledField(
                                child: TextFormField(
                                  controller: controller.phoneController,
                                  validator: controller.validatePhone,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputDecoration(
                                    hint: '05XXXXXXXX',
                                    icon: Icons.phone_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // ── البريد الإلكتروني ──────────
                              _buildLabel('البريد الإلكتروني', required: true),
                              _buildStyledField(
                                child: TextFormField(
                                  controller: controller.emailController,
                                  validator: controller.validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  textDirection: TextDirection.ltr,
                                  decoration: _inputDecoration(
                                    hint: 'example@email.com',
                                    icon: Icons.email_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // ── كلمة المرور ───────────────
                              _buildLabel('كلمة المرور', required: true),
                              _buildStyledField(
                                child: Obx(
                                  () => TextFormField(
                                    controller: controller.passwordController,
                                    validator: controller.validatePassword,
                                    obscureText:
                                        controller.obscurePassword.value,
                                    decoration:
                                        _inputDecoration(
                                          hint: '6 أحرف على الأقل',
                                          icon: Icons.lock_outline_rounded,
                                        ).copyWith(
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              controller.obscurePassword.value
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                              color: const Color(0xFF0D6EBD),
                                              size: 20,
                                            ),
                                            onPressed:
                                                controller.togglePassword,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // ── تأكيد كلمة المرور ─────────
                              _buildLabel('تأكيد كلمة المرور', required: true),
                              _buildStyledField(
                                child: Obx(
                                  () => TextFormField(
                                    controller: controller.confirmController,
                                    validator: controller.validateConfirm,
                                    obscureText:
                                        controller.obscureConfirm.value,
                                    decoration:
                                        _inputDecoration(
                                          hint: 'أعد إدخال كلمة المرور',
                                          icon: Icons.lock_outline_rounded,
                                        ).copyWith(
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              controller.obscureConfirm.value
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                              color: const Color(0xFF0D6EBD),
                                              size: 20,
                                            ),
                                            onPressed: controller.toggleConfirm,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // ── رمز الطالب ────────────────
                              _buildLabel('رمز الطالب', required: true),
                              _buildStyledField(
                                child: TextFormField(
                                  controller: controller.studentCodeController,
                                  validator: controller.validateStudentCode,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4,
                                    color: Color(0xFF1A2B4A),
                                  ),
                                  decoration: _inputDecoration(
                                    hint: '10001',
                                    icon: Icons.badge_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 13,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'الرمز موجود في بطاقة الطالب المدرسية',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // ── صلة القرابة ───────────────
                              _buildLabel('صلة القرابة'),
                              _buildStyledField(
                                child: Obx(
                                  () => DropdownButtonFormField<String>(
                                    value:
                                        controller.selectedRelationship.value,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFF0D6EBD),
                                    ),
                                    items: controller.relationships
                                        .map(
                                          (r) => DropdownMenuItem(
                                            value: r,
                                            child: Text(
                                              r,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        controller.selectedRelationship.value =
                                            v;
                                      }
                                    },
                                    decoration: _inputDecoration(
                                      hint: 'اختر صلة القرابة',
                                      icon: Icons.family_restroom_rounded,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 26),

                              // ── زر إنشاء الحساب ───────────
                              Obx(
                                () => _buildRegisterButton(
                                  isLoading: controller.isLoading.value,
                                  onTap: controller.isLoading.value
                                      ? null
                                      : controller.register,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── رابط تسجيل الدخول ───────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'لديك حساب بالفعل؟',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Get.offNamed(AppRoutes.PARENT_LOGIN),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: const Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                color: Color(0xFF0D6EBD),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Text(
                        'منصة رُشد التعليمية الذكية© 2026',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── الشعار ───────────────────────────────────────────────
  Widget _buildLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.12),
          ),
        ),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Image.asset(
                'assets/images/roshd.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── تسمية الحقل ──────────────────────────────────────────
  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B4A),
            ),
          ),
          if (required) ...[
            const SizedBox(width: 3),
            const Text(
              '',
              style: TextStyle(color: Color(0xFF0D6EBD), fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  // ── غلاف حقل الإدخال ─────────────────────────────────────
  Widget _buildStyledField({required Widget child}) {
    return child;
  }

  // ── ديكور حقول الإدخال ───────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF0D6EBD), size: 20),
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8ECF0), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8ECF0), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0D6EBD), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
    );
  }

  // ── زر إنشاء الحساب ──────────────────────────────────────
  Widget _buildRegisterButton({
    required bool isLoading,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.primaryLight],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D6EBD).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'إنشاء الحساب',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.person_add_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── موجة فاصلة ───────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(size.width * 0.75, 0, size.width, size.height * 0.5);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
