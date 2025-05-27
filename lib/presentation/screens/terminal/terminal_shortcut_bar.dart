import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/presentation/screens/terminal/shortcut_key.dart';
import 'package:xterm/xterm.dart';

import 'modifier_state_provider.dart';

class TerminalShortcutBar extends ConsumerStatefulWidget {
  final Function(String) onRawInput;
  final Function(TerminalKey, {bool ctrl, bool alt})? onKeyInput;
  final VoidCallback? onToggleVisibility;
  final bool isVisible;
  final List<List<ShortcutKey>> shortcutKeys;

  const TerminalShortcutBar({
    super.key,
    required this.shortcutKeys,
    required this.onRawInput,
    this.onKeyInput,
    this.onToggleVisibility,
    this.isVisible = true,
  });

  @override
  ConsumerState<TerminalShortcutBar> createState() => _TerminalShortcutBarState();
}

class _TerminalShortcutBarState extends ConsumerState<TerminalShortcutBar> {

  void _handleKeyPress(ShortcutKey key) {
    final modifierState = ref.read(modifierStateProvider);

    if (key.isModifier) {
      if (key.label == 'CTRL') {
        ref.read(modifierStateProvider.notifier).setCtrl(!modifierState.ctrlPressed);
      } else if (key.label == 'ALT') {
        ref.read(modifierStateProvider.notifier).setAlt(!modifierState.altPressed);
      }
      return;
    }

    // Handle modifier combinations with proper terminal key mapping
    if (modifierState.ctrlPressed) {
      _handleCtrlCombination(key);
    }
    else if (modifierState.altPressed) {
      _handleAltCombination(key);
    }
    else {
      // Regular key press
      widget.onRawInput(key.value);
    }
  }

  void _handleCtrlCombination(ShortcutKey key) {
    // For arrow keys and special keys
    switch (key.label) {
      case '↑':
        widget.onRawInput('\x1b[1;5A');
        break;
      case '↓':
        widget.onRawInput('\x1b[1;5B');
        break;
      case '→':
        widget.onRawInput('\x1b[1;5C');
        break;
      case '←':
        widget.onRawInput('\x1b[1;5D');
        break;
      case 'ESC':
        widget.onRawInput('\x1b');
        break;
      case 'TAB':
        widget.onRawInput('\t');
        break;
      default:
        // For any other key, let's try to convert it to control sequence
        // This handles navigation keys that don't have specific control sequences
        widget.onRawInput(key.value);
    }
  }

  void _handleAltCombination(ShortcutKey key) {
    // Handle Alt combinations
    switch (key.label) {
      case '←':
        widget.onRawInput('\x1bb'); // Alt+Left (move word back)
        break;
      case '→':
        widget.onRawInput('\x1bf'); // Alt+Right (move word forward)
        break;
      case '↑':
        widget.onRawInput('\x1b[1;3A');
        break;
      case '↓':
        widget.onRawInput('\x1b[1;3B');
        break;
      default:
        // For all other keys, send ESC + key
        widget.onRawInput('\x1b${key.value}');
    }
  }

  Widget _buildShortcutKey(ShortcutKey key) {
    final modifierState = ref.watch(modifierStateProvider);
    bool isActive = (key.label == 'CTRL' && modifierState.ctrlPressed) || (key.label == 'ALT' && modifierState.altPressed);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Material(
          color: isActive
              ? Colors.red.useOpacity(0.8)
              : Colors.grey[800]?.useOpacity(0.9),
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _handleKeyPress(key),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(
                key.label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[300],
                  fontSize: key.label.length > 3 ? 10 : 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.useOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: Colors.grey[700]!,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
              spacing: 6,
              mainAxisSize: MainAxisSize.min,
              children: widget.shortcutKeys.map((row) => Row(
                children: row.map((key) => _buildShortcutKey(key)).toList(),
              )).toList()
          ),
        ),
      ),
    );
  }
}
