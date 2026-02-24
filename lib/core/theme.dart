import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koji/core/responsive_helper.dart';

class AppTheme {
  // Colors
  static const Color primaryBlueLight = Color(0xFF1D74FF); // User specified for White Mood
  static const Color primaryBlueDark = Color(0xFF0F296F);  // User specified for Black Mood
  
  // Aliases for backward compatibility
  static const Color primaryBlue = primaryBlueLight;
  
  static const Color darkNavy = Color(0xFF111827); 
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color background = backgroundLight; // Alias
  static const Color cream = Color(0xFFF3F4F6); // Re-added
  static const Color backgroundDark = Color(0xFF121212); // Standard dark bg
  static const Color surfaceDark = Color(0xFF1E1E1E); // Slightly lighter for cards in dark mode

  // Google Fonts - Outfit
  static TextStyle outfitTextStyle({FontWeight? fontWeight}) {
    return GoogleFonts.outfit(
      fontWeight: fontWeight ?? FontWeight.normal,
    );
  }

  // Text Styles - Responsive
  static TextStyle headingStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.outfit(
      fontSize: context.responsive.fontSize(28),
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : darkNavy,
      height: 1.2,
    );
  }

  static TextStyle bodyStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.outfit(
      fontSize: context.responsive.fontSize(16),
      color: isDark ? Colors.grey[400] : textLight,
      height: 1.5,
    );
  }

  static TextStyle buttonTextStyle(BuildContext context) => GoogleFonts.outfit(
    fontSize: context.responsive.fontSize(16),
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Light Theme
  static ThemeData lightThemeData(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = GoogleFonts.outfitTextTheme(Theme.of(context).textTheme);
    
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
        brightness: Brightness.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlueLight, // Use the requested blue
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.width(6.4),
            vertical: responsive.height(2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          ),
          textStyle: buttonTextStyle(context),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData darkThemeData(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
      bodyColor: Colors.white,
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
        brightness: Brightness.dark,
        onSurface: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlueDark, // Use the requested dark blue
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.width(6.4),
            vertical: responsive.height(2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          ),
          textStyle: buttonTextStyle(context),
        ),
      ),
    );
  }
  
  // Backward compatibility alias if needed, or remove if updated everywhere
  static ThemeData themeData(BuildContext context) => lightThemeData(context);
}
