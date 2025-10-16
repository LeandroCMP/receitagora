import 'package:flutter/material.dart';

import 'theme_extensions.dart';

class ReceitagoraAppUiConfig {
  static const _surfaceContainerLowest = Color(0xFFFFE9D6);
  static const _surfaceContainerLow = Color(0xFFFFDFC6);
  static const _surfaceContainer = Color(0xFFFFF6ED);
  static const _surfaceContainerHigh = Color(0xFFFFEBD9);
  static const _surfaceContainerHighest = Color(0xFFFFFBF8);

  static ThemeData buildTheme(TextTheme baseTextTheme) {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFEE6722),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFFFD5C2),
      onPrimaryContainer: Color(0xFF3A1300),
      secondary: Color(0xFFB94F2C),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFFFDAD1),
      onSecondaryContainer: Color(0xFF3A0B04),
      tertiary: Color(0xFF6A994E),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFD5F2BB),
      onTertiaryContainer: Color(0xFF102006),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      background: Color(0xFFFFF4EB),
      onBackground: Color(0xFF301F17),
      surface: Color(0xFFFFF6ED),
      onSurface: Color(0xFF301F17),
      surfaceVariant: Color(0xFFF0D4C4),
      onSurfaceVariant: Color(0xFF5F4438),
      outline: Color(0xFFAF8B78),
      outlineVariant: Color(0xFFD8BCAB),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF3F2B22),
      onInverseSurface: Color(0xFFFBE8DC),
      inversePrimary: Color(0xFFFFB68E),
      surfaceTint: Color(0xFFEE6722),
    );

    const surfaces = ReceitagoraSurfaceColors(
      lowest: _surfaceContainerLowest,
      low: _surfaceContainerLow,
      surface: _surfaceContainer,
      high: _surfaceContainerHigh,
      highest: _surfaceContainerHighest,
    );

    final base = baseTextTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
      fontFamily: 'Poppins',
    );

    final textTheme = base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -0.5,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.22,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        height: 1.52,
        letterSpacing: 0.1,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        height: 1.5,
        letterSpacing: 0.1,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      canvasColor: colorScheme.background,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      fontFamily: 'Poppins',
      extensions: const <ThemeExtension<dynamic>>[surfaces],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaces.high,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shadowColor: colorScheme.primary.withOpacity(0.2),
          elevation: 1,
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
          side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(color: colorScheme.outline.withOpacity(0.4)),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: surfaces.low,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.45)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaces.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.55),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaces.high,
        disabledColor: surfaces.surface.withOpacity(0.75),
        selectedColor: colorScheme.primaryContainer.withOpacity(0.6),
        secondarySelectedColor: colorScheme.primaryContainer.withOpacity(0.55),
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
        backgroundColor: colorScheme.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.surface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withOpacity(0.7),
        thickness: 1,
        space: 28,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaces.high,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        contentTextStyle: textTheme.bodyMedium,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: surfaces.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaces.high,
        indicatorColor: colorScheme.primaryContainer.withOpacity(0.5),
        labelTextStyle: MaterialStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(MaterialState.selected)
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaces.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaces.high,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.35)),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.onSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.45)),
        ),
        textStyle: textTheme.labelSmall?.copyWith(
          color: colorScheme.surface,
        ),
      ),
    );
  }
}
