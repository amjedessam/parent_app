import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parent/theme/app_theme.dart';
import 'package:parent/theme/parent_app_colors.dart';
import '../models/test_model.dart';

class ChildTestDetailsView extends StatelessWidget {
  const ChildTestDetailsView({super.key});

  // ✅ يستخدم percentage (0-100) بدلاً من score (obtained_marks)
  Color _getScoreColor(double pct) {
    if (pct >= 90) return AppColors.scoreExcellent;
    if (pct >= 80) return AppColors.scoreGood;
    if (pct >= 70) return AppColors.scoreAverage;
    return AppColors.scorePoor;
  }

  @override
  Widget build(BuildContext context) {
    final test = Get.arguments as TestModel;
    final pct = test.percentage;
    final color = _getScoreColor(pct);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.heroGradientStart,
          title: const Text('تفاصيل الاختبار'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            onPressed: () => Get.back(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ─── بطاقة الدرجة ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (test.subject.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      test.subject,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailBox(
                          icon: Icons.assessment_rounded,
                          label: 'النسبة المئوية',
                          // ✅ percentage من DB
                          value: '${pct.toStringAsFixed(1)}%',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailBox(
                          icon: Icons.grading_rounded,
                          label: 'الدرجة',
                          // عرض obtained / total
                          value:
                              '${test.score.toInt()} / ${test.totalQuestions}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── معلومات الاختبار ────────────────────────────
            _InfoCard(
              title: 'معلومات الاختبار',
              children: [
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'التاريخ',
                  value:
                      '${test.date.day}/${test.date.month}/${test.date.year}',
                ),
                if (test.duration.inSeconds > 0) ...[
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.timer_rounded,
                    label: 'المدة',
                    value: _formatDuration(test.duration),
                  ),
                ],
                if (test.subject.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.book_rounded,
                    label: 'المادة',
                    value: test.subject,
                  ),
                ],
                // difficulty فقط إذا موجود في details
                if (test.details['difficulty'] != null) ...[
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.signal_cellular_alt_rounded,
                    label: 'مستوى الصعوبة',
                    value: test.details['difficulty'].toString(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // ─── تحليل الأداء ────────────────────────────────
            _InfoCard(
              title: 'تحليل الأداء',
              children: [
                _PerformanceBar(
                  label: 'النسبة المئوية',
                  percentage: pct,
                  color: color,
                ),
                if (test.totalQuestions > 0) ...[
                  const SizedBox(height: 16),
                  _PerformanceBar(
                    label: 'الدرجة الخام',
                    percentage:
                        pct, // نفس القيمة لأن obtained/total = percentage
                    color: AppColors.info,
                    valueLabel:
                        '${test.score.toInt()} / ${test.totalQuestions}',
                  ),
                ],
              ],
            ),

            // ─── المواضيع المغطاة (فقط إذا موجودة) ─────────
            if (test.details['topics'] is List &&
                (test.details['topics'] as List).isNotEmpty) ...[
              const SizedBox(height: 20),
              _InfoCard(
                title: 'المواضيع المغطاة',
                children: [
                  ...(test.details['topics'] as List).map(
                    (topic) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              topic.toString(),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0)
      return '${d.inHours} ساعة ${d.inMinutes.remainder(60)} دقيقة';
    return '${d.inMinutes} دقيقة';
  }
}

// ════════════════════════════════════════════════════════════
// WIDGETS
// ════════════════════════════════════════════════════════════

class _DetailBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.info, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PerformanceBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;
  final String? valueLabel;

  const _PerformanceBar({
    required this.label,
    required this.percentage,
    required this.color,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final display = valueLabel ?? '${percentage.toStringAsFixed(1)}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              display,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (percentage / 100).clamp(0.0, 1.0),
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }
}
