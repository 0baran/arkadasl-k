import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFF006E);
  static const Color secondaryColor = Color(0xFF8338EC);
  static const Color accentColor = Color(0xFFFFBE0B);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF00E676);
  static const Color warningColor = Color(0xFFFFC400);

  static const Color textPrimary = Color(0xFF1E1E24);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textHint = Color(0xFFADB5BD);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData _baseTheme(bool isDark) {
    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: primaryColor,
            secondary: secondaryColor,
            tertiary: accentColor,
            surface: Color(0xFF1E1E24),
            error: errorColor,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.white,
            onError: Colors.white,
          )
        : const ColorScheme.light(
            primary: primaryColor,
            secondary: secondaryColor,
            tertiary: accentColor,
            surface: surfaceColor,
            error: errorColor,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: textPrimary,
            onError: Colors.white,
          );

    final navBg = isDark ? const Color(0xFF2A2A35) : Colors.white;
    final navInactive = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    final scaffoldBg = isDark ? const Color(0xFF121214) : backgroundColor;
    final inputFill = isDark ? const Color(0xFF2A2A35) : Colors.grey.shade50;
    final cardColor = isDark ? const Color(0xFF1E1E24) : surfaceColor;
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      textTheme: GoogleFonts.outfitTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardColor,
      dividerColor: dividerColor,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: colorScheme.onSurface,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navBg.withValues(alpha: 0.9),
        selectedItemColor: primaryColor,
        unselectedItemColor: navInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBg.withValues(alpha: 0.9),
        indicatorColor: primaryColor.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected) ? primaryColor : navInactive;
          return IconThemeData(color: color, size: 26);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: primaryColor);
          }
          return TextStyle(fontSize: 12, color: navInactive);
        }),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(color: textHint),
      ),

      iconTheme: IconThemeData(
        color: colorScheme.primary,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade100,
        selectedColor: primaryColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w500),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
    );
  }

  static ThemeData get lightTheme => _baseTheme(false);
  static ThemeData get darkTheme => _baseTheme(true);
}
