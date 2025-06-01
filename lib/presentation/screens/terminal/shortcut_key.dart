// Helper class for shortcut keys
class ShortcutKey {
  final String label;
  final String value;
  final bool isModifier;

  ShortcutKey(this.label, this.value, {this.isModifier = false});
}
