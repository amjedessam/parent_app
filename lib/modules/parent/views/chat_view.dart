import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parent/core/services/push_notifications_service.dart';
import 'package:parent/theme/parent_app_colors.dart';
import '../models/admin_model.dart';
import '../models/message_model.dart';
import '../services/parent_supabase_service.dart';
import '../widgets/message_bubble.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modern Chat View - Beautiful Message Bubbles
///
/// ✅ MIGRATED TO ADMIN — التواصل مع الإدارة
class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ParentSupabaseService _supabaseService =
      Get.find<ParentSupabaseService>();
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  late AdminModel admin;
  List<MessageModel> messages = [];
  bool isLoading = true;
  RealtimeChannel? _incomingChannel;
  RealtimeChannel? _outgoingChannel;
  int? _parentId;
  Timer? _silentPollTimer;

  @override
  void initState() {
    super.initState();
    admin = Get.arguments as AdminModel;
    PushNotificationsService.suppressForegroundMessageNotifications = true;
    _initChat();
  }

  Future<void> _initChat() async {
    await loadMessages();
    _parentId = await _supabaseService.getCurrentParentId();
    if (_parentId != null) {
      _subscribeRealtime();
      _startSilentPolling();
      // Best effort only: avoid crashing UI if RLS/JWT claims are not ready.
      try {
        await _supabaseService.markConversationAsRead(adminId: admin.id);
      } catch (e) {
        print('⚠️ markConversationAsRead failed on init: $e');
      }
    }
  }

  /// احتياط إذا تعثّر Realtime (فلترة، نشر، إلخ) — تحديث خفيف بدون إعادة تحميل كاملة.
  void _startSilentPolling() {
    _silentPollTimer?.cancel();
    _silentPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _silentRefreshMessages();
    });
  }

  Future<void> _silentRefreshMessages() async {
    if (!mounted) return;
    try {
      final messagesData = await _supabaseService.loadMessages(adminId: admin.id);
      final list = messagesData
          .map((json) => MessageModel.fromJson(json))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      if (!mounted) return;
      if (!_messagesListsDiffer(messages, list)) return;
      setState(() {
        messages = list;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('⚠️ silent refresh: $e');
    }
  }

  bool _messagesListsDiffer(List<MessageModel> a, List<MessageModel> b) {
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].content != b[i].content) return true;
    }
    return false;
  }

  Future<void> loadMessages() async {
    setState(() => isLoading = true);
    try {
      final messagesData = await _supabaseService.loadMessages(
        adminId: admin.id,
      );

      // Convert Supabase JSON to MessageModel
      messages = messagesData
          .map((json) => MessageModel.fromJson(json))
          .toList();

      // ترتيب الرسائل: الأقدم أولاً (للعرض مع reverse: true)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      print('❌ Error loading messages: $e');
    }
    setState(() => isLoading = false);
    _scrollToBottom();
  }

  void _subscribeRealtime() {
    final parentId = _parentId;
    if (parentId == null) return;

    final client = Supabase.instance.client;

    // Incoming messages (Admin -> Parent). يجب أن يطابق عمود int في Postgres (لا نمرّر نصًا).
    _incomingChannel = client
        .channel('messages_incoming_parent_${parentId}_${admin.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_parent_id',
            value: parentId,
          ),
          callback: (payload) async {
            final newRow = Map<String, dynamic>.from(payload.newRecord);
            final senderAdminId = newRow['sender_admin_id'];
            final senderId = senderAdminId is int
                ? senderAdminId
                : int.tryParse(senderAdminId?.toString() ?? '');
            if (senderId != admin.id) return;

            final m = MessageModel.fromJson(newRow);
            if (!mounted) return;
            setState(() {
              if (messages.any((x) => x.id == m.id)) return;
              messages.add(m);
              messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            });
            _scrollToBottom();
            try {
              await _supabaseService.markConversationAsRead(adminId: admin.id);
            } catch (e) {
              print('⚠️ markConversationAsRead failed in callback: $e');
            }
          },
        )
        .subscribe((status, [err]) {
          debugPrint('📡 realtime incoming: $status ${err ?? ''}');
        });

    // Outgoing messages (Parent -> Admin).
    _outgoingChannel = client
        .channel('messages_outgoing_parent_${parentId}_${admin.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'sender_parent_id',
            value: parentId,
          ),
          callback: (payload) {
            final newRow = Map<String, dynamic>.from(payload.newRecord);
            final recipientAdminId = newRow['recipient_admin_id'];
            final rid = recipientAdminId is int
                ? recipientAdminId
                : int.tryParse(recipientAdminId?.toString() ?? '');
            if (rid != admin.id) return;

            final m = MessageModel.fromJson(newRow);
            if (!mounted) return;
            setState(() {
              if (messages.any((x) => x.id == m.id)) return;
              messages.add(m);
              messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            });
            _scrollToBottom();
          },
        )
        .subscribe((status, [err]) {
          debugPrint('📡 realtime outgoing: $status ${err ?? ''}');
        });
  }

  @override
  void dispose() {
    PushNotificationsService.suppressForegroundMessageNotifications = false;
    _silentPollTimer?.cancel();
    _incomingChannel?.unsubscribe();
    _outgoingChannel?.unsubscribe();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    final content = messageController.text.trim();
    messageController.clear();

    // Get actual parent ID
    final parentId = await _supabaseService.getCurrentParentId();

    // Optimistic update - add message immediately
    setState(() {
      messages.add(
        MessageModel(
          id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
          senderId: parentId ?? 0,
          receiverId: admin.id,
          content: content,
          timestamp: DateTime.now(),
          isFromParent: true,
          isRead: false,
        ),
      );
    });

    _scrollToBottom();

    try {
      // Send via Supabase
      await _supabaseService.sendMessage(
        adminId: admin.id,
        subject: 'رسالة جديدة',
        content: content,
      );
    } catch (e) {
      print('❌ Error sending message: $e');
      // TODO: Handle error - maybe remove optimistic message or show error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل إرسال الرسالة')));
    }
  }

  Color _getAdminColor() {
    // Admin gets a distinctive purple color
    return const Color.fromARGB(255, 75, 126, 246);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.heroGradientStart,

        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            // Container(
            //   width: 40,
            //   height: 40,
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //       colors: [_getAdminColor(), _getAdminColor().withOpacity(0.7)],
            //     ),
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: Center(
            //     child: Text(
            //       admin.name.split(' ').map((n) => n[0]).take(2).join(),
            //       style: const TextStyle(
            //         fontSize: 14,
            //         fontWeight: FontWeight.bold,
            //         color: Colors.white,
            //       ),
            //     ),
            //   ),
            // ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getAdminColor(), _getAdminColor().withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ادارة المدرسة',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.backgroundLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return MessageBubble(
                        message: message,
                        teacherColor: _getAdminColor(),
                      );
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: messageController,
                // textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  // hintTextDirection: TextDirection.rtl,
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
