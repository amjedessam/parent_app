// modules/parent/models/weekly_summary_model.dart

/// ملخص أسبوعي للأنشطة
class WeeklySummaryModel {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalActivities;
  final int completedActivities;
  final int pendingActivities;
  final int missedActivities;
  final Map<int, int> activitiesPerChild; // childId -> count

  WeeklySummaryModel({
    required this.weekStart,
    required this.weekEnd,
    required this.totalActivities,
    required this.completedActivities,
    required this.pendingActivities,
    required this.missedActivities,
    required this.activitiesPerChild,
  });

  double get completionRate =>
      totalActivities > 0 ? (completedActivities / totalActivities) * 100 : 0;
}
