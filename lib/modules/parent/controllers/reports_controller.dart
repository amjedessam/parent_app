import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parent/modules/parent/models/activity_model.dart';
import 'package:parent/modules/parent/models/attendance_model.dart';
import 'package:parent/modules/parent/models/daily_summary_model.dart';
import 'package:parent/modules/parent/models/weekly_summary_model.dart';
import 'package:parent/modules/parent/services/parent_supabase_service.dart';

class ReportsController extends GetxController {
  final ParentSupabaseService _supabaseService =
      Get.find<ParentSupabaseService>();

  // ═══════════════════════════════════════════════════════════
  // STATE VARIABLES
  // ═══════════════════════════════════════════════════════════

  // Loading states
  final isLoadingActivities = true.obs;
  final isLoadingAttendance = true.obs;
  final isLoadingSummaries = true.obs;

  // Error states
  final errorActivities = Rxn<String>();
  final errorAttendance = Rxn<String>();
  final errorSummaries = Rxn<String>();

  // Activities data
  final activities = <ActivityModel>[].obs;
  final weeklySummary = Rxn<WeeklySummaryModel>();

  // Attendance data
  final attendanceRecords = <AttendanceModel>[].obs;
  final selectedMonth = DateTime.now().obs;

  // Daily summaries data
  final dailySummaries = <DailySummaryModel>[].obs;
  final selectedDate = DateTime.now().obs;
  final selectedChildIdForSummary = Rxn<int>(); // null = all children

  // Filter states
  final selectedChildIdForActivities = Rxn<int>(); // null = all children
  final activityFilter = ActivityFilter.all.obs;

  List<ActivityModel> get filteredActivities {
    var filtered = activities.toList();

    // Filter by child
    if (selectedChildIdForActivities.value != null) {
      filtered = filtered
          .where((a) => a.childId == selectedChildIdForActivities.value)
          .toList();
    }

    // Filter by status
    switch (activityFilter.value) {
      case ActivityFilter.pending:
        filtered = filtered
            .where((a) => a.status == ActivityStatus.pending)
            .toList();
        break;
      case ActivityFilter.overdue:
        filtered = filtered.where((a) => a.isOverdue).toList();
        break;
      case ActivityFilter.completed:
        filtered = filtered
            .where((a) => a.status == ActivityStatus.completed)
            .toList();
        break;
      case ActivityFilter.today:
        // ✅ اليوم: يعرض فقط غير المكتملة من اليوم
        filtered = filtered
            .where((a) => a.isDueToday && a.status != ActivityStatus.completed)
            .toList();
        break;
      case ActivityFilter.all:
        // ✅ الكل: يستثني المكتملة — المكتملة تظهر فقط في فلتر "المكتملة"
        filtered = filtered
            .where((a) => a.status != ActivityStatus.completed)
            .toList();
        break;
    }

    // Sort: المعلق الجديد أولاً ← ثم المتأخر ← ثم الأولوية ← ثم التاريخ
    filtered.sort((a, b) {
      // ✅ المعلق (الجديد من المعلم) يأتي أولاً
      final aIsPending = a.status == ActivityStatus.pending && !a.isOverdue;
      final bIsPending = b.status == ActivityStatus.pending && !b.isOverdue;

      if (aIsPending && !bIsPending) return -1;
      if (!aIsPending && bIsPending) return 1;

      // ثم المتأخر
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;

      // ثم الأولوية الأعلى
      final priorityCompare = (b.priority ?? 0).compareTo(a.priority ?? 0);
      if (priorityCompare != 0) return priorityCompare;

      // ثم الأحدث تاريخاً (تنازلي)
      return b.dueDate.compareTo(a.dueDate);
    });

    return filtered;
  }

  /// الأنشطة المتأخرة
  List<ActivityModel> get overdueActivities {
    return activities.where((a) => a.isOverdue).toList();
  }

  /// الأنشطة المعلقة
  List<ActivityModel> get pendingActivities {
    return activities.where((a) => a.status == ActivityStatus.pending).toList();
  }

