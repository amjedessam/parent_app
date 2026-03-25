import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parent/modules/parent/services/parent_auth_service.dart';
import '../models/child_model.dart';
import '../models/parent_model.dart';
import '../services/parent_supabase_service.dart';

class DashboardController extends GetxController {
  final ParentSupabaseService _supabaseService =
      Get.find<ParentSupabaseService>();

  // ─── State ──────────────────────────────────────────────
  final isLoading = true.obs;
  final parent = Rxn<ParentModel>();
  final children = <ChildModel>[].obs;
  final unreadNotificationsCount = 0.obs;
  final errorMessage = Rxn<String>();
  final unreadMessages = 0.obs;

  // ربط طالب جديد
  final isLinkingChild = false.obs;
  final linkError = Rxn<String>();

  // ─── Computed ───────────────────────────────────────────
  int get totalChildren => children.length;
  int get totalReports =>
      children.fold(0, (sum, child) => sum + child.testHistory.length);

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  // ────────────────────────────────────────────────────────
  // LOAD DATA
  // ────────────────────────────────────────────────────────
  Future<void> loadData() async {
    isLoading.value = true;
    errorMessage.value = null;

    print(
      '🔄 loadData() — parentId='
      '${Get.find<ParentAuthService>().appEntityId.value}',
    );

    try {
      // بيانات ولي الأمر
      final parentData = await _supabaseService.loadCurrentParent();
      if (parentData != null) {
        parent.value = ParentModel.fromJson(parentData);
      }

      // الأطفال
      final childrenData = await _supabaseService.loadChildren();
      children.value = await _enrichChildrenData(childrenData);

      // الإشعارات غير المقروءة
      final notifications = await _supabaseService.loadNotifications(
        unreadOnly: true,
      );
      unreadNotificationsCount.value = notifications.length;

      // الرسائل غير المقروءة
      try {
        final messages = await _supabaseService.loadMessages();
        unreadMessages.value = messages
            .where((m) => m['is_read'] == false)
            .length;
      } catch (e) {
        print('❌ Error loading messages in dashboard: $e');
        unreadMessages.value = 0;
      }
    } catch (e) {
      print('❌ loadData error: $e');
      errorMessage.value = 'فشل تحميل البيانات. اسحب للتحديث.';
    } finally {
      isLoading.value = false;
    }
  }

  // ────────────────────────────────────────────────────────
  // ENRICH CHILDREN — يُضاف أداء المواد هنا
  // ────────────────────────────────────────────────────────
  Future<List<ChildModel>> _enrichChildrenData(
    List<Map<String, dynamic>> childrenData,
  ) async {
    final result = <ChildModel>[];

    for (final childJson in childrenData) {
      final studentData = childJson['students'] as Map<String, dynamic>?;
      final studentId = (childJson['student_id'] ?? studentData?['id']) as int?;
      if (studentId == null) continue;

      // ─── نتائج الاختبارات (لحساب latestScore و averageScore) ──
      final examResults = await _supabaseService.loadChildExamResults(
        studentId,
        limit: 20,
      );

      // latestScore من الـ percentage مباشرة (كما هو في DB)
      final latestScore = examResults.isNotEmpty
          ? ((examResults.first['percentage'] ?? 0) as num).toDouble()
          : 0.0;

      // averageScore = AVG(percentage) لكل الاختبارات
      final averageScore = examResults.isNotEmpty
          ? examResults
                    .map((e) => ((e['percentage'] ?? 0) as num).toDouble())
                    .reduce((a, b) => a + b) /
                examResults.length
          : 0.0;

      // ─── أداء المواد الدراسية ──────────────────────────────
      final subjectPerformances = await _supabaseService
          .loadStudentSubjectPerformances(studentId);

      // ─── ملخص التدريب الذاتي ──────────────────────────────
      final practiceSummary = await _supabaseService.loadChildPracticeSummary(
        studentId,
      );

      // ─── بناء ChildModel ──────────────────────────────────
      final childModel =
          ChildModel.fromJson({
            ...childJson,
            'latestScore': latestScore,
            'averageScore': averageScore,
            'testHistory': examResults,
          }).copyWith(
            subjectPerformances: subjectPerformances,
            practiceAttempts:
                (practiceSummary['total_attempts'] as num?)?.toInt() ?? 0,
            practiceAverageScore:
                (practiceSummary['average_score'] as num?)?.toDouble() ?? 0.0,
            practiceTotalCorrect:
                (practiceSummary['total_correct'] as num?)?.toInt() ?? 0,
            practiceTotalWrong:
                (practiceSummary['total_wrong'] as num?)?.toInt() ?? 0,
            practiceLastAttemptAt: practiceSummary['last_attempt_at'] != null
                ? DateTime.tryParse(
                    practiceSummary['last_attempt_at'].toString(),
                  )
                : null,
            practiceSubjectsSummary: practiceSummary['subjects_summary'] != null
                ? List<Map<String, dynamic>>.from(
                    (practiceSummary['subjects_summary'] as List).map(
                      (e) => Map<String, dynamic>.from(e as Map),
                    ),
                  )
                : [],
          );

      result.add(childModel);
    }

    return result;
  }

  // ────────────────────────────────────────────────────────
  // LINK NEW CHILD
  // ────────────────────────────────────────────────────────
  Future<void> linkNewChild(int studentCode, String relationship) async {
    isLinkingChild.value = true;
    linkError.value = null;

    final error = await _supabaseService.linkChildByStudentCode(
      studentCode,
      relationship,
    );

    if (error != null) {
      linkError.value = error;
      isLinkingChild.value = false;
      return;
    }

    Get.back();
    await loadData();

    Get.snackbar(
      'تم بنجاح ✅',
      'تمت إضافة الطالب',
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );

    isLinkingChild.value = false;
  }

  // ────────────────────────────────────────────────────────
  // NAVIGATION
  // ────────────────────────────────────────────────────────
  void goToChildReport(ChildModel child) {
    Get.toNamed('/parent/child-report', arguments: child);
  }

  void openNotifications() {
    Get.toNamed('/parent/notifications');
  }
}
