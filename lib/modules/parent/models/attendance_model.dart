// ════════════════════════════════════════════════════════════

// modules/parent/models/attendance_model.dart

/// نموذج الحضور والغياب
class AttendanceModel {
  final int childId;
  final String childName;
  final DateTime month;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int excusedAbsences;
  final List<AttendanceDay> dailyRecords;

  AttendanceModel({
    required this.childId,
    required this.childName,
    required this.month,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.excusedAbsences,
    required this.dailyRecords,
  });

  /// Factory method to create AttendanceModel from Supabase aggregated data
  factory AttendanceModel.fromSupabaseJson(
    Map<String, dynamic> json, {
    required DateTime month,
    String? childName,
  }) {
    final dailyRecordsJson = json['daily_records'] as List<dynamic>? ?? [];
    
    return AttendanceModel(
      childId: _parseInt(json['student_id']) ?? 0,
      childName: childName ?? json['student_name_cache']?.toString() ?? '',
      month: month,
      totalDays: _parseInt(json['total_days']) ?? 0,
      presentDays: _parseInt(json['present_days']) ?? 0,
      absentDays: _parseInt(json['absent_days']) ?? 0,
      lateDays: _parseInt(json['late_days']) ?? 0,
      excusedAbsences: _parseInt(json['excused_absences']) ?? 0,
      dailyRecords: dailyRecordsJson
          .map((day) => AttendanceDay.fromJson(day as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Factory from raw attendance records (for client-side aggregation)
  factory AttendanceModel.fromRawRecords(
    int childId,
    String childName,
    DateTime month,
    List<Map<String, dynamic>> records,
  ) {
    final dailyRecords = records.map((r) => AttendanceDay.fromJson(r)).toList();
    
    return AttendanceModel(
      childId: childId,
      childName: childName,
      month: month,
      totalDays: records.length,
      presentDays: records.where((r) => r['status'] == 'present').length,
      absentDays: records.where((r) => r['status'] == 'absent').length,
      lateDays: records.where((r) => r['status'] == 'late').length,
      excusedAbsences: records.where((r) => r['status'] == 'excused').length,
      dailyRecords: dailyRecords,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  /// نسبة الحضور
  double get attendancePercentage =>
      totalDays > 0 ? (presentDays / totalDays) * 100 : 0;

  /// نسبة الغياب
  double get absencePercentage =>
      totalDays > 0 ? (absentDays / totalDays) * 100 : 0;

  /// نسبة التأخير
  double get latePercentage => totalDays > 0 ? (lateDays / totalDays) * 100 : 0;
}

/// سجل يوم واحد
class AttendanceDay {
  final DateTime date;
  final AttendanceStatus status;
  final String? note;
  final DateTime? checkInTime;

  AttendanceDay({
    required this.date,
    required this.status,
    this.note,
    this.checkInTime,
  });

  /// Factory method to create AttendanceDay from Supabase JSON
  factory AttendanceDay.fromJson(Map<String, dynamic> json) {
    return AttendanceDay(
      date: _parseDate(json['attendance_date'] ?? json['date']),
      status: _parseAttendanceStatus(json['status']),
      note: json['notes']?.toString() ?? json['note']?.toString(),
      checkInTime: json['check_in_time'] != null
          ? DateTime.tryParse(json['check_in_time'].toString())
          : null,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static AttendanceStatus _parseAttendanceStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'excused':
        return AttendanceStatus.excused;
      case 'holiday':
        return AttendanceStatus.holiday;
      default:
        return AttendanceStatus.notRecorded;
    }
  }

  bool get isLate {
    if (checkInTime == null) return false;
    // افتراض أن الدوام يبدأ الساعة 7:30
    final expectedTime = DateTime(date.year, date.month, date.day, 7, 30);
    return checkInTime!.isAfter(expectedTime);
  }
}

enum AttendanceStatus {
  present, // حاضر
  absent, // غائب
  late, // متأخر
  excused, // غياب بعذر
  holiday, // عطلة
  notRecorded, // لم يسجل
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get arabicName {
    switch (this) {
      case AttendanceStatus.present:
        return 'حاضر';
      case AttendanceStatus.absent:
        return 'غائب';
      case AttendanceStatus.late:
        return 'متأخر';
      case AttendanceStatus.excused:
        return 'غياب بعذر';
      case AttendanceStatus.holiday:
        return 'عطلة';
      case AttendanceStatus.notRecorded:
        return 'لم يسجل';
    }
  }
}
