import 'package:flutter/material.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/presentation/screens/terminal/shortcut_key.dart';
import 'package:xterm/xterm.dart';

class TerminalShortcutBar extends StatefulWidget {
  final Function(String) onRawInput; // Changed to handle raw input
  final Function(TerminalKey, {bool ctrl, bool alt})? onKeyInput; // Added for key input
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
  State<TerminalShortcutBar> createState() => _TerminalShortcutBarState();
}

class _TerminalShortcutBarState extends State<TerminalShortcutBar> {
  bool _ctrlPressed = false;
  bool _altPressed = false;

  void _handleKeyPress(ShortcutKey key) {
    if (key.isModifier) {
      setState(() {
        if (key.label == 'CTRL') {
          _ctrlPressed = !_ctrlPressed;
          if (_ctrlPressed) _altPressed = false;
        }
        else if (key.label == 'ALT') {
          _altPressed = !_altPressed;
          if (_altPressed) _ctrlPressed = false;
        }
      });
      return;
    }

    // Handle modifier combinations with proper terminal key mapping
    if (_ctrlPressed) {
      _handleCtrlCombination(key);
    } else if (_altPressed) {
      _handleAltCombination(key);
    } else {
      // Regular key press
      widget.onRawInput(key.value);
    }

    // Reset modifiers after use
    if (_ctrlPressed || _altPressed) {
      setState(() {
        _ctrlPressed = false;
        _altPressed = false;
      });
    }
  }

  void _handleCtrlCombination(ShortcutKey key) {
    // Handle special Ctrl combinations
    switch (key.label.toUpperCase()) {
      case 'C':
        widget.onRawInput('\x03'); // Ctrl+C
        break;
      case 'Z':
        widget.onRawInput('\x1a'); // Ctrl+Z
        break;
      case 'D':
        widget.onRawInput('\x04'); // Ctrl+D
        break;
      case 'L':
        widget.onRawInput('\x0c'); // Ctrl+L
        break;
      case 'A':
        widget.onRawInput('\x01'); // Ctrl+A
        break;
      case 'E':
        widget.onRawInput('\x05'); // Ctrl+E
        break;
      case 'K':
        widget.onRawInput('\x0b'); // Ctrl+K
        break;
      case 'U':
        widget.onRawInput('\x15'); // Ctrl+U
        break;
      case 'W':
        widget.onRawInput('\x17'); // Ctrl+W
        break;
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
      default:
      // For single characters, convert to control character
        if (key.label.length == 1) {
          int ctrlCode = key.label.toLowerCase().codeUnitAt(0) - 96;
          if (ctrlCode > 0 && ctrlCode < 27) {
            widget.onRawInput(String.fromCharCode(ctrlCode));
          }
        } else {
          widget.onRawInput(key.value);
        }
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
      default:
        widget.onRawInput('\x1b${key.value}');
    }
  }

  Widget _buildShortcutKey(ShortcutKey key) {
    bool isActive = (key.label == 'CTRL' && _ctrlPressed) || (key.label == 'ALT' && _altPressed);

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

