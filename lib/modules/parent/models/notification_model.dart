class NotificationModel {
  final dynamic id;
  final String title;
  final String message;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final dynamic childId;
  final Map<String, dynamic>? metadata; // ✅ أضف هذا

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.childId,
    this.metadata, // ✅
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'] ?? '',
      type:
          json['notification_type']?.toString() ??
          json['type']?.toString() ??
          'general',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      isRead: json['is_read'] ?? false,
      childId: json['metadata']?['student_id'],
      metadata:
          json['metadata'] !=
              null // ✅
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}
