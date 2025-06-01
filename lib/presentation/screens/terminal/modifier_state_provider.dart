import 'package:flutter_riverpod/flutter_riverpod.dart';

final modifierStateProvider = StateNotifierProvider<ModifierStateNotifier, ModifierState>((ref) {
  return ModifierStateNotifier();
});

class ModifierState {
  final bool ctrlPressed;
  final bool altPressed;

  const ModifierState({
    this.ctrlPressed = false,
    this.altPressed = false,
  });

  ModifierState copyWith({
    bool? ctrlPressed,
    bool? altPressed,
  }) {
    return ModifierState(
      ctrlPressed: ctrlPressed ?? this.ctrlPressed,
      altPressed: altPressed ?? this.altPressed,
    );
  }
}

class ModifierStateNotifier extends StateNotifier<ModifierState> {
  ModifierStateNotifier() : super(const ModifierState());

  void setCtrl(bool pressed) {
    state = state.copyWith(
      ctrlPressed: pressed,
      altPressed: pressed ? false : state.altPressed, // Reset alt when ctrl is pressed
    );
  }

  void setAlt(bool pressed) {
    state = state.copyWith(
      altPressed: pressed,
      ctrlPressed: pressed ? false : state.ctrlPressed, // Reset ctrl when alt is pressed
    );
  }

  void reset() {
    state = const ModifierState();
  }
}