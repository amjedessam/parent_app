// modules/parent/models/subject_performance_model.dart

import 'package:flutter/material.dart';

/// أداء الطالب في مادة دراسية واحدة
/// مصدر البيانات: section_subjects + subjects + exam_results
class SubjectPerformanceModel {
  final int subjectId;
  final String subjectName;
  final String icon;         // emoji من حقل subjects.icon
  final String colorHex;    // لون من حقل subjects.color  (0xFFxxxxxx)
  final double averageScore; // AVG(percentage) من exam_results لهذه المادة
  final int totalExams;      // عدد الاختبارات المكتملة
  final double? lastScore;   // آخر percentage في المادة
  final String? lastExamTitle;
  final DateTime? lastExamDate;

  SubjectPerformanceModel({
    required this.subjectId,
    required this.subjectName,
    required this.icon,
    required this.colorHex,
    required this.averageScore,
    required this.totalExams,
    this.lastScore,
    this.lastExamTitle,
    this.lastExamDate,
  });

  // ─────────────────────────────────────────────────────────
  // COLOR HELPERS
  // ─────────────────────────────────────────────────────────

  /// يدعم: 0xFF6C63FF  |  #6C63FF  |  6C63FF
  Color get subjectColor {
    try {
      String hex = colorHex
          .replaceFirst('0x', '')
          .replaceFirst('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF6C63FF);
    }
  }

  Color get subjectColorLight => subjectColor.withOpacity(0.12);

  // ─────────────────────────────────────────────────────────
  // PERFORMANCE HELPERS
  // ─────────────────────────────────────────────────────────

  double get progressValue => (averageScore / 100).clamp(0.0, 1.0);

  bool get hasExams => totalExams > 0;

  String get performanceLabel {
    if (!hasExams) return 'لا يوجد اختبارات';
    if (averageScore >= 90) return 'ممتاز';
    if (averageScore >= 80) return 'جيد جداً';
    if (averageScore >= 70) return 'جيد';
    if (averageScore >= 60) return 'مقبول';
    return 'يحتاج تحسين';
  }

  Color get performanceColor {
    if (!hasExams) return const Color(0xFF94A3B8);
    if (averageScore >= 80) return const Color(0xFF22C55E);
    if (averageScore >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color get performanceBgColor {
    if (!hasExams) return const Color(0xFFF1F5F9);
    if (averageScore >= 80) return const Color(0xFFDCFCE7);
    if (averageScore >= 60) return const Color(0xFFFEF3C7);
    return const Color(0xFFFEE2E2);
  }
}
