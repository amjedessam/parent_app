import 'package:flutter/material.dart';
import 'package:parent/theme/parent_app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String _font = 'Cairo';

  // ─── Display ──────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: parentappcolors.textPrimary,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _font,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: parentappcolors.textPrimary,
    height: 1.25,
    letterSpacing: -0.3,
  );

  // ─── Headings ─────────────────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: parentappcolors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: parentappcolors.textPrimary,
    height: 1.35,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: parentappcolors.textPrimary,
    height: 1.4,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: parentappcolors.textPrimary,
    height: 1.4,
  );

  // ─── Body ─────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: parentappcolors.textPrimary,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: parentappcolors.textPrimary,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: parentappcolors.textSecondary,
    height: 1.5,
  );

  // ─── Caption ──────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: parentappcolors.textTertiary,
    height: 1.4,
  );

  static const TextStyle captionMedium = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: parentappcolors.textSecondary,
    height: 1.4,
  );

  static const TextStyle captionBold = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: parentappcolors.textSecondary,
    height: 1.4,
  );

  // ─── Labels ───────────────────────────────────────────────────
  static const TextStyle label = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: parentappcolors.textSecondary,
    height: 1.4,
  );

  static const TextStyle labelBold = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: parentappcolors.textPrimary,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: parentappcolors.textSecondary,
    height: 1.4,
  );

  // ─── Buttons ──────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );

  static const TextStyle buttonOutlined = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: parentappcolors.primary,
    height: 1.2,
  );

  // ─── Stats & Numbers ──────────────────────────────────────────
  /// للأرقام على خلفيات فاتحة
  static const TextStyle statNumber = TextStyle(
    fontFamily: _font,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: parentappcolors.textPrimary,
    height: 1.2,
  );

  /// للأرقام على خلفيات داكنة (Hero card)
  static const TextStyle statNumberOnDark = TextStyle(
    fontFamily: _font,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.2,
  );

  static const TextStyle statLabel = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: parentappcolors.textSecondary,
    height: 1.3,
  );

  static const TextStyle statLabelOnDark = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.3,
  );

  // ─── Score Colors ─────────────────────────────────────────────
  static const TextStyle scoreExcellent = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: parentappcolors.scoreExcellent,
    height: 1.2,
  );

  static const TextStyle scoreGood = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: parentappcolors.scoreGood,
    height: 1.2,
  );

  static const TextStyle scoreAverage = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: parentappcolors.scoreAverage,
    height: 1.2,
  );

  static const TextStyle scorePoor = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: parentappcolors.scorePoor,
    height: 1.2,
  );

  // ─── Navigation ───────────────────────────────────────────────
  static const TextStyle navLabel = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}
