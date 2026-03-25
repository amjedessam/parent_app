class MessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime timestamp;
  final bool isFromParent;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.isFromParent,
    required this.isRead,
  });

  /// Factory method to create MessageModel from Supabase JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Determine if message is from parent based on sender_parent_id
    final senderParentId = json['sender_parent_id'];
    final isFromParent = senderParentId != null;

    // Get sender/receiver IDs
    final int senderId;
    final int receiverId;

    if (isFromParent) {
      senderId = senderParentId is int ? senderParentId : int.tryParse(senderParentId.toString()) ?? 0;
      final recipientAdminId = json['recipient_admin_id'];
      receiverId = recipientAdminId is int ? recipientAdminId : int.tryParse(recipientAdminId?.toString() ?? '0') ?? 0;
    } else {
      final senderAdminId = json['sender_admin_id'];
      senderId = senderAdminId is int ? senderAdminId : int.tryParse(senderAdminId?.toString() ?? '0') ?? 0;
      final recipientParentId = json['recipient_parent_id'];
      receiverId = recipientParentId is int ? recipientParentId : int.tryParse(recipientParentId?.toString() ?? '0') ?? 0;
    }

    // Parse timestamp - support both sent_at and created_at
    DateTime timestamp;
    final dateField = json['sent_at'] ?? json['created_at'];
    if (dateField is String) {
      timestamp = DateTime.tryParse(dateField) ?? DateTime.now();
    } else if (dateField is DateTime) {
      timestamp = dateField;
    } else {
      timestamp = DateTime.now();
    }

    // Support message_text, content, and message field names
    final content = json['message_text']?.toString() ?? 
                   json['content']?.toString() ?? 
                   json['message']?.toString() ?? '';

    return MessageModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: timestamp,
      isFromParent: isFromParent,
      isRead: json['is_read'] == true,
    );
  }
}
