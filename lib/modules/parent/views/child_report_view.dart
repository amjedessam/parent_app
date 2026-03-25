import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parent/routes/app_routes.dart';
import 'package:parent/theme/app_theme.dart';
import 'package:parent/theme/parent_app_colors.dart';
import '../models/child_model.dart';
import '../models/subject_performance_model.dart';
import '../widgets/score_chart.dart';
import '../widgets/test_list_item.dart';

class ChildReportView extends StatefulWidget {
  const ChildReportView({super.key});

  @override
  State<ChildReportView> createState() => _ChildReportViewState();
}

class _ChildReportViewState extends State<ChildReportView>
    with SingleTickerProviderStateMixin {
  late ChildModel child;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    child = Get.arguments as ChildModel;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── نسبة للون ───────────────────────────────────────────
  Color _scoreColor(double score) {
    if (score >= 90) return AppColors.scoreExcellent;
    if (score >= 80) return AppColors.scoreGood;
    if (score >= 70) return AppColors.scoreAverage;
    if (score > 0) return AppColors.scorePoor;
    return const Color(0xFF94A3B8);
  }

  String _scoreLabel(double score) {
    if (score >= 90) return 'ممتاز';
    if (score >= 80) return 'جيد جداً';
    if (score >= 70) return 'جيد';
    if (score >= 60) return 'مقبول';
    if (score > 0) return 'يحتاج تحسين';
    return 'لا يوجد';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerScrolled) => [
            _buildSliverAppBar(),
          ],
          body: _buildBody(),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // SLIVER APP BAR — gradient + student info
  // ════════════════════════════════════════════════════════
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 290,
      pinned: true,
      backgroundColor: AppColors.heroGradientStart,
      leading: IconButton(
        icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      // actions: [
      //   IconButton(
      //     icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
      //     onPressed: () => Get.snackbar('تصدير', 'تم تصدير التقرير بنجاح'),
      //   ),
      // ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [AppColors.primary, AppColors.gradientEnd],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 52, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // اسم الطالب والصف
                  Row(
                    children: [
                      // الأفاتار
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            child.name.isNotEmpty ? child.name[0] : '؟',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              child.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.school_rounded,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  child.grade +
                                      (child.sectionName != null
                                          ? ' — ${child.sectionName}'
                                          : ''),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // بطاقتا الدرجات
                  Row(
                    children: [
                      Expanded(
                        child: _GradientStatCard(
                          label: 'آخر اختبار',
                          value: child.latestScore > 0
                              ? '${child.latestScore.toStringAsFixed(1)}%'
                              : '—',
                          sublabel: child.latestScore > 0
                              ? _scoreLabel(child.latestScore)
                              : 'لا يوجد اختبار بعد',
                          icon: Icons.trending_up_rounded,
                          accentColor: _scoreColor(child.latestScore),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GradientStatCard(
                          label: 'المعدل العام',
                          value: child.averageScore > 0
                              ? '${child.averageScore.toStringAsFixed(1)}%'
                              : '—',
                          sublabel: child.averageScore > 0
                              ? _scoreLabel(child.averageScore)
                              : 'لا يوجد بيانات',
                          icon: Icons.bar_chart_rounded,
                          accentColor: _scoreColor(child.averageScore),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'المواد'),
          Tab(text: 'الدرجات'),
          Tab(text: 'الاختبارات'),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // BODY — TabBarView
  // ════════════════════════════════════════════════════════
  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: [_buildSubjectsTab(), _buildScoresTab(), _buildTestsTab()],
    );
  }

  // ════════════════════════════════════════════════════════
  // TAB 1: المواد الدراسية
  // ════════════════════════════════════════════════════════
  Widget _buildSubjectsTab() {
    if (child.subjectPerformances.isEmpty) {
      return _buildEmptyState(
        icon: Icons.menu_book_rounded,
        message: 'لا توجد مواد دراسية مسجلة لهذا الطالب',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // ملخص عدد المواد
        _SubjectsSummaryHeader(
          total: child.subjectPerformances.length,
          withExams: child.subjectPerformances.where((s) => s.hasExams).length,
        ),
        const SizedBox(height: 16),

        // بطاقة لكل مادة
        ...child.subjectPerformances.map(
          (subject) => _SubjectPerformanceCard(subject: subject),
        ),

        // ─── قسم التدريب الذاتي ──────────────────────────
        _buildPracticeSection(),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // TAB 2: تطور الدرجات
  // ════════════════════════════════════════════════════════
  Widget _buildScoresTab() {
    if (child.testHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.show_chart_rounded,
        message: 'لا توجد اختبارات مكتملة حتى الآن',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      color: AppColors.success,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'تطور الدرجات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: ScoreProgressionLineChart(tests: child.testHistory),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // إحصائيات سريعة
        _buildQuickStats(),
      ],
    );
  }

  Widget _buildQuickStats() {
    final tests = child.testHistory;
    if (tests.isEmpty) return const SizedBox.shrink();

    // ✅ test.percentage يقرأ من DB (generated column) مباشرة
    final scores = tests.map((t) => t.percentage).toList();
    final highest = scores.reduce((a, b) => a > b ? a : b);
    final lowest = scores.reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _QuickStatItem(
              label: 'عدد الاختبارات',
              value: '${tests.length}',
              icon: Icons.quiz_rounded,
              color: AppColors.primary,
            ),
          ),
          _divider(),
          Expanded(
            child: _QuickStatItem(
              label: 'أعلى درجة',
              value: '${highest.toStringAsFixed(1)}%',
              icon: Icons.emoji_events_rounded,
              color: AppColors.scoreExcellent,
            ),
          ),
          _divider(),
          Expanded(
            child: _QuickStatItem(
              label: 'أدنى درجة',
              value: '${lowest.toStringAsFixed(1)}%',
              icon: Icons.south_rounded,
              color: AppColors.scorePoor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 50, color: Colors.grey.shade100);

  // ════════════════════════════════════════════════════════
  // PRACTICE SECTION — يُضاف في نهاية تبويب المواد
  // ════════════════════════════════════════════════════════
  Widget _buildPracticeSection() {
    if (child.practiceAttempts == 0) return const SizedBox.shrink();

    final lastDate = child.practiceLastAttemptAt;
    final dateStr = lastDate != null
        ? '${lastDate.year}/${lastDate.month.toString().padLeft(2, '0')}/${lastDate.day.toString().padLeft(2, '0')}'
        : '—';

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── عنوان القسم ────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B70F5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.self_improvement_rounded,
                    color: Color(0xFF6B70F5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'التدريب الذاتي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ─── إحصائيات 4 خانات ───────────────────────────
            Row(
              children: [
                Expanded(
                  child: _PracticeStatBox(
                    label: 'عدد الاختبارات',
                    value: '${child.practiceAttempts}',
                    color: const Color(0xFF6B70F5),
                    icon: Icons.quiz_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PracticeStatBox(
                    label: 'المعدل',
                    value: '${child.practiceAverageScore.toStringAsFixed(1)}%',
                    color: child.practiceAverageScore >= 70
                        ? AppColors.scoreGood
                        : AppColors.scorePoor,
                    icon: Icons.bar_chart_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PracticeStatBox(
                    label: 'إجابات صحيحة',
                    value: '${child.practiceTotalCorrect}',
                    color: AppColors.scoreExcellent,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PracticeStatBox(
                    label: 'إجابات خاطئة',
                    value: '${child.practiceTotalWrong}',
                    color: AppColors.scorePoor,
                    icon: Icons.cancel_outlined,
                  ),
                ),
              ],
            ),
            // ─── آخر محاولة ─────────────────────────────────
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.textMedium,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'آخر محاولة: $dateStr',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),

            // ─── تفاصيل المواد ───────────────────────────────
            if (child.practiceSubjectsSummary.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),
              const Text(
                'أداء المواد في التدريب',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              ...child.practiceSubjectsSummary.map((subj) {
                final name = subj['subject_name']?.toString() ?? 'مادة';
                final icon = subj['subject_icon']?.toString() ?? '📚';
                final attempts = (subj['attempts'] as num?)?.toInt() ?? 0;
                final avg = (subj['average_score'] as num?)?.toDouble() ?? 0.0;
                final correct = (subj['total_correct'] as num?)?.toInt() ?? 0;
                final wrong = (subj['total_wrong'] as num?)?.toInt() ?? 0;
                final color = avg >= 70
                    ? AppColors.scoreGood
                    : AppColors.scorePoor;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${avg.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: avg / 100,
                          backgroundColor: color.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 12,
                            color: AppColors.textMedium,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$attempts اختبار',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMedium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.check_circle_outline,
                            size: 12,
                            color: AppColors.scoreExcellent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$correct صح',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.scoreExcellent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.cancel_outlined,
                            size: 12,
                            color: AppColors.scorePoor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$wrong خطأ',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.scorePoor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // TAB 3: سجل الاختبارات
  // ════════════════════════════════════════════════════════
  Widget _buildTestsTab() {
    if (child.testHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_edu_rounded,
        message: 'لا توجد اختبارات مكتملة حتى الآن',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 4),
          child: Text(
            'الاختبارات المكتملة (${child.testHistory.length})',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
        ),
        ...child.testHistory.map(
          (test) => ModernTestListItem(
            test: test,
            onTap: () => Get.toNamed(
              AppRoutes.PARENT_CHILD_TEST_DETAILS,
              arguments: test,
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // EMPTY STATE
  // ════════════════════════════════════════════════════════
  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// WIDGETS
// ════════════════════════════════════════════════════════════

/// بطاقة إحصاء بيضاء شفافة في الـ header
class _GradientStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final IconData icon;
  final Color accentColor;

  const _GradientStatCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sublabel,
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

/// رأس قسم المواد — يعرض عدد المواد وعدد التي لها اختبارات
class _SubjectsSummaryHeader extends StatelessWidget {
  final int total;
  final int withExams;

  const _SubjectsSummaryHeader({required this.total, required this.withExams});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.gradientEnd],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المواد الدراسية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$withExams من $total مادة لديها اختبارات مسجلة',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$total',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة أداء مادة واحدة
class _SubjectPerformanceCard extends StatelessWidget {
  final SubjectPerformanceModel subject;

  const _SubjectPerformanceCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── صف العنوان ─────────────────────────────────
            Row(
              children: [
                // أيقونة المادة مع لونها
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: subject.subjectColorLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: subject.subjectColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      subject.icon,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // اسم المادة والمعدل
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subject.subjectName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subject.hasExams
                            ? '${subject.totalExams} اختبار مكتمل'
                            : 'لا توجد اختبارات بعد',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),

                // badge الأداء
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: subject.performanceBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    subject.hasExams
                        ? '${subject.averageScore.toStringAsFixed(1)}%'
                        : '—',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: subject.performanceColor,
                    ),
                  ),
                ),
              ],
            ),

            // ─── شريط التقدم ─────────────────────────────────
            if (subject.hasExams) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: subject.progressValue,
                        backgroundColor: subject.subjectColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          subject.performanceColor,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    subject.performanceLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subject.performanceColor,
                    ),
                  ),
                ],
              ),

              // ─── آخر اختبار ──────────────────────────────
              if (subject.lastScore != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 14,
                        color: AppColors.textMedium,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'آخر اختبار: ${subject.lastExamTitle ?? ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${subject.lastScore!.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: subject.performanceColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// بطاقة إحصاء للتدريب الذاتي
class _PracticeStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _PracticeStatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// عنصر إحصاء صغير في تبويب الدرجات
class _QuickStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
