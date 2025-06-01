import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:xterm/xterm.dart';


/// Custom shortcuts for terminal that integrate with the shortcut bar
/// and handle physical keyboard inputs
Map<ShortcutActivator, Intent> getTerminalShortcuts() {
  final Map<ShortcutActivator, Intent> shortcuts = {
    // CTRL combinations
    // Standard terminal control characters
    const SingleActivator(LogicalKeyboardKey.keyC, control: true):
    const _SendRawSequenceIntent('\x03'),  // Ctrl+C (SIGINT)
    
    const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
    const _SendRawSequenceIntent('\x1a'),  // Ctrl+Z (SIGTSTP)
    
    const SingleActivator(LogicalKeyboardKey.keyD, control: true):
    const _SendRawSequenceIntent('\x04'),  // Ctrl+D (EOF)
    
    const SingleActivator(LogicalKeyboardKey.keyL, control: true):
    const _SendRawSequenceIntent('\x0c'),  // Ctrl+L (clear screen)
    
    const SingleActivator(LogicalKeyboardKey.keyA, control: true):
    const _SendRawSequenceIntent('\x01'),  // Ctrl+A (start of line)
    
    const SingleActivator(LogicalKeyboardKey.keyE, control: true):
    const _SendRawSequenceIntent('\x05'),  // Ctrl+E (end of line)
    
    const SingleActivator(LogicalKeyboardKey.keyK, control: true):
    const _SendRawSequenceIntent('\x0b'),  // Ctrl+K (kill to end of line)
    
    const SingleActivator(LogicalKeyboardKey.keyU, control: true):
    const _SendRawSequenceIntent('\x15'),  // Ctrl+U (kill to start of line)
    
    const SingleActivator(LogicalKeyboardKey.keyW, control: true):
    const _SendRawSequenceIntent('\x17'),  // Ctrl+W (kill word backward)

    const SingleActivator(LogicalKeyboardKey.keyP, control: true):
    const _SendRawSequenceIntent('\x10'),  // Ctrl+P (previous command)
    
    const SingleActivator(LogicalKeyboardKey.keyN, control: true):
    const _SendRawSequenceIntent('\x0e'),  // Ctrl+N (next command)
    
    const SingleActivator(LogicalKeyboardKey.keyR, control: true):
    const _SendRawSequenceIntent('\x12'),  // Ctrl+R (reverse search)
    
    const SingleActivator(LogicalKeyboardKey.keyT, control: true):
    const _SendRawSequenceIntent('\x14'),  // Ctrl+T (transpose chars)
    
    const SingleActivator(LogicalKeyboardKey.keyO, control: true):
    const _SendRawSequenceIntent('\x0f'),  // Ctrl+O
    
    const SingleActivator(LogicalKeyboardKey.keyH, control: true):
    const _SendRawSequenceIntent('\x08'),  // Ctrl+H (backspace)
    
    const SingleActivator(LogicalKeyboardKey.keyJ, control: true):
    const _SendRawSequenceIntent('\x0a'),  // Ctrl+J (newline)
    
    const SingleActivator(LogicalKeyboardKey.keyM, control: true):
    const _SendRawSequenceIntent('\x0d'),  // Ctrl+M (return)
    
    const SingleActivator(LogicalKeyboardKey.keyB, control: true):
    const _SendRawSequenceIntent('\x02'),  // Ctrl+B (back char)
    
    const SingleActivator(LogicalKeyboardKey.keyF, control: true):
    const _SendRawSequenceIntent('\x06'),  // Ctrl+F (forward char)
    
    const SingleActivator(LogicalKeyboardKey.keyG, control: true):
    const _SendRawSequenceIntent('\x07'),  // Ctrl+G (bell/abort)
    
    const SingleActivator(LogicalKeyboardKey.keyV, control: true):
    const _SendRawSequenceIntent('\x16'),  // Ctrl+V (literal insert)
    
    const SingleActivator(LogicalKeyboardKey.keyX, control: true):
    const _SendRawSequenceIntent('\x18'),  // Ctrl+X
    
    const SingleActivator(LogicalKeyboardKey.keyY, control: true):
    const _SendRawSequenceIntent('\x19'),  // Ctrl+Y (yank)
    
    const SingleActivator(LogicalKeyboardKey.keyS, control: true):
    const _SendRawSequenceIntent('\x13'),  // Ctrl+S (stop output)
    
    const SingleActivator(LogicalKeyboardKey.keyQ, control: true):
    const _SendRawSequenceIntent('\x11'),  // Ctrl+Q (resume output)
    
    const SingleActivator(LogicalKeyboardKey.keyI, control: true):
    const _SendRawSequenceIntent('\x09'),  // Ctrl+I (tab)
    
    // Ctrl+Arrow keys for word navigation
    const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
    const _SendRawSequenceIntent('\x1b[1;5D'),
    
    const SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
    const _SendRawSequenceIntent('\x1b[1;5C'),
    
    const SingleActivator(LogicalKeyboardKey.arrowUp, control: true):
    const _SendRawSequenceIntent('\x1b[1;5A'),
    
    const SingleActivator(LogicalKeyboardKey.arrowDown, control: true):
    const _SendRawSequenceIntent('\x1b[1;5B'),
    
    // Alt combinations
    // Alt+Arrow keys
    const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
    const _SendRawSequenceIntent('\x1bb'),  // Alt+Left (move word back)
    
    const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true):
    const _SendRawSequenceIntent('\x1bf'),  // Alt+Right (move word forward)
    
    const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true):
    const _SendRawSequenceIntent('\x1b[1;3A'),
    
    const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
    const _SendRawSequenceIntent('\x1b[1;3B'),
  };
  
  // Add Alt+letter shortcuts
  for (int charCode = 97; charCode <= 122; charCode++) { // a-z
    final letter = String.fromCharCode(charCode);
    final key = LogicalKeyboardKey(charCode - 32); // Convert to uppercase key code
    shortcuts[SingleActivator(key, alt: true)] = 
        _SendRawSequenceIntent('\x1b$letter'); // Alt+letter sends ESC+letter
  }
  
  return shortcuts;
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