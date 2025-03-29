import 'dart:ui';

extension ColorOpacity on Color {
  Color useOpacity(double opacity) {
    return withAlpha((opacity * 255).round());
  }
}