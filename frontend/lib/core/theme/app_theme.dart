import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta industrial/refinada: azul-ardósia escuro + laranja âmbar
  static const Color primary = Color(0xFF1A2B4A);
  static const Color primaryLight = Color(0xFF243B5E);
  static const Color accent = Color(0xFFE8A020);
  static const Color accentLight = Color(0xFFFFB84D);
  static const Color background = Color(0xFFF4F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEF1F8);
  static const Color error = Color(0xFFD93025);
  static const Color success = Color(0xFF1E7E34);
  static const Color warning = Color(0xFFF59E0B);
  static const Color textPrimary = Color(0xFF0F1D33);
  static const Color textSecondary = Color(0xFF5A6A82);
  static const Color textHint = Color(0xFF9AAABB);
  static const Color divider = Color(0xFFDDE3EE);
  static const Color statusOk = Color(0xFF16A34A);
  static const Color statusBaixo = Color(0xFFD97706);
  static const Color statusCritico = Color(0xFFDC2626);
  static const Color sidebar = Color(0xFF0F1D33);
  static const Color sidebarActive = Color(0xFF1A2B4A);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryLight,
        onPrimaryContainer: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        secondaryContainer: accentLight,
        onSecondaryContainer: textPrimary,
        error: error,
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: error,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceVariant,
        onSurfaceVariant: textSecondary,
        outline: divider,
        outlineVariant: Color(0xFFEEF1F8),
        shadow: Color(0x1A1A2B4A),
        scrim: Color(0x80000000),
        inverseSurface: primary,
        onInverseSurface: Colors.white,
        inversePrimary: accent,
        surfaceTint: primary,
      ),
      textTheme: GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge: GoogleFonts.raleway(
          fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.raleway(
          fontSize: 26, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.raleway(
          fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        headlineMedium: GoogleFonts.raleway(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        headlineSmall: GoogleFonts.raleway(
          fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        titleMedium: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        bodyLarge: GoogleFonts.nunito(fontSize: 15, color: textPrimary),
        bodyMedium: GoogleFonts.nunito(fontSize: 14, color: textSecondary),
        bodySmall: GoogleFonts.nunito(fontSize: 12, color: textHint),
        labelLarge: GoogleFonts.nunito(
          fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5,
        ),
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0x1A1A2B4A),
        titleTextStyle: GoogleFonts.raleway(
          fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.nunito(color: textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.nunito(color: textHint, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(color: divider, space: 1, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        labelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primary,
        contentTextStyle: GoogleFonts.nunito(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.raleway(
          fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary,
        ),
      ),
    );
  }
}