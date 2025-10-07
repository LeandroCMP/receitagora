import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData buildTheme(TextTheme baseTextTheme) {
    const primary = Color(0xFFFFC24C);
    const primaryContainer = Color(0xFF2F2412);
    const background = Color(0xFF16171B);
    const surface = Color(0xFF1F2025);
    const surfaceVariant = Color(0xFF24252B);
    const onSurface = Color(0xFFECEEF6);
    const outline = Color(0xFF35363F);

    final colorScheme = const ColorScheme.dark().copyWith(
      primary: primary,
      onPrimary: const Color(0xFF201100),
      primaryContainer: primaryContainer,
      onPrimaryContainer: const Color(0xFFFFF2D8),
      secondary: const Color(0xFFFF7257),
      onSecondary: const Color(0xFF2B0400),
      secondaryContainer: const Color(0xFF3B1810),
      onSecondaryContainer: const Color(0xFFFFE0D6),
      background: background,
      onBackground: onSurface,
      surface: surface,
      onSurface: onSurface,
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: onSurface.withOpacity(0.7),
      outline: outline,
      outlineVariant: Color.alphaBlend(Colors.white.withOpacity(0.04), outline),
      error: const Color(0xFFFF6F6F),
      onError: const Color(0xFF2B0103),
    );

    final textTheme = baseTextTheme.apply(
      bodyColor: colorScheme.onBackground,
      displayColor: colorScheme.onBackground,
    );

    final surfaceTint = Color.alphaBlend(
      colorScheme.primary.withOpacity(0.05),
      colorScheme.surface,
    );
    final borderColor = Color.alphaBlend(
      colorScheme.onSurface.withOpacity(0.08),
      colorScheme.surface,
    );
    final subtleBorder = Color.alphaBlend(
      colorScheme.onSurface.withOpacity(0.05),
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
          colorScheme.primary.withOpacity(0.04),
          colorScheme.surface,
        ),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceTint,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
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
            borderRadius: BorderRadius.circular(22),
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
            borderRadius: BorderRadius.circular(22),
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
            borderRadius: BorderRadius.circular(22),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: subtleBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: subtleBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: colorScheme.primary.withOpacity(0.9),
            width: 1.6,
          ),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color.alphaBlend(
          colorScheme.primary.withOpacity(0.16),
          colorScheme.surface,
        ),
        disabledColor: colorScheme.onSurface.withOpacity(0.1),
        selectedColor: colorScheme.primary.withOpacity(0.25),
        secondarySelectedColor: colorScheme.primary.withOpacity(0.28),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          colorScheme.primary.withOpacity(0.14),
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
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        contentTextStyle: textTheme.bodyMedium,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