  /// متوسط نسبة الحضور لجميع الأطفال
  double get averageAttendancePercentage {
    if (attendanceRecords.isEmpty) return 0;
    final sum = attendanceRecords
        .map((a) => a.attendancePercentage)
        .reduce((a, b) => a + b);
    return sum / attendanceRecords.length;
  }

  // ═══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════@override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  /// تحميل كل البيانات
  Future<void> loadAllData() async {
    await Future.wait([
      loadActivities(),
      loadAttendance(),
      loadDailySummaries(),
    ]);
  }

  // ═══════════════════════════════════════════════════════════
  // ACTIVITIES METHODS - SUPABASE MIGRATED ✅
  // ═══════════════════════════════════════════════════════════
  Future<void> loadActivities() async {
    try {
      isLoadingActivities.value = true;
      errorActivities.value = null;

      final List<ActivityModel> result;

      if (selectedChildIdForActivities.value != null) {
        // Load activities for specific child from Supabase
        result = await _supabaseService.loadActivitiesAsModels(
          selectedChildIdForActivities.value!,
        );
      } else {
        // Load activities for all children
        final children = await _supabaseService.loadChildren();
        result = [];

        for (final child in children) {
          final studentId = child['student_id'] as int?;
          if (studentId == null) continue;

          final childActivities = await _supabaseService.loadActivitiesAsModels(
            studentId,
          );
          result.addAll(childActivities);
        }
      }

      activities.value = result;

      // Compute weekly summary from Supabase data
      _computeWeeklySummary();
    } catch (e) {
      print('❌ Error loading activities: $e');
      errorActivities.value = 'فشل تحميل الأنشطة. اسحب للتحديث.';

      // ✅ في حالة الخطأ، تأكد من أن القوائم فارغة وليست null
      activities.value = [];
      weeklySummary.value = null;
    } finally {
      isLoadingActivities.value = false;
    }
  }

