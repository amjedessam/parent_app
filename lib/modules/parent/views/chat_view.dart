import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parent/theme/app_theme.dart';
import 'package:parent/theme/parent_app_colors.dart';
import '../models/admin_model.dart';
import '../models/message_model.dart';
import '../services/parent_supabase_service.dart';
import '../widgets/message_bubble.dart';

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

  @override
  void initState() {
    super.initState();
    admin = Get.arguments as AdminModel;
    loadMessages();
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getAdminColor(), _getAdminColor().withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  admin.name.split(' ').map((n) => n[0]).take(2).join(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
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
                    reverse: true, // عرض الرسائل من الأسفل (كـ WhatsApp)
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      // عكس index لعرض الرسائل بالترتيب الصحيح
                      final messageIndex = messages.length - 1 - index;
                      final message = messages[messageIndex];
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
