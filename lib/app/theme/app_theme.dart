import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData buildTheme(TextTheme baseTextTheme) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF9D5C),
      brightness: Brightness.dark,
    );

    final colorScheme = baseScheme.copyWith(
      primary: const Color(0xFFFF9D5C),
      onPrimary: const Color(0xFF2C0D00),
      primaryContainer: const Color(0xFF382014),
      onPrimaryContainer: const Color(0xFFFFE3D4),
      secondary: const Color(0xFF75D6C3),
      onSecondary: const Color(0xFF01201A),
      secondaryContainer: const Color(0xFF1D3B35),
      onSecondaryContainer: const Color(0xFFCAFFF1),
      background: const Color(0xFF0C131F),
      onBackground: const Color(0xFFE4E9F3),
      surface: const Color(0xFF141C2B),
      onSurface: const Color(0xFFDCE2EE),
      surfaceVariant: const Color(0xFF1B2434),
      outline: const Color(0xFF323B4C),
      outlineVariant: const Color(0xFF232B3A),
      error: const Color(0xFFF28B82),
      onError: const Color(0xFF2C0B0D),
    );

    final textTheme = baseTextTheme.apply(
      bodyColor: colorScheme.onBackground,
      displayColor: colorScheme.onBackground,
    );

    final surfaceTint = Color.alphaBlend(
      colorScheme.primary.withOpacity(0.08),
      colorScheme.surface,
    );
    final borderColor = Color.alphaBlend(
      colorScheme.onSurface.withOpacity(0.05),
      colorScheme.surface,
    );
    final subtleBorder = Color.alphaBlend(
      colorScheme.onSurface.withOpacity(0.03),
      colorScheme.surface,
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
          colorScheme.primary.withOpacity(0.06),
          colorScheme.surface,
        ),
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
        margin: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: subtleBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: surfaceTint,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: borderColor),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: borderColor),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
          colorScheme.primary.withOpacity(0.07),
          colorScheme.surface,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
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
          borderSide: BorderSide(
            color: colorScheme.primary.withOpacity(0.75),
            width: 1.4,
          ),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color.alphaBlend(
          colorScheme.primary.withOpacity(0.12),
          colorScheme.surface,
        ),
        disabledColor: colorScheme.onSurface.withOpacity(0.12),
        selectedColor: colorScheme.primary.withOpacity(0.24),
        secondarySelectedColor: colorScheme.primary.withOpacity(0.28),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        labelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
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
      dialogTheme: DialogTheme(
        backgroundColor: surfaceTint,
        surfaceTintColor: surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        contentTextStyle: textTheme.bodyMedium,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        iconColor: colorScheme.onSurface,
        textColor: colorScheme.onSurface,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceTint,
        surfaceTintColor: surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
