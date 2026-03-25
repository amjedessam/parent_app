class TestModel {
  final int id;
  final String title;
  final String subject;
  final DateTime date;

  /// obtained_marks من exam_results (رقم خام مثل 18)
  final double score;

  /// total_marks من exam_results (مثل 20)
  final int totalQuestions;

  final int correctAnswers;
  final Duration duration;
  final Map<String, dynamic> details;

  /// النسبة المئوية — تُقرأ من DB (generated column) أو تُحسب
  final double _percentage;

  TestModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.date,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.duration,
    required this.details,
    double? percentage,
  }) : _percentage =
           percentage ??
           (totalQuestions > 0 ? (score / totalQuestions * 100) : 0.0);

  // ─── getter ──────────────────────────────────────────────
  /// النسبة المئوية الصحيحة (0-100) — استخدم هذا دائماً للعرض
  double get percentage => _percentage;

  factory TestModel.fromJson(Map<String, dynamic> json) {
    final exam = json['exams'] as Map<String, dynamic>?;
    final subject = exam?['subjects'] as Map<String, dynamic>?;

    final obtainedMarks = (json['obtained_marks'] ?? json['score'] ?? 0)
        .toDouble();
    final totalMarks =
        (json['total_marks'] ?? json['total_questions'] ?? 0) as num;

    // percentage: يقرأ من الـ generated column في DB إذا كانت موجودة
    double? dbPct;
    if (json['percentage'] != null) {
      dbPct = (json['percentage'] as num).toDouble();
    }

    return TestModel(
      id: _parseInt(json['id']) ?? 0,
      title: exam?['title'] ?? json['title'] ?? '',
      subject: subject?['name'] ?? json['subject'] ?? '',
      date: _parseDate(json['submitted_at'] ?? json['date']),
      score: obtainedMarks,
      totalQuestions: totalMarks.toInt(),
      correctAnswers: json['correct_answers'] ?? 0,
      duration: Duration(
        seconds: json['time_taken_seconds'] ?? json['duration'] ?? 0,
      ),
      details: json['details'] as Map<String, dynamic>? ?? {},
      percentage: dbPct,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }
}