  /// Compute weekly summary from Supabase activities data
  void _computeWeeklySummary() {
    // ✅ إضافة check للقائمة الفارغة
    if (activities.isEmpty) {
      weeklySummary.value = null;
      return;
    }

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final weekActivities = activities.where((a) {
      return a.dueDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          a.dueDate.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();

    // ✅ إذا لم يكن هناك أنشطة هذا الأسبوع
    if (weekActivities.isEmpty) {
      weeklySummary.value = null;
      return;
    }

    // Group by child
    final activitiesPerChild = <int, int>{};
    for (final activity in weekActivities) {
      activitiesPerChild[activity.childId] =
          (activitiesPerChild[activity.childId] ?? 0) + 1;
    }

    weeklySummary.value = WeeklySummaryModel(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalActivities: weekActivities.length,
      completedActivities: weekActivities
          .where((a) => a.status == ActivityStatus.completed)
          .length,
      pendingActivities: weekActivities
          .where((a) => a.status == ActivityStatus.pending)
          .length,
      missedActivities: weekActivities
          .where((a) => a.status == ActivityStatus.missing)
          .length,
      activitiesPerChild: activitiesPerChild,
    );
  }

  void setActivityFilter(ActivityFilter filter) {
    activityFilter.value = filter;
  }

  void setChildFilterForActivities(int? childId) {
    selectedChildIdForActivities.value = childId;
    loadActivities();
  }

  /// تحديث حالة النشاط إلى مكتمل
  Future<void> markActivityAsCompleted(int activityId) async {
    try {
      // ✅ تحديث فوري في الواجهة (Optimistic Update)
      final index = activities.indexWhere((a) => a.id == activityId);
      if (index == -1) return;

      // تحديث في Supabase
      await _supabaseService.updateActivityStatus(activityId, 'completed');

      // إعادة تحميل البيانات للتأكد من التزامن
      await loadActivities();

      Get.snackbar(
        '✅ تم',
        'تم تحديد التقرير كمكتمل',
        backgroundColor: const Color(0xFF22C55E).withOpacity(0.95),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
      );
    } catch (e) {
      print('❌ Error marking activity as completed: $e');
      Get.snackbar(
        'خطأ',
        'فشل تحديث حالة التقرير، حاول مجدداً',
        backgroundColor: const Color(0xFFEF4444).withOpacity(0.95),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ATTENDANCE METHODS - SUPABASE MIGRATED ✅
  // ═══════════════════════════════════════════════════════════

  Future<void> loadAttendance() async {
    try {
      isLoadingAttendance.value = true;
      errorAttendance.value = null;

      final data = await _supabaseService.loadAttendanceAsModels(
        month: selectedMonth.value,
        studentId: selectedChildIdForActivities.value,
      );
      attendanceRecords.value = data;
    } catch (e) {
      print('❌ Error loading attendance: $e');
      errorAttendance.value = 'فشل تحميل بيانات الحضور. اسحب للتحديث.';
      attendanceRecords.value = []; // ✅ تأكد من القائمة الفارغة
    } finally {
      isLoadingAttendance.value = false;
    }
  }

  void changeMonth(DateTime newMonth) {
    selectedMonth.value = newMonth;
    loadAttendance();
  }

  void previousMonth() {
    final current = selectedMonth.value;
    selectedMonth.value = DateTime(current.year, current.month - 1);
    loadAttendance();
  }

  void nextMonth() {
    final current = selectedMonth.value;
    selectedMonth.value = DateTime(current.year, current.month + 1);
    loadAttendance();
  }

  // ═══════════════════════════════════════════════════════════
  // DAILY SUMMARIES METHODS - SUPABASE MIGRATED ✅
  // ═══════════════════════════════════════════════════════════

  Future<void> loadDailySummaries() async {
    try {
      isLoadingSummaries.value = true;
      errorSummaries.value = null;

      if (selectedChildIdForSummary.value == null) {
        // Load for all children
        final children = await _supabaseService.loadChildren();
        final allSummaries = <DailySummaryModel>[];

        for (final child in children) {
          final studentId = child['student_id'] as int?;
          if (studentId == null) continue;

          final summaries = await _supabaseService.loadDailySummariesAsModels(
            studentId,
            date: selectedDate.value,
          );
          allSummaries.addAll(summaries);
        }

        dailySummaries.value = allSummaries;
      } else {
        // Load for specific child
        final data = await _supabaseService.loadDailySummariesAsModels(
          selectedChildIdForSummary.value!,
          date: selectedDate.value,
        );
        dailySummaries.value = data;
      }
    } catch (e) {
      print('❌ Error loading daily summaries: $e');
      errorSummaries.value = 'فشل تحميل الخلاصة اليومية. اسحب للتحديث.';
      dailySummaries.value = []; // ✅ تأكد من القائمة الفارغة
    } finally {
      isLoadingSummaries.value = false;
    }
  }

  void changeDate(DateTime newDate) {
    selectedDate.value = newDate;
    loadDailySummaries();
  }

  void previousDay() {
    selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
    loadDailySummaries();
  }

  void nextDay() {
    selectedDate.value = selectedDate.value.add(const Duration(days: 1));
    loadDailySummaries();
  }

  void setChildFilterForSummaries(int? childId) {
    selectedChildIdForSummary.value = childId;
    loadDailySummaries();
  }

  // ═══════════════════════════════════════════════════════════
  // REFRESH
  // ═══════════════════════════════════════════════════════════

  Future<void> refreshAll() async {
    await loadAllData();
  }
}

// ════════════════════════════════════════════════════════════════

/// فلتر الأنشطة
enum ActivityFilter {
  today, // اليوم
  all, // الكل
  completed, // المكتملة
  pending, // المعلقة
  overdue, // المتأخرة
}

extension ActivityFilterExtension on ActivityFilter {
  String get arabicName {
    switch (this) {
      case ActivityFilter.today:
        return 'اليوم';
      case ActivityFilter.all:
        return 'الكل';
      case ActivityFilter.completed:
        return 'المكتملة';
      case ActivityFilter.pending:
        return 'المعلقة';
      case ActivityFilter.overdue:
        return 'المتأخرة';
    }
  }
}
