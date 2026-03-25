import 'package:flutter/material.dart';

class parentappcolors {
  parentappcolors._();

  // ─── Primary — Sky Blue ───────────────────────────────────────
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF1565C0);

  static const Color primarySurface = Color(0xFFE3F2FD);
  static const Color primaryBorder = Color(0xFFBBDEFB);

  // ─── Secondary — Deep Blue ────────────────────────────────────
  static const Color secondary = Color(0xFF0288D1);
  static const Color secondaryLight = Color(0xFF29B6F6);
  static const Color secondaryDark = Color(0xFF01579B);

  static const Color secondarySurface = Color(0xFFE1F5FE);
  static const Color secondaryBorder = Color(0xFFB3E5FC);

  // ─── Accent — Cyan ────────────────────────────────────────────
  static const Color accent = Color(0xFF00ACC1);
  static const Color accentSurface = Color(0xFFE0F7FA);

  // ─── Semantic Colors ──────────────────────────────────────────
  static const Color success = Color(0xFF43A047);
  static const Color successLight = Color(0xFF66BB6A);
  static const Color successSurface = Color(0xFFE8F5E9);

  static const Color warning = Color(0xFFFB8C00);
  static const Color warningSurface = Color(0xFFFFF3E0);

  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorSurface = Color(0xFFFFEBEE);

  static const Color info = Color(0xFF1E88E5);
  static const Color infoSurface = Color(0xFFE3F2FD);

  // ─── Score Colors (للدرجات) ───────────────────────────────────
  static const Color scoreExcellent = Color(0xFF43A047); // ≥ 85%
  static const Color scoreGood = Color(0xFF1E88E5); // ≥ 70%
  static const Color scoreAverage = Color(0xFFFB8C00); // ≥ 50%
  static const Color scorePoor = Color(0xFFE53935); // < 50%

  // ─── Backgrounds ──────────────────────────────────────────────
  static const Color background = Color(0xFFF4F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // ─── Text ─────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A237E); // أزرق داكن جداً
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color textTertiary = Color(0xFF90A4AE);
  static const Color textDisabled = Color(0xFFB0BEC5);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textHint = Color(0xFFB0BEC5);

  // Backward-compatible aliases
  static const Color textWhite = Color(0xFFFFFFFF);

  // ─── Border & Divider ─────────────────────────────────────────
  static const Color border = Color(0xFFE0E7EF);
  static const Color borderDark = Color(0xFFCFD8DC);
  static const Color divider = Color(0xFFF0F4F8);

  // ─── Shadows ──────────────────────────────────────────────────
  static const Color shadowSoft = Color(0x0C1E88E5);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowCard = Color(0x0E1A237E);

  // ─── Card ─────────────────────────────────────────────────────
  static const Color cardBg = Color(0xFFFFFFFF);

  // ─── Difficulty Colors ────────────────────────────────────────
  static const Color easyColor = Color(0xFF43A047);
  static const Color mediumColor = Color(0xFFFB8C00);
  static const Color hardColor = Color(0xFFE53935);

  // ─── Chart Colors ─────────────────────────────────────────────
  static const List<Color> chartColors = [
    Color(0xFF1E88E5), // Primary Blue
    Color(0xFF43A047), // Green
    Color(0xFFFB8C00), // Orange
    Color(0xFF8E24AA), // Purple
    Color(0xFF00ACC1), // Cyan
    Color(0xFFE53935), // Red
    Color(0xFF3949AB), // Indigo
    Color(0xFF00897B), // Teal
  ];

  // ─── Gradients ────────────────────────────────────────────────
  /// Gradient رئيسي — للـ AppBar والـ Headers
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradient ناعم للبطاقات
  static const LinearGradient primarySoftGradient = LinearGradient(
    colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Gradient أفقي — للبانرات والـ Hero cards
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E88E5), Color(0xFF0288D1)],
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF43A047), Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFB8C00), Color(0xFFF57C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFC62828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Role Selection Gradient ──────────────────────────────────
  static const List<Color> roleSelectionGradient = [
    Color(0xFF1E88E5),
    Color(0xFF1565C0),
  ];

  // ─── Shimmer ──────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFDCEAFA);
  static const Color shimmerHighlight = Color(0xFFEEF5FD);

  // ─── Backward-Compatible aliases ─────────────────────────────
  static const Color scaffoldBg = background;
}

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = parentappcolors.primary;
  static const Color primaryLight = parentappcolors.primaryLight;
  static const Color primaryDark = parentappcolors.primaryDark;
  static const Color primarySurface = parentappcolors.primarySurface;
  static const Color primaryBorder = parentappcolors.primaryBorder;

  // Secondary
  static const Color secondary = parentappcolors.secondary;
  static const Color secondaryLight = parentappcolors.secondaryLight;
  static const Color secondaryDark = parentappcolors.secondaryDark;

  // Accent
  static const Color accent = parentappcolors.accent;

  // Semantic
  static const Color success = parentappcolors.success;
  static const Color successSurface = parentappcolors.successSurface;
  static const Color warning = parentappcolors.warning;
  static const Color warningSurface = parentappcolors.warningSurface;
  static const Color error = parentappcolors.error;
  static const Color errorSurface = parentappcolors.errorSurface;
  static const Color info = parentappcolors.info;
  static const Color infoSurface = parentappcolors.infoSurface;

  // Score
  static const Color scoreExcellent = parentappcolors.scoreExcellent;
  static const Color scoreGood = parentappcolors.scoreGood;
  static const Color scoreAverage = parentappcolors.scoreAverage;
  static const Color scorePoor = parentappcolors.scorePoor;

  // Background
  static const Color background = parentappcolors.background;
  static const Color backgroundLight = parentappcolors.background;
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surface = parentappcolors.surface;
  static const Color cardDark = Color(0xFF1E293B);

  // Text — هذه الأسماء هي ما يستخدمه المشروع
  static const Color textDark = parentappcolors.textPrimary;
  static const Color textMedium = parentappcolors.textSecondary;
  static const Color textLight = parentappcolors.textTertiary;
  static const Color textPrimary = parentappcolors.textPrimary;
  static const Color textSecondary = parentappcolors.textSecondary;
  static const Color textTertiary = parentappcolors.textTertiary;
  static const Color textDisabled = parentappcolors.textDisabled;
  static const Color textOnPrimary = parentappcolors.textOnPrimary;
  static const Color textWhite = parentappcolors.textOnPrimary;
  static const Color textHint = parentappcolors.textHint;

  // Border & Divider
  static const Color border = parentappcolors.border;
  static const Color borderDark = parentappcolors.borderDark;
  static const Color divider = parentappcolors.divider;

  // Shadows
  static const Color shadowSoft = parentappcolors.shadowSoft;
  static const Color shadowMedium = parentappcolors.shadowMedium;
  static const Color shadowCard = parentappcolors.shadowCard;

  // Difficulty
  static const Color easyColor = parentappcolors.easyColor;
  static const Color mediumColor = parentappcolors.mediumColor;
  static const Color hardColor = parentappcolors.hardColor;

  // Dashboard specific
  static const Color studentsColor = Color(0xFF1E88E5);
  static const Color reportsColor = Color(0xFF8E24AA);
  static const Color messagesColor = Color(0xFF00ACC1);

  // Gradient colors
  static const Color gradientStart = parentappcolors.primary;
  static const Color gradientEnd = parentappcolors.secondary;
  static const Color heroGradientStart = parentappcolors.primary;
  static const Color heroGradientEnd = parentappcolors.secondary;

  // Gradients
  static const LinearGradient primaryGradient = parentappcolors.primaryGradient;
  static const LinearGradient primarySoftGradient =
      parentappcolors.primarySoftGradient;
  static const LinearGradient heroGradient = parentappcolors.heroGradient;
  static const LinearGradient successGradient = parentappcolors.successGradient;
  static const LinearGradient warningGradient = parentappcolors.warningGradient;
  static const LinearGradient errorGradient = parentappcolors.errorGradient;

  // Chart & Shimmer
  static const List<Color> chartColors = parentappcolors.chartColors;
  static const Color shimmerBase = parentappcolors.shimmerBase;
  static const Color shimmerHighlight = parentappcolors.shimmerHighlight;
}
