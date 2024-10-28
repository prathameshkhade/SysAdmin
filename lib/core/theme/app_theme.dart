import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF387EF5),
    secondaryHeaderColor: Colors.blueGrey.withOpacity(0.1),
    scaffoldBackgroundColor: Colors.white,

    colorScheme: ColorScheme.light(
      primary: const Color(0xFF387EF5),
      // secondary: const Color(0xFF387EF5),
      secondary: CupertinoColors.systemTeal,
      secondaryContainer: Colors.blueGrey.withOpacity(0.1),
      surface: Colors.white,
      error: Colors.red.shade700,
    ),

    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    textTheme: const TextTheme(
        titleLarge: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600
        ),
        titleMedium: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600
        ),
        titleSmall: TextStyle(
          color: Colors.black54,
          fontSize: 12,
        ),
        bodyMedium: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w400
        )
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF387EF5),
    scaffoldBackgroundColor: const Color(0xFF121212),
    secondaryHeaderColor: Colors.blueGrey.withOpacity(0.1),

    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF387EF5),
      secondary: const Color(0xFF387EF5),
      surface: const Color(0xFF1E1E1E),
      error: Colors.red.shade700,
    ),

    cardTheme: CardTheme(
      color: const Color(0xFF1E1E1E),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Special card theme for light cards in dark mode
    extensions: [
      CustomThemeExtension(
        lightCardColor: const Color(0xFF2A2A2A),
        lightCardTextColor: Colors.white70,
      ),
    ],

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600
      ),
      titleMedium: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600
      ),
      titleSmall: TextStyle(
        color: Colors.white54,
        fontSize: 12,
      ),
      bodyMedium: TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w400
      )
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// Custom extension for special theme cases
class CustomThemeExtension extends ThemeExtension<CustomThemeExtension> {
  final Color lightCardColor;
  final Color lightCardTextColor;

  CustomThemeExtension({
    required this.lightCardColor,
    required this.lightCardTextColor,
  });

  @override
  ThemeExtension<CustomThemeExtension> copyWith({
    Color? lightCardColor,
    Color? lightCardTextColor,
  }) {
    return CustomThemeExtension(
      lightCardColor: lightCardColor ?? this.lightCardColor,
      lightCardTextColor: lightCardTextColor ?? this.lightCardTextColor,
    );
  }

  @override
  ThemeExtension<CustomThemeExtension> lerp(
      ThemeExtension<CustomThemeExtension>? other,
      double t,
      ) {
    if (other is! CustomThemeExtension) {
      return this;
    }
    return CustomThemeExtension(
      lightCardColor: Color.lerp(lightCardColor, other.lightCardColor, t)!,
      lightCardTextColor: Color.lerp(lightCardTextColor, other.lightCardTextColor, t)!,
    );
  }
}