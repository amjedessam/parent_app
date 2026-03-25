// modules/parent/models/activity_model.dart

/// نموذج الأنشطة والواجبات
class ActivityModel {
  final int id;
  final int childId;
  final String childName;  // ← اسم الطالب
  final String? className; // ← اسم الصف
  final String? teacherName; // ← اسم المعلم
  final String title;
  final String description;
  final ActivityType type;
  final ActivityStatus status;
  final DateTime dueDate;
  final String? subject;
  final int? priority; // 1-5

  ActivityModel({
    required this.id,
    required this.childId,
    required this.childName,
    this.className,
    this.teacherName,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.dueDate,
    this.subject,
    this.priority,
  });

  /// Factory method to create ActivityModel from Supabase JSON
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    // Support both Supabase structure (with nested subjects) and flat structure
    final subjectData = json['subjects'] as Map<String, dynamic>?;

    // استخرج بيانات الطالب والمعلم والصف
    final studentData = json['students'] as Map<String, dynamic>?;
    final sectionData = studentData?['sections'] as Map<String, dynamic>?;
    final teacherData = json['teachers'] as Map<String, dynamic>?;

    return ActivityModel(
      id: _parseInt(json['id']) ?? 0,
      childId: _parseInt(json['student_id'] ?? json['childId']) ?? 0,
      childName:
          json['student_name']?.toString() ??
          studentData?['full_name']?.toString() ??
          'طالب',
      className:
          json['section_name']?.toString() ??
          sectionData?['name']?.toString(),
      teacherName:
          json['teacher_name']?.toString() ??
          teacherData?['full_name']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: _parseActivityType(json['activity_type'] ?? json['type']),
      status: _parseActivityStatus(json['status']),
      dueDate: _parseDate(json['due_date'] ?? json['dueDate']),
      subject: subjectData?['name']?.toString() ?? 
               json['subject']?.toString(),
      priority: _parseInt(json['priority']) ?? 3,
    );
  }

  /// Helper: Parse int from various types
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  /// Helper: Parse DateTime from various types
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  /// Helper: Parse ActivityType from string
  static ActivityType _parseActivityType(String? value) {
    switch (value?.toLowerCase()) {
      case 'homework':
        return ActivityType.homework;
      case 'project':
        return ActivityType.project;
      case 'task':
        return ActivityType.task;
      case 'reading':
        return ActivityType.reading;
      case 'practice':
        return ActivityType.practice;
      default:
        return ActivityType.task;
    }
  }

  /// Helper: Parse ActivityStatus from string
  static ActivityStatus _parseActivityStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return ActivityStatus.pending;
      case 'in_progress':
      case 'inprogress':
        return ActivityStatus.inProgress;
      case 'completed':
        return ActivityStatus.completed;
      case 'missing':
        return ActivityStatus.missing;
      case 'submitted':
        return ActivityStatus.submitted;
      default:
        return ActivityStatus.pending;
    }
  }

  /// Convert to JSON for storage/serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': childId,
      'title': title,
      'description': description,
      'activity_type': type.name,
      'status': _statusToString(status),
      'due_date': dueDate.toIso8601String(),
      'subject': subject,
      'priority': priority,
    };
  }

  static String _statusToString(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.pending:
        return 'pending';
      case ActivityStatus.inProgress:
        return 'in_progress';
      case ActivityStatus.completed:
        return 'completed';
      case ActivityStatus.missing:
        return 'missing';
      case ActivityStatus.submitted:
        return 'submitted';
    }
  }

  bool get isOverdue =>
      status != ActivityStatus.completed && DateTime.now().isAfter(dueDate);

  bool get isDueToday =>
      dueDate.year == DateTime.now().year &&
      dueDate.month == DateTime.now().month &&
      dueDate.day == DateTime.now().day;
}

enum ActivityType {
  homework, // واجب منزلي
  project, // مشروع
  task, // مهمة
  reading, // قراءة
  practice, // تمرين
}

enum ActivityStatus {
  pending, // معلق
  inProgress, // قيد التنفيذ
  completed, // مكتمل
  missing, // مفقود
  submitted, // تم التسليم
}

// Extension لترجمة الأنواع
extension ActivityTypeExtension on ActivityType {
  String get arabicName {
    switch (this) {
      case ActivityType.homework:
        return 'واجب منزلي';
      case ActivityType.project:
        return 'مشروع';
      case ActivityType.task:
        return 'مهمة';
      case ActivityType.reading:
        return 'قراءة';
      case ActivityType.practice:
        return 'تمرين';
    }
  }
}

extension ActivityStatusExtension on ActivityStatus {
  String get arabicName {
    switch (this) {
      case ActivityStatus.pending:
        return 'معلق';
      case ActivityStatus.inProgress:
        return 'قيد التنفيذ';
      case ActivityStatus.completed:
        return 'مكتمل';
      case ActivityStatus.missing:
        return 'مفقود';
      case ActivityStatus.submitted:
        return 'تم التسليم';
    }
  }
}
