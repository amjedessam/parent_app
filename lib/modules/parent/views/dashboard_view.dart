import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parent/theme/app_theme.dart';
import 'package:parent/modules/parent/controllers/dashboard_controller.dart';
// import 'package:parent/modules/parent/widgets/hero_header_card.dart';
import 'package:parent/modules/parent/widgets/statistic_card.dart';
import 'package:parent/modules/parent/controllers/navigation_controller.dart';
import 'package:parent/theme/parent_app_colors.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBFC),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: controller.loadData,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Welcome Header مع Gradient + Notification Bell
                SliverToBoxAdapter(child: _buildWelcomeHeader()),

                // Statistics Section
                SliverToBoxAdapter(child: _buildStatisticsSection()),

                // عنوان "أطفالي"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'أطفالي',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showLinkChildDialog(context),
                          icon: const Icon(Icons.person_add_rounded, size: 18),
                          label: const Text(
                            'إضافة طالب',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              62,
                              136,
                              221,
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // قائمة الأطفال (الآن SliverList صحيحة 100%)
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final child = controller.children[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: ModernChildCard(
                        child: child,
                        onTap: () => controller.goToChildReport(child),
                      ),
                    );
                  }, childCount: controller.children.length),
                ),

                // مسافة في الأسفل
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _showLinkChildDialog(BuildContext context) {
    final codeController = TextEditingController();
    String selectedRelationship = 'أب';
    const relationships = ['أب', 'أم', 'وصي', 'أخ', 'أخت'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // العنوان
                  const Text(
                    'إضافة طالب جديد',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'أدخل رمز الطالب الموجود في بطاقته المدرسية',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // حقل رمز الطالب
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      color: Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      labelText: 'رمز الطالب',
                      hintText: '10001',
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: AppColors.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // صلة القرابة
                  DropdownButtonFormField<String>(
                    value: selectedRelationship,
                    decoration: InputDecoration(
                      labelText: 'صلة القرابة',
                      prefixIcon: const Icon(
                        Icons.family_restroom_rounded,
                        color: AppColors.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    items: relationships
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedRelationship = v!),
                  ),
                  const SizedBox(height: 16),

                  // رسالة الخطأ
                  Obx(() {
                    final error = controller.linkError.value;
                    if (error == null) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // زر الإضافة
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: controller.isLinkingChild.value
                            ? null
                            : () {
                                final code = int.tryParse(
                                  codeController.text.trim(),
                                );
                                if (code == null) {
                                  controller.linkError.value =
                                      'أدخل رمزاً صحيحاً';
                                  return;
                                }
                                controller.linkNewChild(
                                  code,
                                  selectedRelationship,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: controller.isLinkingChild.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'إضافة الطالب',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      controller.linkError.value = null;
      codeController.dispose();
    });
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient, // تأكد إنك معرفها في AppColors
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // النصوص
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرحباً،',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    controller.parent.value?.name ?? 'ولي الأمر',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'تابع التقدم التعليمي لأطفالك',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          // جرس الإشعارات
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  size: 28,
                  color: Colors.white,
                ),
                onPressed: controller.openNotifications,
              ),
              Obx(() {
                final count = controller.unreadNotificationsCount.value;
                if (count == 0) return const SizedBox.shrink();

                return Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Row(
        children: [
          // كارت عدد الطلابh
          Expanded(
            child: StatisticCard(
              icon: Icons.people_rounded,
              title: 'عدد الطلاب',
              value: controller.totalChildren.toString(),
              color: const Color(0xFF3B82F6),
              onTap: () {
                // لو عايز تنقل لصفحة الطلاب
              },
            ),
          ),

          const SizedBox(width: 16),

          // كارت التقارير
          Expanded(
            child: StatisticCard(
              icon: Icons.assessment_rounded,
              title: 'التقارير',
              value: controller.totalReports.toString(),
              color: const Color(0xFF8B5CF6),
              onTap: () => Get.find<NavigationController>().switchTab(1),
            ),
          ),

          const SizedBox(width: 16),

          // كارت الرسائل الجديدة
          Expanded(
            child: StatisticCard(
              icon: Icons.mail_rounded,
              title: 'الرسائل ',
              value: controller.unreadMessages.toString(),
              color: const Color(0xFF06B6D4),
              onTap: () => Get.find<NavigationController>().switchTab(2),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class ModernChildCard extends StatelessWidget {
  final dynamic child; // ChildModel
  final VoidCallback onTap;

  const ModernChildCard({super.key, required this.child, required this.onTap});

  Color _getScoreColor(double score) {
    if (score >= 90) return const Color(0xFF22C55E);
    if (score >= 80) return const Color(0xFF3B82F6);
    if (score >= 70) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getScoreColor(child.averageScore),
                            _getScoreColor(child.averageScore).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _getScoreColor(
                              child.averageScore,
                            ).withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          child.name[0],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.school_rounded,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                child.grade,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Row(
                          //   children: [
                          //     Icon(
                          //       Icons.badge_outlined,
                          //       size: 14,
                          //       color: Colors.grey[600],
                          //     ),
                          //     const SizedBox(width: 6),
                          //     Text(
                          //       'رمز: ${child.studentCode}',
                          //       style: const TextStyle(
                          //         fontSize: 12,
                          //         color: Color(0xFF6B70F5),
                          //         fontWeight: FontWeight.w700,
                          //       ),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                    // Arrow
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B70F5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 14,
                        color: Color(0xFF6B70F5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Scores Row
                Row(
                  children: [
                    Expanded(
                      child: _ScoreMiniCard(
                        label: 'آخر درجة',
                        score: child.latestScore,
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ScoreMiniCard(
                        label: 'المعدل',
                        score: child.averageScore,
                        icon: Icons.bar_chart_rounded,
                      ),
                    ),
                  ],
                ),

                // Alerts (if any)
                if (child.recentAlerts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.info_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            child.recentAlerts.first,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreMiniCard extends StatelessWidget {
  final String label;
  final double score;
  final IconData icon;

  const _ScoreMiniCard({
    required this.label,
    required this.score,
    required this.icon,
  });

  Color _getScoreColor() {
    if (score >= 90) return const Color(0xFF22C55E);
    if (score >= 80) return const Color(0xFF3B82F6);
    if (score >= 70) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${score.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
