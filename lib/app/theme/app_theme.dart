import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData buildTheme(TextTheme baseTextTheme) {
    const seed = Color(0xFFFFC876);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF1A1E27),
      background: const Color(0xFF121521),
      onSurface: const Color(0xFFF5F6FA),
    ).copyWith(
      secondary: const Color(0xFF8ED6FF),
      tertiary: const Color(0xFFFF9AA2),
      surfaceVariant: const Color(0xFF232734),
      outline: const Color(0xFF2E3340),
      outlineVariant: const Color(0xFF3B4050),
      error: const Color(0xFFFF8B7E),
    );

    final textTheme = baseTextTheme.apply(
      bodyColor: colorScheme.onBackground,
      displayColor: colorScheme.onBackground,
      fontFamily: 'Roboto',
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: Color.alphaBlend(
          colorScheme.surface.withOpacity(0.2),
          colorScheme.background,
        ),
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardTheme(
        color: Color.alphaBlend(
          colorScheme.surface.withOpacity(0.72),
          Colors.black.withOpacity(0.1),
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: colorScheme.outline.withOpacity(0.35)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline.withOpacity(0.4)),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: colorScheme.surfaceVariant,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(color: colorScheme.outline.withOpacity(0.35)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color.alphaBlend(
          colorScheme.surface.withOpacity(0.7),
          Colors.black.withOpacity(0.05),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.85), width: 1.6),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.55),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant.withOpacity(0.4),
        disabledColor: colorScheme.surfaceVariant.withOpacity(0.3),
        selectedColor: colorScheme.primary.withOpacity(0.25),
        secondarySelectedColor: colorScheme.primary.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        labelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color.alphaBlend(
          colorScheme.surface.withOpacity(0.9),
          Colors.black.withOpacity(0.3),
        ),
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withOpacity(0.3),
        thickness: 1,
        space: 28,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        contentTextStyle: textTheme.bodyMedium,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
