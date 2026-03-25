import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parent/theme/app_theme.dart';
import 'package:parent/theme/parent_app_colors.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final Color teacherColor;

  const MessageBubble({
    super.key,
    required this.message,
    required this.teacherColor,
  });

  String _formatTime(DateTime timestamp) {
    final localTime = timestamp.toLocal();
    return DateFormat('HH:mm').format(localTime);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isFromParent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Avatar الإداري (يسار) ─────────────────────
          if (!message.isFromParent) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                border: Border.all(color: AppColors.primaryBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // ── فقاعة الرسالة ─────────────────────────────
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                // رسالة ولي الأمر → Sky Blue gradient
                gradient: message.isFromParent
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                // رسالة الإداري → أبيض بحد أزرق خفيف
                color: message.isFromParent ? null : AppColors.surface,
                border: message.isFromParent
                    ? null
                    : Border.all(color: AppColors.border),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isFromParent ? 18 : 4),
                  bottomRight: Radius.circular(message.isFromParent ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: message.isFromParent
                        ? AppColors.shadowSoft
                        : AppColors.shadowCard,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // نص الرسالة
                  Text(
                    message.content,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      color: message.isFromParent
                          ? Colors.white
                          : AppColors.textDark,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // الوقت + علامة القراءة
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: message.isFromParent
                              ? Colors.white.withOpacity(0.75)
                              : AppColors.textLight,
                        ),
                      ),
                      if (message.isFromParent) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 14,
                          // ✅ بدل Colors.lightBlueAccent
                          color: message.isRead
                              ? Colors.white
                              : Colors.white.withOpacity(0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Avatar ولي الأمر (يمين) ───────────────────
          if (message.isFromParent) ...[
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
