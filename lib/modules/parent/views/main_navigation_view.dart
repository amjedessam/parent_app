import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parent/modules/parent/controllers/navigation_controller.dart';
import 'package:parent/modules/parent/controllers/reports_controller.dart';
import 'package:parent/modules/parent/views/communication_view.dart';
import 'package:parent/modules/parent/views/dashboard_view.dart';
import 'package:parent/modules/parent/views/profile_view.dart';
import 'package:parent/modules/parent/views/reports_view.dart';
import 'package:parent/theme/app_theme.dart';
import 'package:parent/theme/parent_app_colors.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView>
    with SingleTickerProviderStateMixin {
  late final NavigationController _navController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<NavigationController>()) {
      Get.put(NavigationController());
    }
    _navController = Get.find<NavigationController>();

    if (!Get.isRegistered<ReportsController>()) {
      Get.put(ReportsController());
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  final _pages = [
    const DashboardView(),
    const ReportsView(),
    const CommunicationView(),
    const ProfileView(),
  ];

  final _navItems = [
    {'icon': Icons.home_rounded, 'label': 'الرئيسية'},
    {'icon': Icons.assessment_rounded, 'label': 'التقارير'},
    {'icon': Icons.chat_bubble_rounded, 'label': 'الرسائل'},
    {'icon': Icons.person_rounded, 'label': ' الشخصي'},
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Obx(
        () => Scaffold(
          body: IndexedStack(
            index: _navController.currentIndex.value,
            children: _pages,
          ),
          extendBody: true,
          bottomNavigationBar: Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.transparent.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                height: 70,
                // padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    _navItems.length,
                    (index) => _buildFloatingNavItem(
                      index: index,
                      icon: _navItems[index]['icon'] as IconData,
                      label: _navItems[index]['label'] as String,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _navController.currentIndex.value == index;
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) {
          _animationController.reverse();
          _navController.switchTab(index);
        },
        onTapCancel: () => _animationController.reverse(),
        child: ScaleTransition(
          scale: isSelected ? _scaleAnimation : const AlwaysStoppedAnimation(1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppColors.textLight,
                    size: isSelected ? 28 : 24,
                  ),
                ),
                // const SizedBox(height: 1),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: isSelected ? 11 : 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textLight,
                    letterSpacing: -0.2,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
