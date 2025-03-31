import 'package:flutter/material.dart';

class Util {

  /// Displays a snack bar message on the current screen.
  ///
  /// This method is used to show a short message to the user, typically for
  /// notification or feedback purposes. The appearance of the snack bar,
  /// including background and text colors, can be customized.
  ///
  /// Parameters:
  /// - `context`: (required) The `BuildContext` of the current screen where
  ///   the snack bar will be displayed.
  /// - `msg`: (required) The message to display inside the snack bar.
  /// - `bgColour`: (optional) The background color of the snack bar. If not
  ///   provided, it defaults to a theme-specific color.
  /// - `txtColour`: (optional) The color of the text message inside the snack bar.
  /// - `isError`: (optional, default: `false`) Determines whether the message
  ///   should use the error color defined in the app's theme. If true, the snack
  ///   bar will display an error-styled background.
  ///
  /// Usage:
  /// ```dart
  /// Util.showMsg(
  ///   context: context,
  ///   msg: "This is a notification!",
  ///   bgColour: Colors.blue,
  ///   txtColour: Colors.white,
  ///   isError: false,
  /// );
  /// ```
  ///
  /// Notes:
  /// - The snack bar automatically disappears after 3 seconds.
  /// - If `isError` is true, the `bgColour` parameter will be ignored in favor of
  ///   the theme's error color.

  static void showMsg({
    required BuildContext context,
    required String msg,
    Color? bgColour,
    Color? txtColour,
    bool isError = false,
  }) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 1.0,
        backgroundColor: isError ? theme.colorScheme.error : bgColour,
        duration: const Duration(seconds: 3),

        content: Text(
          msg,
          style: TextStyle(
              fontSize: 14,
              color: txtColour
          ),
        ),
      ),
    );
  }

  /// Formats the given time in minutes into a human-readable string.
  ///
  /// This method converts uptime provided in minutes into a readable format
  /// based on the total duration. It dynamically determines whether to use
  /// minutes, hours, or days in the output string.
  ///
  /// Parameters:
  /// - `totalMinutes`: (required) The total time in minutes that needs formatting.
  ///
  /// Returns:
  /// A formatted string representation of the uptime:
  /// - For durations under 60 minutes: Displays the time in minutes (e.g., "45 minutes").
  /// - For durations under 24 hours: Displays the time in hours and minutes
  ///   (e.g., "3 hours, 24 minutes").
  /// - For durations of 24 hours or more: Displays the time in days, hours, and minutes
  ///   (e.g., "2 days, 1 hour, 33 minutes").
  ///
  /// Usage:
  /// ```dart
  /// String formattedTime = Util.formatTime(2973);
  /// print(formattedTime);
  /// // Output: "2 days, 1 hour, 33 minutes"
  /// ```
  ///
  /// Notes:
  /// - Singular and plural units are handled properly for readability (e.g., "1 minute" vs "2 minutes").
  /// - This method is ideal for representing uptime or elapsed durations in a user-friendly format.

  static String formatTime(int totalMinutes) {
    // Less than 1 hour
    if (totalMinutes < 60) {
      return '$totalMinutes minute${totalMinutes == 1 ? '' : 's'}';
    }
    // Less than 24 hours
    else if (totalMinutes < 1440) {
      int hours = totalMinutes ~/ 60;
      int minutes = totalMinutes % 60;
      return '$hours hour${hours == 1 ? '' : 's'}, $minutes minute${minutes == 1 ? '' : 's'}';
    }
    // 24 hours or more
    else {
      int days = totalMinutes ~/ 1440;
      int remainingMinutes = totalMinutes % 1440;
      int hours = remainingMinutes ~/ 60;
      int minutes = remainingMinutes % 60;
      return '$days day${days == 1 ? '' : 's'}, $hours hour${hours == 1 ? '' : 's'}, $minutes minute${minutes == 1 ? '' : 's'}';
    }
  }
}