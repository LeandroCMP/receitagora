import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData buildTheme(TextTheme baseTextTheme) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5BE49B),
      brightness: Brightness.dark,
    );

    final colorScheme = baseScheme.copyWith(
      primary: const Color(0xFF5BE49B),
      onPrimary: const Color(0xFF002112),
      primaryContainer: const Color(0xFF1A6D4A),
      secondary: const Color(0xFF8AB4F8),
      onSecondary: const Color(0xFF04142C),
      tertiary: const Color(0xFFF6A7C1),
      background: const Color(0xFF0F172A),
      surface: const Color(0xFF131D2E),
      surfaceVariant: const Color(0xFF1E2A3D),
      outline: const Color(0xFF3C4A63),
      error: const Color(0xFFF97066),
      onError: const Color(0xFF2C0B0D),
    );

    final textTheme = baseTextTheme.apply(
      bodyColor: colorScheme.onBackground,
      displayColor: colorScheme.onBackground,
    );

    final surfaceTint = Color.alphaBlend(
      colorScheme.primary.withOpacity(0.04),
      colorScheme.surface,
    );
    final borderColor = Color.alphaBlend(
      colorScheme.onSurface.withOpacity(0.1),
      colorScheme.surface,
    );
    final subtleBorder = Color.alphaBlend(
      colorScheme.onSurface.withOpacity(0.06),
      colorScheme.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceTint,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceTint,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: subtleBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: borderColor),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color.alphaBlend(
          colorScheme.primary.withOpacity(0.08),
          colorScheme.surface,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: subtleBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: subtleBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.8), width: 1.6),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color.alphaBlend(
          colorScheme.primary.withOpacity(0.14),
          colorScheme.surface,
        ),
        disabledColor: colorScheme.onSurface.withOpacity(0.12),
        selectedColor: colorScheme.primary.withOpacity(0.22),
        secondarySelectedColor: colorScheme.primary.withOpacity(0.28),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color.alphaBlend(
          colorScheme.primary.withOpacity(0.12),
          colorScheme.surface,
        ),
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: subtleBorder,
        thickness: 1,
        space: 24,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        iconColor: colorScheme.onSurface,
        textColor: colorScheme.onSurface,
      ),
    );
  }
}
