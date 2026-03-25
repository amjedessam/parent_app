import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:parent/theme/app_theme.dart';
import 'package:parent/theme/parent_app_colors.dart';

/// Modern Curriculum Gap Bar Chart using fl_chart
class CurriculumGapBarChart extends StatelessWidget {
  final Map<String, double> gaps;

  const CurriculumGapBarChart({super.key, required this.gaps});

  Color _getGapColor(double gap) {
    if (gap < 10) return AppColors.scoreExcellent;
    if (gap < 20) return AppColors.scoreAverage;
    return AppColors.scorePoor;
  }

  @override
  Widget build(BuildContext context) {
    final sortedGaps = gaps.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 35,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${sortedGaps[group.x.toInt()].key}\n${rod.toY.toStringAsFixed(1)}%',
                const TextStyle(
                  // fontFamily: 'Cairo',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= sortedGaps.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    sortedGaps[value.toInt()].key,
                    style: const TextStyle(
                      // fontFamily: 'Cairo',
                      fontSize: 10,
                      color: AppColors.textMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(
                    // fontFamily: 'Cairo',
                    fontSize: 10,
                    color: AppColors.textMedium,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(sortedGaps.length, (index) {
          final gap = sortedGaps[index].value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: gap,
                gradient: LinearGradient(
                  colors: [
                    _getGapColor(gap),
                    _getGapColor(gap).withOpacity(0.7),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 30,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
