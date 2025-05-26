import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:xterm/xterm.dart';

/// Custom shortcuts for terminal that integrate with the shortcut bar
Map<ShortcutActivator, Intent> getTerminalShortcuts() {
  return {
    // Ctrl+C - Send interrupt signal
    const SingleActivator(LogicalKeyboardKey.keyC, control: true):
    const _SendRawSequenceIntent('\x03'),  // Ctrl+C

    // Ctrl+Z - Send suspend signal
    const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
    const _SendRawSequenceIntent('\x1a'),  // Ctrl+Z

    // Ctrl+D - Send EOF
    const SingleActivator(LogicalKeyboardKey.keyD, control: true):
    const _SendRawSequenceIntent('\x04'),  // Ctrl+D

    // Ctrl+L - Clear screen
    const SingleActivator(LogicalKeyboardKey.keyL, control: true):
    const _SendRawSequenceIntent('\x0c'),  // Ctrl+L

    // Ctrl+A - Move to beginning of line
    const SingleActivator(LogicalKeyboardKey.keyA, control: true):
    const _SendRawSequenceIntent('\x01'),  // Ctrl+A

    // Ctrl+E - Move to end of line
    const SingleActivator(LogicalKeyboardKey.keyE, control: true):
    const _SendRawSequenceIntent('\x05'),  // Ctrl+E

    // Ctrl+K - Kill from cursor to end of line
    const SingleActivator(LogicalKeyboardKey.keyK, control: true):
    const _SendRawSequenceIntent('\x0b'),  // Ctrl+K

    // Ctrl+U - Kill from cursor to beginning of line
    const SingleActivator(LogicalKeyboardKey.keyU, control: true):
    const _SendRawSequenceIntent('\x15'),  // Ctrl+U

    // Ctrl+W - Kill word backwards
    const SingleActivator(LogicalKeyboardKey.keyW, control: true):
    const _SendRawSequenceIntent('\x17'),  // Ctrl+W

    // Ctrl+Arrow keys for word navigation
    const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
    const _SendRawSequenceIntent('\x1b[1;5D'),

    const SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
    const _SendRawSequenceIntent('\x1b[1;5C'),

    const SingleActivator(LogicalKeyboardKey.arrowUp, control: true):
    const _SendRawSequenceIntent('\x1b[1;5A'),

    const SingleActivator(LogicalKeyboardKey.arrowDown, control: true):
    const _SendRawSequenceIntent('\x1b[1;5B'),

    // Alt+Arrow keys
    const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
    const _SendRawSequenceIntent('\x1bb'),

    const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true):
    const _SendRawSequenceIntent('\x1bf'),
  };
}

class _SendTerminalKeyIntent extends Intent {
  const _SendTerminalKeyIntent(this.key);
  final TerminalKey key;
}

class _SendRawSequenceIntent extends Intent {
  const _SendRawSequenceIntent(this.sequence);
  final String sequence;
}

class TerminalShortcutActions extends StatelessWidget {
  final Widget child;
  final Terminal terminal;

  const TerminalShortcutActions({
    super.key,
    required this.child,
    required this.terminal,
  });

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        _SendTerminalKeyIntent: _SendTerminalKeyAction(terminal),
        _SendRawSequenceIntent: _SendRawSequenceAction(terminal),
      },
      child: child,
    );
  }
}

class _SendTerminalKeyAction extends Action<_SendTerminalKeyIntent> {
  _SendTerminalKeyAction(this.terminal);
  final Terminal terminal;

  @override
  Object? invoke(_SendTerminalKeyIntent intent) {
    terminal.keyInput(intent.key);
    return null;
  }
}

class _SendRawSequenceAction extends Action<_SendRawSequenceIntent> {
  _SendRawSequenceAction(this.terminal);
  final Terminal terminal;

  @override
  Object? invoke(_SendRawSequenceIntent intent) {
    terminal.textInput(intent.sequence);
    return null;
  }
}
