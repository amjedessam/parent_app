import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parent/theme/app_theme.dart';
import 'package:parent/modules/parent/controllers/notification_controller.dart';
import 'package:parent/theme/parent_app_colors.dart';

class NotificationsView extends GetView<NotificationController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBFC),
        appBar: AppBar(
          backgroundColor: AppColors.heroGradientStart,

          title: const Text('الإشعارات'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            onPressed: () => Get.back(),
          ),
          actions: [
            Obx(
              () => Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: controller.showUnreadOnly.value
                      ? const Color(0xFF6B70F5)
                      : const Color(0xFF6B70F5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    controller.showUnreadOnly.value
                        ? Icons.filter_alt_rounded
                        : Icons.filter_alt_off_rounded,
                    color: controller.showUnreadOnly.value
                        ? Colors.white
                        : const Color(0xFF6B70F5),
                  ),
                  onPressed: controller.toggleFilter,
                ),
              ),
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = controller.filteredNotifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B70F5).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_off_rounded,
                      size: 80,
                      color: const Color(0xFF6B70F5).withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'لا توجد إشعارات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadNotifications,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ModernNotificationItem(
                  notification: notification,
                  onTap: () => controller.markAsRead(notification),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

// Modern Notification Item
class ModernNotificationItem extends StatelessWidget {
  final dynamic notification; // NotificationModel
  final VoidCallback onTap;

  const ModernNotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  Color _getTypeColor() {
    switch (notification.type) {
      case 'exam_published':
      case 'exam_result':
        return const Color(0xFF6B70F5);
      case 'attendance_absent':
        return const Color(0xFFF59E0B);
      case 'report_sent': // ✅ جديد
        return const Color(0xFF0EA5E9);
      case 'message_received':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case 'exam_published':
      case 'exam_result':
        return Icons.assessment_rounded;
      case 'attendance_absent':
        return Icons.warning_amber_rounded;
      case 'report_sent': // ✅ جديد
        return Icons.description_rounded;
      case 'message_received':
        return Icons.mail_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: notification.isRead
              ? Colors.transparent
              : color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(_getTypeIcon(), color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(notification.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
