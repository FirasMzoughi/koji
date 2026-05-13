import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koji/core/responsive_helper.dart';

class AppTheme {
  static const Color primaryBlueLight = Color(0xFF1D74FF);
  static const Color primaryBlueDark = Color(0xFF4A90D9);
  static const Color primaryBlue = primaryBlueLight;

  static const Color darkNavy = Color(0xFF111827);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color background = backgroundLight;
  static const Color cream = Color(0xFFF3F4F6);
  static const Color backgroundDark = Color(0xFF0F1117);
  static const Color surfaceDark = Color(0xFF1A1D26);
  static const Color cardDark = Color(0xFF222633);
  static const Color dividerDark = Color(0xFF2D3142);
  static const Color textOnDark = Color(0xFFE5E7EB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  static TextStyle defaultTextStyle({FontWeight? fontWeight}) {
    return GoogleFonts.inter(
      fontWeight: fontWeight ?? FontWeight.normal,
    );
  }

  static TextStyle headingStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.inter(
      fontSize: context.responsive.fontSize(28),
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : darkNavy,
      height: 1.2,
    );
  }

  static TextStyle bodyStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.inter(
      fontSize: context.responsive.fontSize(16),
      color: isDark ? Colors.grey[400] : textLight,
      height: 1.5,
    );
  }

  static TextStyle buttonTextStyle(BuildContext context) => GoogleFonts.inter(
        fontSize: context.responsive.fontSize(16),
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color backgroundColor(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textLight;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? dividerDark : const Color(0xFFE5E7EB);

  static Color mutedSurface(BuildContext context) =>
      isDark(context) ? cardDark : const Color(0xFFF1F5F9);

  static Color headerBackground(BuildContext context) =>
      isDark(context) ? const Color(0xFF111827) : const Color(0xFF0F172A);

  static ThemeData lightThemeData(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primaryBlueLight,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlueLight,
        primary: primaryBlueLight,
        surface: backgroundLight,
        onSurface: textDark,
        secondary: cream,
        onSecondary: textDark,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: darkNavy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkNavy,
        ),
        iconTheme: const IconThemeData(color: darkNavy),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: darkNavy,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlueLight,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.width(6.4),
            vertical: responsive.height(2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          ),
          textStyle: buttonTextStyle(context),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlueLight,
          side: const BorderSide(color: primaryBlueLight),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.width(6.4),
            vertical: responsive.height(2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: context.responsive.fontSize(16),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlueLight,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(10)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(10)),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(10)),
          borderSide: const BorderSide(color: primaryBlueLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFFF8FAFC),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryBlueLight
              : const Color(0xFFCBD5E1),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: textLight,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: darkNavy,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: backgroundLight,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(16)),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkNavy,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkNavy,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(10)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      iconTheme: const IconThemeData(color: darkNavy),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlueLight,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(16)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: darkNavy,
        unselectedItemColor: textLight,
      ),
    );
  }

  static ThemeData darkThemeData(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
      bodyColor: textOnDark,
      displayColor: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryBlueDark,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlueDark,
        primary: primaryBlueDark,
        surface: surfaceDark,
        onSurface: textOnDark,
        secondary: cardDark,
        onSecondary: textOnDark,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: textOnDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textOnDark,
        ),
        iconTheme: const IconThemeData(color: textOnDark),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          side: const BorderSide(color: dividerDark, width: 1),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textOnDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlueDark,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.width(6.4),
            vertical: responsive.height(2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          ),
          textStyle: buttonTextStyle(context),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlueDark,
          side: const BorderSide(color: primaryBlueDark),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.width(6.4),
            vertical: responsive.height(2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: context.responsive.fontSize(16),
            fontWeight: FontWeight.w600,
            color: primaryBlueDark,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlueDark,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(10)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(10)),
          borderSide: const BorderSide(color: dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(10)),
          borderSide: const BorderSide(color: primaryBlueDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerDark,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFFE5E7EB),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryBlueDark
              : dividerDark,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: textSecondaryDark,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: primaryBlueDark,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: backgroundDark,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(16)),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textOnDark,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardDark,
        contentTextStyle: GoogleFonts.inter(
          color: textOnDark,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(10)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      iconTheme: const IconThemeData(color: textOnDark),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlueDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(16)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: textOnDark,
        unselectedItemColor: textSecondaryDark,
      ),
    );
  }

  static ThemeData themeData(BuildContext context) => lightThemeData(context);
}
