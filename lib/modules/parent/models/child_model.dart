import 'test_model.dart';
import 'subject_performance_model.dart';

class ChildModel {
  final int id;
  final String name;
  final String grade;
  final String? avatarUrl;

  /// نسبة آخر اختبار مكتمل (percentage من exam_results)
  final double latestScore;

  /// متوسط النسب من exam_results.percentage
  final double averageScore;

  final List<String> recentAlerts;
  final List<TestModel> testHistory;
  final Map<String, double> curriculumGaps;

  // حقول من Supabase
  final int studentCode;
  final String? sectionName;
  final String relationship;

  /// ✅ أداء الطالب لكل مادة دراسية
  final List<SubjectPerformanceModel> subjectPerformances;

  // ─── حقول التدريب الذاتي (من practice_quiz_attempts) ───
  final int practiceAttempts;
  final double practiceAverageScore;
  final int practiceTotalCorrect;
  final int practiceTotalWrong;
  final DateTime? practiceLastAttemptAt;
  final List<Map<String, dynamic>> practiceSubjectsSummary;

  ChildModel({
    required this.id,
    required this.name,
    required this.grade,
    this.avatarUrl,
    required this.latestScore,
    required this.averageScore,
    required this.recentAlerts,
    required this.testHistory,
    required this.curriculumGaps,
    this.studentCode = 0,
    this.sectionName,
    this.relationship = '',
    this.subjectPerformances = const [],
    this.practiceAttempts = 0,
    this.practiceAverageScore = 0.0,
    this.practiceTotalCorrect = 0,
    this.practiceTotalWrong = 0,
    this.practiceLastAttemptAt,
    this.practiceSubjectsSummary = const [],
  });

  // ─────────────────────────────────────────────────────────
  // FACTORY
  // البنية المتوقعة من Supabase:
  //   parent_students → select('*, students(*, section:sections(name, grade:grades(name)))')
  // ─────────────────────────────────────────────────────────
  factory ChildModel.fromJson(Map<String, dynamic> json) {
    final studentData = json['students'] as Map<String, dynamic>? ?? json;
    final sectionData = studentData['section'] as Map<String, dynamic>?;
    final gradeData = sectionData?['grade'] as Map<String, dynamic>?;

    // testHistory
    final rawTests = json['testHistory'] as List? ?? [];
    final tests = rawTests
        .map((e) => TestModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // latestScore و averageScore — أولوية للقيم المحسوبة مسبقاً في Controller
    final directLatest = json['latestScore'];
    final directAverage = json['averageScore'];

    double latestScore = 0.0;
    double avgScore = 0.0;

    if (directLatest != null) {
      latestScore = (directLatest as num).toDouble();
    } else if (tests.isNotEmpty) {
      latestScore = tests.first.totalQuestions > 0
          ? tests.first.score / tests.first.totalQuestions * 100
          : 0.0;
    }

    if (directAverage != null) {
      avgScore = (directAverage as num).toDouble();
    } else if (tests.isNotEmpty) {
      avgScore =
          tests
              .map(
                (t) => t.totalQuestions > 0
                    ? t.score / t.totalQuestions * 100
                    : 0.0,
              )
              .reduce((a, b) => a + b) /
          tests.length;
    }

    return ChildModel(
      id: _parseInt(studentData['id']) ?? 0,
      studentCode: _parseInt(studentData['student_code']) ?? 0,
      name: studentData['full_name']?.toString() ?? '',
      grade:
          gradeData?['name']?.toString() ??
          json['grade_name']?.toString() ??
          json['grade']?.toString() ??
          '',
      sectionName: sectionData?['name']?.toString(),
      avatarUrl: studentData['profile_image_url']?.toString(),
      relationship: json['relationship']?.toString() ?? '',
      latestScore: latestScore,
      averageScore: avgScore,
      recentAlerts:
          (json['recentAlerts'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      testHistory: tests,
      curriculumGaps: json['curriculumGaps'] != null
          ? Map<String, double>.from(json['curriculumGaps'])
          : {},
      subjectPerformances: const [], // تُحقن لاحقاً عبر copyWith
    );
  }

  // ─────────────────────────────────────────────────────────
  // copyWith — لإضافة subjectPerformances وبيانات التدريب
  // ─────────────────────────────────────────────────────────
  ChildModel copyWith({
    List<SubjectPerformanceModel>? subjectPerformances,
    double? averageScore,
    double? latestScore,
    int? practiceAttempts,
    double? practiceAverageScore,
    int? practiceTotalCorrect,
    int? practiceTotalWrong,
    DateTime? practiceLastAttemptAt,
    List<Map<String, dynamic>>? practiceSubjectsSummary,
  }) {
    return ChildModel(
      id: id,
      name: name,
      grade: grade,
      avatarUrl: avatarUrl,
      latestScore: latestScore ?? this.latestScore,
      averageScore: averageScore ?? this.averageScore,
      recentAlerts: recentAlerts,
      testHistory: testHistory,
      curriculumGaps: curriculumGaps,
      studentCode: studentCode,
      sectionName: sectionName,
      relationship: relationship,
      subjectPerformances: subjectPerformances ?? this.subjectPerformances,
      practiceAttempts: practiceAttempts ?? this.practiceAttempts,
      practiceAverageScore: practiceAverageScore ?? this.practiceAverageScore,
      practiceTotalCorrect: practiceTotalCorrect ?? this.practiceTotalCorrect,
      practiceTotalWrong: practiceTotalWrong ?? this.practiceTotalWrong,
      practiceLastAttemptAt:
          practiceLastAttemptAt ?? this.practiceLastAttemptAt,
      practiceSubjectsSummary:
          practiceSubjectsSummary ?? this.practiceSubjectsSummary,
    );
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  TestModel? get latestTest =>
      testHistory.isNotEmpty ? testHistory.first : null;
}
