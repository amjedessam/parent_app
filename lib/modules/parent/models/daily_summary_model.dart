class DailySummaryModel {
  final int id;
  final int childId;
  final String childName;
  final String? teacherName; // ← اسم المعلم
  final String? className; // ← اسم الصف
  final DateTime date;
  final String recap;
  final ParticipationLevel participationLevel;
  final BehaviorLevel behaviorLevel;
  final FocusLevel focusLevel;
  final String? teacherNote;
  final String? highlightOfDay;
  final List<String> subjectsStudied;
  final Map<String, String>? subjectNotes; // ملاحظات لكل مادة

  DailySummaryModel({
    required this.id,
    required this.childId,
    required this.childName,
    this.teacherName,
    this.className, // ← اسم الصف
    required this.date,
    required this.recap,
    required this.participationLevel,
    required this.behaviorLevel,
    required this.focusLevel,
    this.teacherNote,
    this.highlightOfDay,
    required this.subjectsStudied,
    this.subjectNotes,
  });

  /// Factory method to create DailySummaryModel from Supabase JSON
  /// DB columns: recap, subjects_studied (text[]); model also accepts summary_content, subjects_covered.
  factory DailySummaryModel.fromJson(Map<String, dynamic> json) {
    // DB has subjects_studied (text[]); support subjects_covered for compatibility
    final raw = json['subjects_studied'] ?? json['subjects_covered'];
    List<String> subjectsList = [];
    if (raw is List) {
      subjectsList = raw.map((s) => s.toString()).toList();
    } else if (raw is String) {
      subjectsList = [raw];
    }

    // Parse subject_notes (JSONB object in database)
    final subjectNotesJson = json['subject_notes'];
    Map<String, String>? subjectNotesMap;
    if (subjectNotesJson is Map) {
      subjectNotesMap = subjectNotesJson.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }

    return DailySummaryModel(
      id: _parseInt(json['id']) ?? 0,
      childId: _parseInt(json['student_id'] ?? json['childId']) ?? 0,
      childName:
          json['student_name']?.toString() ??
          json['student_name_cache']?.toString() ??
          json['childName']?.toString() ??
          '',
      // teacherName:
      //     json['teacher_name']?.toString() ?? json['teacher_name']?.toString(),
      // ✅ AFTER (صحيح)
      teacherName:
          json['teacher_name']?.toString() ??
          json['teacher_name_from_join']?.toString() ??
          json['teacherName']?.toString() ??
          json['teacher_name_cache']?.toString(),
      className:
          json['section_name']?.toString() ??
          json['className']?.toString() ??
          json['class_name']?.toString(),
      date: _parseDate(json['summary_date'] ?? json['date']),
      recap:
          json['summary_content']?.toString() ??
          json['recap']?.toString() ??
          '',
      participationLevel: _parseParticipationLevel(json['participation_level']),
      behaviorLevel: _parseBehaviorLevel(json['behavior_level']),
      focusLevel: _parseFocusLevel(json['focus_level']),
      // teacherNote:
      //     json['teacher_notes']?.toString() ?? json['teacherNote']?.toString(),
      // highlightOfDay:
      //     json['highlight']?.toString() ?? json['highlightOfDay']?.toString(),
      teacherNote:
          json['teacher_note']?.toString() ??
          json['teacher_notes']?.toString() ??
          json['teacherNote']?.toString(),
      highlightOfDay:
          json['highlight_of_day']?.toString() ??
          json['highlight']?.toString() ??
          json['highlightOfDay']?.toString(),
      subjectsStudied: subjectsList,
      subjectNotes: subjectNotesMap,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static ParticipationLevel _parseParticipationLevel(dynamic value) {
    final intValue = _parseInt(value) ?? 3;
    switch (intValue) {
      case 5:
        return ParticipationLevel.veryActive;
      case 4:
        return ParticipationLevel.active;
      case 3:
        return ParticipationLevel.moderate;
      case 2:
        return ParticipationLevel.passive;
      case 1:
        return ParticipationLevel.notParticipating;
      default:
        return ParticipationLevel.moderate;
    }
  }

  static BehaviorLevel _parseBehaviorLevel(dynamic value) {
    final intValue = _parseInt(value) ?? 3;
    switch (intValue) {
      case 5:
        return BehaviorLevel.excellent;
      case 4:
        return BehaviorLevel.good;
      case 3:
        return BehaviorLevel.acceptable;
      case 2:
        return BehaviorLevel.needsAttention;
      case 1:
        return BehaviorLevel.problematic;
      default:
        return BehaviorLevel.acceptable;
    }
  }

  static FocusLevel _parseFocusLevel(dynamic value) {
    final intValue = _parseInt(value) ?? 3;
    switch (intValue) {
      case 5:
        return FocusLevel.highlyFocused;
      case 4:
        return FocusLevel.focused;
      case 3:
        return FocusLevel.moderate;
      case 2:
        return FocusLevel.distracted;
      case 1:
        return FocusLevel.veryDistracted;
      default:
        return FocusLevel.moderate;
    }
  }

  /// مستوى الأداء العام
  PerformanceLevel get overallPerformance {
    final levels = [
      participationLevel.value,
      behaviorLevel.value,
      focusLevel.value,
    ];
    final avg = levels.reduce((a, b) => a + b) / levels.length;

    if (avg >= 4) return PerformanceLevel.excellent;
    if (avg >= 3) return PerformanceLevel.good;
    if (avg >= 2) return PerformanceLevel.average;
    return PerformanceLevel.needsImprovement;
  }
}

/// مستوى المشاركة
enum ParticipationLevel {
  veryActive(5), // نشط جداً
  active(4), // نشط
  moderate(3), // معتدل
  passive(2), // سلبي
  notParticipating(1); // لم يشارك

  final int value;
  const ParticipationLevel(this.value);

  String get arabicName {
    switch (this) {
      case ParticipationLevel.veryActive:
        return 'نشط جداً';
      case ParticipationLevel.active:
        return 'نشط';
      case ParticipationLevel.moderate:
        return 'معتدل';
      case ParticipationLevel.passive:
        return 'سلبي';
      case ParticipationLevel.notParticipating:
        return 'لم يشارك';
    }
  }
}

/// مستوى السلوك
enum BehaviorLevel {
  excellent(5), // ممتاز
  good(4), // جيد
  acceptable(3), // مقبول
  needsAttention(2), // يحتاج انتباه
  problematic(1); // مشكلة

  final int value;
  const BehaviorLevel(this.value);

  String get arabicName {
    switch (this) {
      case BehaviorLevel.excellent:
        return 'ممتاز';
      case BehaviorLevel.good:
        return 'جيد';
      case BehaviorLevel.acceptable:
        return 'مقبول';
      case BehaviorLevel.needsAttention:
        return 'يحتاج انتباه';
      case BehaviorLevel.problematic:
        return 'مشكلة';
    }
  }
}

/// مستوى التركيز
enum FocusLevel {
  highlyFocused(5), // مركز جداً
  focused(4), // مركز
  moderate(3), // معتدل
  distracted(2), // مشتت
  veryDistracted(1); // مشتت جداً

  final int value;
  const FocusLevel(this.value);

  String get arabicName {
    switch (this) {
      case FocusLevel.highlyFocused:
        return 'مركز جداً';
      case FocusLevel.focused:
        return 'مركز';
      case FocusLevel.moderate:
        return 'معتدل';
      case FocusLevel.distracted:
        return 'مشتت';
      case FocusLevel.veryDistracted:
        return 'مشتت جداً';
    }
  }
}

/// مستوى الأداء العام
enum PerformanceLevel {
  excellent, // ممتاز
  good, // جيد
  average, // يحتاج تحسين

  needsImprovement;

  String get arabicName {
    switch (this) {
      case PerformanceLevel.excellent:
        return 'ممتاز';
      case PerformanceLevel.good:
        return 'جيد';
      case PerformanceLevel.average:
        return 'متوسط';
      case PerformanceLevel.needsImprovement:
        return 'يحتاج تحسين';
    }
  }
}
