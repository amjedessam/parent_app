import 'package:get/get.dart';
import 'package:parent/modules/parent/models/notification_model.dart';
import 'package:parent/modules/parent/services/parent_supabase_service.dart';
import 'package:parent/modules/parent/views/report_detail_view.dart';

class NotificationController extends GetxController {
  final ParentSupabaseService _supabaseService =
      Get.find<ParentSupabaseService>();

  // State variables
  final isLoading = true.obs;
  final notifications = <NotificationModel>[].obs;
  final showUnreadOnly = false.obs;
  final errorMessage = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  // ✅ Computed property للفلترة
  List<NotificationModel> get filteredNotifications {
    if (showUnreadOnly.value) {
      return notifications.where((n) => !n.isRead).toList();
    }
    return notifications;
  }

  // ✅ تحميل الإشعارات من Supabase
  Future<void> loadNotifications() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      // تحميل الإشعارات من Supabase
      final notificationsData = await _supabaseService.loadNotifications(
        unreadOnly: showUnreadOnly.value,
      );

      // تحويل notificationsData إلى List<NotificationModel>
      notifications.value = notificationsData
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error loading notifications: $e');
      errorMessage.value = 'فشل تحميل الإشعارات';
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ تبديل الفلتر
  void toggleFilter() {
    showUnreadOnly.value = !showUnreadOnly.value;
    loadNotifications(); // Reload with new filter
  }

  Future<void> markAsRead(NotificationModel notification) async {
    try {
      final notificationId = int.tryParse(notification.id.toString());
      if (notificationId == null) return;

      final success = await _supabaseService.markNotificationAsRead(
        notificationId,
      );

      if (!success) return;

      // تحديث الحالة محلياً
      final index = notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        notifications[index] = NotificationModel(
          id: notification.id,
          title: notification.title,
          message: notification.message,
          timestamp: notification.timestamp,
          isRead: true,
          type: notification.type,
          childId: notification.childId,
          metadata: notification.metadata, // ✅ احتفظ بالـ metadata
        );
        notifications.refresh();
      }

      // ✅ فتح تفاصيل التقرير إذا كان النوع report_sent
      if (notification.type == 'report_sent') {
        Get.to(
          () => ReportDetailView(notification: notification),
          transition: Transition.rightToLeft,
        );
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // ✅ عدد الإشعارات غير المقروءة
  int get unreadCount {
    return notifications.where((n) => !n.isRead).length;
  }
}
