import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:parent/theme/app_theme.dart';
import 'package:parent/theme/parent_app_colors.dart';
import '../models/test_model.dart';

/// مخطط تطور الدرجات — يعرض النسبة المئوية الصحيحة من DB
class ScoreProgressionLineChart extends StatelessWidget {
  final List<TestModel> tests;

  const ScoreProgressionLineChart({super.key, required this.tests});

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) return const SizedBox.shrink();

    final sortedTests = List<TestModel>.from(tests)
      ..sort((a, b) => a.date.compareTo(b.date));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMedium,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= sortedTests.length) {
                  return const Text('');
                }
                return Text(
                  'اختبار ${idx + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMedium,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            // ✅ test.percentage بدلاً من test.score
            spots: List.generate(
              sortedTests.length,
              (index) => FlSpot(
                index.toDouble(),
                sortedTests[index].percentage.clamp(0.0, 100.0),
              ),
            ),
            isCurved: true,
            color: AppColors.success,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.success,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.3),
                  AppColors.success.withOpacity(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
