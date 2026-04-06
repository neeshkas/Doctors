// Тема приложения DoctorsHunter CRM
// Все цвета, стили и визуальные настройки бренда

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Константы цветов и тема приложения DoctorsHunter
class AppTheme {
  AppTheme._();

  // ============================================================
  // Цвета бренда
  // ============================================================

  /// Основной цвет бренда — бирюзовый
  static const Color primaryColor = Color(0xFF40BCA0);

  /// Тёмный цвет текста
  static const Color darkText = Color(0xFF0F1322);

  /// Вторичный цвет текста (серый)
  static const Color secondaryText = Color(0xFF7A7A7A);

  /// Светлый фон
  static const Color lightBg = Color(0xFFF4F4F4);

  /// Цвет границ
  static const Color borderColor = Color(0xFFE4E6ED);

  /// Цвет ошибки
  static const Color errorColor = Color(0xFFD80027);

  /// Белый цвет
  static const Color white = Color(0xFFFFFFFF);

  // ============================================================
  // Радиусы скругления
  // ============================================================

  /// Скругление кнопок
  static const double buttonRadius = 16.0;

  /// Скругление карточек
  static const double cardRadius = 24.0;

  // ============================================================
  // URL логотипа
  // ============================================================

  /// URL логотипа DoctorsHunter (сетевое изображение)
  static const String logoUrl = 'https://doctorshunter.com/logo.svg';

  // ============================================================
  // Тема Material
  // ============================================================

  /// Основная тема приложения
  static ThemeData get themeData {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBg,

      // Цветовая схема
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: white,
        secondary: primaryColor,
        onSecondary: white,
        error: errorColor,
        onError: white,
        surface: white,
        onSurface: darkText,
      ),

      // Типографика на основе Inter
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: darkText),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: darkText),
        displaySmall: baseTextTheme.displaySmall?.copyWith(color: darkText),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: darkText),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: darkText),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: darkText),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: darkText,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: darkText,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          color: darkText,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: darkText),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: darkText),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: secondaryText),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: white,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: secondaryText),
        labelSmall: baseTextTheme.labelSmall?.copyWith(color: secondaryText),
      ),

      // Тема AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),

      // Тема карточек
      cardTheme: CardTheme(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: borderColor),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // Тема кнопок ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Тема кнопок OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Тема кнопок TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Тема полей ввода
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: secondaryText),
        hintStyle: GoogleFonts.inter(color: secondaryText),
        errorStyle: GoogleFonts.inter(color: errorColor, fontSize: 12),
      ),

      // Тема Divider
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // Тема чипов
      chipTheme: ChipThemeData(
        backgroundColor: lightBg,
        selectedColor: primaryColor.withOpacity(0.15),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: darkText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          side: const BorderSide(color: borderColor),
        ),
      ),

      // Тема навигационного бокового меню
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: white,
        selectedIconTheme: IconThemeData(color: primaryColor),
        unselectedIconTheme: IconThemeData(color: secondaryText),
        indicatorColor: Color(0x2640BCA0),
      ),

      // Тема диалогов
      dialogTheme: DialogTheme(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Тема SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkText,
        contentTextStyle: GoogleFonts.inter(color: white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
