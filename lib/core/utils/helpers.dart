import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parent/theme/parent_app_colors.dart';

class Helpers {
  static void showSuccessSnackbar(String message) {
    Get.snackbar(
      'نجح',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: parentappcolors.success,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  static void showErrorSnackbar(String message) {
    Get.snackbar(
      'خطأ',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: parentappcolors.error,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  static void showWarningSnackbar(String message) {
    Get.snackbar(
      'تحذير',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: parentappcolors.warning,
      colorText: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.white),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  static Color getScoreColor(double percentage) {
    if (percentage >= 90) return parentappcolors.success;
    if (percentage >= 70) return parentappcolors.primary;
    if (percentage >= 50) return parentappcolors.warning;
    return parentappcolors.error;
  }

  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  static String getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'سهل';
      case 'medium':
        return 'متوسط';
      case 'hard':
        return 'صعب';
      default:
        return 'متنوع';
    }
  }

  static Color getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return parentappcolors.easyColor;
      case 'medium':
        return parentappcolors.mediumColor;
      case 'hard':
        return parentappcolors.hardColor;
      default:
        return parentappcolors.primary;
    }
  }
}
