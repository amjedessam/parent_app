import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parent/theme/parent_app_colors.dart';
import 'package:parent/theme/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',

      // ─── Color Scheme ───────────────────────────────────────
      colorScheme: const ColorScheme.light(
        primary: parentappcolors.primary,
        onPrimary: parentappcolors.textOnPrimary,
        primaryContainer: parentappcolors.primarySurface,
        onPrimaryContainer: parentappcolors.primaryDark,

        secondary: parentappcolors.secondary,
        onSecondary: parentappcolors.textOnPrimary,
        secondaryContainer: parentappcolors.secondarySurface,
        onSecondaryContainer: parentappcolors.secondaryDark,

        tertiary: parentappcolors.accent,
        onTertiary: parentappcolors.textOnPrimary,
        tertiaryContainer: parentappcolors.accentSurface,

        error: parentappcolors.error,
        onError: parentappcolors.textOnPrimary,
        errorContainer: parentappcolors.errorSurface,

        surface: parentappcolors.surface,
        onSurface: parentappcolors.textPrimary,
        surfaceContainerHighest: parentappcolors.background,

        outline: parentappcolors.border,
        outlineVariant: parentappcolors.divider,
      ),

      // ─── Scaffold ───────────────────────────────────────────
      scaffoldBackgroundColor: parentappcolors.background,

      // ─── AppBar ─────────────────────────────────────────────
      // كما في الصورة: AppBar أزرق سماوي solid
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: parentappcolors.primary,
        foregroundColor: parentappcolors.textOnPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 22),
        actionsIconTheme: IconThemeData(color: Colors.white, size: 22),
      ),

      // ─── Card ───────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: parentappcolors.border, width: 1),
        ),
        color: parentappcolors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shadowColor: parentappcolors.shadowCard,
      ),

      // ─── Elevated Button ────────────────────────────────────
      // كما في الصورة: أزرق سماوي solid + radius كبير
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: parentappcolors.primary,
          foregroundColor: parentappcolors.textOnPrimary,
          disabledBackgroundColor: parentappcolors.border,
          disabledForegroundColor: parentappcolors.textDisabled,
          textStyle: AppTextStyles.button,
          shadowColor: Colors.transparent,
        ),
      ),

      // ─── Outlined Button ────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: parentappcolors.primary, width: 1.5),
          foregroundColor: parentappcolors.primary,
          textStyle: AppTextStyles.buttonOutlined,
        ),
      ),

      // ─── Text Button ────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: parentappcolors.primary,
          textStyle: AppTextStyles.button.copyWith(
            color: parentappcolors.primary,
          ),
        ),
      ),

      // ─── FAB ────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: parentappcolors.primary,
        foregroundColor: parentappcolors.textOnPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // ─── Input Decoration ───────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: parentappcolors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: parentappcolors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: parentappcolors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: parentappcolors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: parentappcolors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: parentappcolors.error, width: 2),
        ),
        labelStyle: AppTextStyles.label,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: parentappcolors.textHint,
        ),
        errorStyle: AppTextStyles.captionMedium.copyWith(
          color: parentappcolors.error,
        ),
        prefixIconColor: parentappcolors.textTertiary,
        suffixIconColor: parentappcolors.textTertiary,
      ),

      // ─── Chip ───────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: parentappcolors.primarySurface,
        selectedColor: parentappcolors.primary,
        disabledColor: parentappcolors.divider,
        deleteIconColor: parentappcolors.primary,
        labelStyle: AppTextStyles.labelSmall.copyWith(
          color: parentappcolors.primary,
        ),
        secondaryLabelStyle: AppTextStyles.labelSmall.copyWith(
          color: parentappcolors.textOnPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: parentappcolors.primaryBorder),
        ),
        side: const BorderSide(color: parentappcolors.primaryBorder),
        elevation: 0,
        pressElevation: 0,
        checkmarkColor: Colors.white,
        selectedShadowColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),

      // ─── Divider ────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: parentappcolors.divider,
        thickness: 1,
        space: 1,
      ),

      // ─── Icon ───────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: parentappcolors.textSecondary,
        size: 22,
      ),

      // ─── Bottom Navigation Bar ──────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: parentappcolors.surface,
        selectedItemColor: parentappcolors.primary,
        unselectedItemColor: parentappcolors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        enableFeedback: true,
        selectedLabelStyle: AppTextStyles.navLabel.copyWith(
          color: parentappcolors.primary,
        ),
        unselectedLabelStyle: AppTextStyles.navLabel.copyWith(
          color: parentappcolors.textTertiary,
        ),
      ),

      // ─── NavigationBar (Material3) ──────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: parentappcolors.surface,
        indicatorColor: parentappcolors.primarySurface,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: parentappcolors.primary,
              size: 22,
            );
          }
          return const IconThemeData(
            color: parentappcolors.textTertiary,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.navLabel.copyWith(
              color: parentappcolors.primary,
            );
          }
          return AppTextStyles.navLabel.copyWith(
            color: parentappcolors.textTertiary,
          );
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),

      // ─── Dialog ─────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        shadowColor: parentappcolors.shadowMedium,
        backgroundColor: parentappcolors.surface,
        titleTextStyle: AppTextStyles.h3,
        contentTextStyle: AppTextStyles.bodyMedium,
        surfaceTintColor: Colors.transparent,
      ),

      // ─── Bottom Sheet ───────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: parentappcolors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 8,
        shadowColor: parentappcolors.shadowMedium,
        dragHandleColor: parentappcolors.border,
      ),

      // ─── Snackbar ───────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: parentappcolors.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
        ),
        actionTextColor: parentappcolors.primarySurface,
        elevation: 4,
      ),

      // ─── List Tile ──────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: parentappcolors.textSecondary,
        textColor: parentappcolors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // ─── Progress Indicator ─────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: parentappcolors.primary,
        linearTrackColor: parentappcolors.primarySurface,
        circularTrackColor: parentappcolors.primarySurface,
        linearMinHeight: 6,
      ),

      // ─── Switch ─────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return parentappcolors.textOnPrimary;
          }
          return parentappcolors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return parentappcolors.primary;
          }
          return parentappcolors.border;
        }),
      ),

      // ─── Tab Bar ────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        indicatorColor: parentappcolors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: parentappcolors.primary,
        unselectedLabelColor: parentappcolors.textTertiary,
        labelStyle: AppTextStyles.labelBold,
        unselectedLabelStyle: AppTextStyles.label,
        dividerColor: parentappcolors.border,
        overlayColor: WidgetStateProperty.all(parentappcolors.primarySurface),
      ),

      // ─── Text Theme ─────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        headlineSmall: AppTextStyles.h3,
        titleLarge: AppTextStyles.h3,
        titleMedium: AppTextStyles.h4,
        titleSmall: AppTextStyles.labelBold,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.label,
        labelMedium: AppTextStyles.labelSmall,
        labelSmall: AppTextStyles.caption,
      ),
    );
  }
}

// ─── AppSpacing ───────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double cardPadding = 16.0;
  static const double cardRadius = 16.0;
  static const double cardRadiusLarge = 20.0;
  static const double heroRadius = 24.0;
}

// ─── AppShadows ───────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft = [
    BoxShadow(
      color: parentappcolors.shadowCard,
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(
      color: parentappcolors.shadowMedium,
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> primary = [
    BoxShadow(
      color: parentappcolors.shadowSoft,
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> colored(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
