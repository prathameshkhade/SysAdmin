import 'package:flutter/material.dart';
import 'package:sysadmin/core/utils/color_extension.dart';

class TerminalShortcutBar extends StatefulWidget {
  final Function(String) onKeyPressed;
  final VoidCallback? onToggleVisibility;
  final bool isVisible;

  const TerminalShortcutBar({
    super.key,
    required this.onKeyPressed,
    this.onToggleVisibility,
    this.isVisible = true,
  });

  @override
  State<TerminalShortcutBar> createState() => _TerminalShortcutBarState();
}

class _TerminalShortcutBarState extends State<TerminalShortcutBar> {
  bool _ctrlPressed = false;
  bool _altPressed = false;

  // Define shortcut keys similar to Termux
  final List<ShortcutKey> _topRowKeys = [
    ShortcutKey('ESC', '\x1b'),
    ShortcutKey('/', '/'),
    ShortcutKey('-', '-'),
    ShortcutKey('HOME', '\x1b[H'),
    ShortcutKey('↑', '\x1b[A'),
    ShortcutKey('END', '\x1b[F'),
    ShortcutKey('PGUP', '\x1b[5~'),
  ];

  final List<ShortcutKey> _bottomRowKeys = [
    ShortcutKey('TAB', '\t'),
    ShortcutKey('CTRL', '', isModifier: true),
    ShortcutKey('ALT', '', isModifier: true),
    ShortcutKey('←', '\x1b[D'),
    ShortcutKey('↓', '\x1b[B'),
    ShortcutKey('→', '\x1b[C'),
    ShortcutKey('PGDN', '\x1b[6~'),
  ];

  void _handleKeyPress(ShortcutKey key) {
    if (key.isModifier) {
      setState(() {
        if (key.label == 'CTRL') {
          _ctrlPressed = !_ctrlPressed;
          if (_ctrlPressed) _altPressed = false;
        } else if (key.label == 'ALT') {
          _altPressed = !_altPressed;
          if (_altPressed) _ctrlPressed = false;
        }
      });
      return;
    }

    String output = key.value;

    // Handle modifier combinations
    if (_ctrlPressed) {
      if (key.label.length == 1) {
        // For single characters, convert to control character
        int ctrlCode = key.label.toLowerCase().codeUnitAt(0) - 96;
        if (ctrlCode > 0 && ctrlCode < 27) {
          output = String.fromCharCode(ctrlCode);
        }
      }
      // else {
      //   // For special keys like arrows, add Ctrl modifier
      //   if (key.label == '↑') {
      //     output = '\x1b[1;5A';
      //   }
      //   else if (key.label == '↓') {
      //     output = '\x1b[1;5B';
      //   }
      //   else if (key.label == '→') {
      //     output = '\x1b[1;5C';
      //   }
      //   else if (key.label == '←') {
      //     output = '\x1b[1;5D';
      //   }
      // }
      else {
        output = switch(key.label) {
          '↑' => '\x1b[1;5A',
          '↓' => '\x1b[1;5B',
          '→' => '\x1b[1;5C',
          '←' => '\x1b[1;5D',
          _ => key.value,
        };
      }
    }
    else if (_altPressed) {
      output = '\x1b${key.value}';
    }

    widget.onKeyPressed(output);

    // Reset modifiers after use
    if (_ctrlPressed || _altPressed) {
      setState(() {
        _ctrlPressed = false;
        _altPressed = false;
      });
    }
  }

