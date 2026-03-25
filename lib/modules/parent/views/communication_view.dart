import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:parent/theme/app_theme.dart';
import 'package:parent/theme/parent_app_colors.dart';
import '../controllers/communication_controller.dart';
import '../widgets/admin_card.dart';

class CommunicationView extends GetView<CommunicationController> {
  const CommunicationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          child: Obx(() {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: ClipPath(
                    clipper: _CurvedBottomClipper(),
                    child: Container(
                      height: 180,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            parentappcolors.primary,
                            parentappcolors.primaryDark,
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // ── أيقونة الجرس ──────────────
                              // Container(
                              //   width: 42,
                              //   height: 42,
                              //   decoration: BoxDecoration(
                              //     color: Colors.white.withOpacity(0.2),
                              //     borderRadius: BorderRadius.circular(12),
                              //   ),
                              //   child: const Icon(
                              //     Icons.notifications_outlined,
                              //     color: Colors.white,
                              //     size: 22,
                              //   ),
                              // ),
                              // ── العنوان والوصف ────────────
                              Center(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'تواصل',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'تواصل مع إدارة المدرسة',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ══════════════════════════════════════════════
                //  BODY CONTENT
                // ══════════════════════════════════════════════
                if (controller.isLoading.value)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (controller.admins.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else ...[
                  // ── عنوان القسم ────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            // child: const Icon(
                            //   Icons.admin_panel_settings_outlined,
                            //   color: AppColors.primary,
                            //   size: 18,
                            // ),
                          ),
                          // const SizedBox(width: 10),
                          // const Text(
                          //   'الإداريون المتاحون',
                          //   style: TextStyle(
                          //     fontFamily: 'Cairo',
                          //     fontSize: 16,
                          //     fontWeight: FontWeight.w700,
                          //     color: AppColors.textDark,
                          //   ),
                          // ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryBorder,
                              ),
                            ),
                            child: Text(
                              '${controller.admins.length} إداري',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── قائمة الإداريين ─────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final admin = controller.admins[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AdminCard(
                            admin: admin,
                            onTap: () => controller.openChat(admin),
                          ),
                        );
                      }, childCount: controller.admins.length),
                    ),
                  ),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Center(
                // child: Icon(
                //   Icons.admin_panel_settings_outlined,
                //   size: 42,
                //   color: AppColors.primary,
                // ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'لا يوجد إداريون متاحون',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'لا يوجد إداريون متاحون للتواصل حالياً',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Curved Bottom Clipper ─────────────────────────────────────
class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_CurvedBottomClipper oldClipper) => false;
}