  Widget _buildShortcutKey(ShortcutKey key) {
    bool isActive = (key.label == 'CTRL' && _ctrlPressed) ||
        (key.label == 'ALT' && _altPressed);

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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row
              Row(
                children: _topRowKeys.map(_buildShortcutKey).toList(),
              ),
              const SizedBox(height: 6),
              // Bottom row
              Row(
                children: _bottomRowKeys.map(_buildShortcutKey).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper class for shortcut keys
class ShortcutKey {
  final String label;
  final String value;
  final bool isModifier;

  ShortcutKey(this.label, this.value, {this.isModifier = false});
}

// Extension widget for common key combinations
class TerminalShortcutBarExtended extends StatefulWidget {
  final Function(String) onKeyPressed;
  final VoidCallback? onToggleVisibility;
  final bool isVisible;

  const TerminalShortcutBarExtended({
    super.key,
    required this.onKeyPressed,
    this.onToggleVisibility,
    this.isVisible = true,
  });

  @override
  State<TerminalShortcutBarExtended> createState() => _TerminalShortcutBarExtendedState();
}

class _TerminalShortcutBarExtendedState extends State<TerminalShortcutBarExtended> {
  bool _ctrlPressed = false;
  bool _altPressed = false;

  // Extended key set with number row and QWERTY layout
  final List<List<ShortcutKey>> _keyRows = [
    // Function keys row
    [
      ShortcutKey('ESC', '\x1b'),
      ShortcutKey('F1', '\x1bOP'),
      ShortcutKey('F2', '\x1bOQ'),
      ShortcutKey('F3', '\x1bOR'),
      ShortcutKey('F4', '\x1bOS'),
      ShortcutKey('F5', '\x1b[15~'),
      ShortcutKey('F6', '\x1b[17~'),
    ],
    // Number row
    [
      ShortcutKey('1', '1'),
      ShortcutKey('2', '2'),
      ShortcutKey('3', '3'),
      ShortcutKey('4', '4'),
      ShortcutKey('5', '5'),
      ShortcutKey('6', '6'),
      ShortcutKey('7', '7'),
      ShortcutKey('8', '8'),
      ShortcutKey('9', '9'),
      ShortcutKey('0', '0'),
    ],
    // QWERTY row
    [
      ShortcutKey('Q', 'q'),
      ShortcutKey('W', 'w'),
      ShortcutKey('E', 'e'),
      ShortcutKey('R', 'r'),
      ShortcutKey('T', 't'),
      ShortcutKey('Y', 'y'),
      ShortcutKey('U', 'u'),
      ShortcutKey('I', 'i'),
      ShortcutKey('O', 'o'),
      ShortcutKey('P', 'p'),
    ],
    // ASDF row
    [
      ShortcutKey('A', 'a'),
      ShortcutKey('S', 's'),
      ShortcutKey('D', 'd'),
      ShortcutKey('F', 'f'),
      ShortcutKey('G', 'g'),
      ShortcutKey('H', 'h'),
      ShortcutKey('J', 'j'),
      ShortcutKey('K', 'k'),
      ShortcutKey('L', 'l'),
    ],
    // Control row
    [
      ShortcutKey('CTRL', '', isModifier: true),
      ShortcutKey('ALT', '', isModifier: true),
      ShortcutKey('←', '\x1b[D'),
      ShortcutKey('↓', '\x1b[B'),
      ShortcutKey('↑', '\x1b[A'),
      ShortcutKey('→', '\x1b[C'),
      ShortcutKey('DEL', '\x7f'),
    ],
  ];

  void _handleKeyPress(ShortcutKey key) {
    if (key.isModifier) {
      setState(() {
        if (key.label == 'CTRL') {
          _ctrlPressed = !_ctrlPressed;
          if (_ctrlPressed) _altPressed = false;
        } else if (key.label == 'ALT') {
          _altPressed = !_altPressed;
          if (_altPressed) _ctrlPressed = false;
        }
      });
      return;
    }

    String output = key.value;

    if (_ctrlPressed && key.label.length == 1) {
      int ctrlCode = key.label.toLowerCase().codeUnitAt(0) - 96;
      if (ctrlCode > 0 && ctrlCode < 27) {
        output = String.fromCharCode(ctrlCode);
      }
    } else if (_altPressed) {
      output = '\x1b${key.value}';
    }

    widget.onKeyPressed(output);

    if (_ctrlPressed || _altPressed) {
      setState(() {
        _ctrlPressed = false;
        _altPressed = false;
      });
    }
  }

  Widget _buildKey(ShortcutKey key) {
    bool isActive = (key.label == 'CTRL' && _ctrlPressed) ||
        (key.label == 'ALT' && _altPressed);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(1),
        height: 35,
        child: Material(
          color: isActive
              ? Colors.red.useOpacity(0.8)
              : Colors.grey[800]?.useOpacity(0.9),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => _handleKeyPress(key),
            child: Center(
              child: Text(
                key.label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[300],
                  fontSize: key.label.length > 2 ? 9 : 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
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
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _keyRows.map((row) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    children: row.map(_buildKey).toList(),
                  ),
                ),
            ).toList(),
          ),
        ),
      ),
    );
  }
}