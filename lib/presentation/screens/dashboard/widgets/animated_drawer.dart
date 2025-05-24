import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A provider to maintain the drawer state across the app
final drawerStateProvider = StateNotifierProvider<DrawerStateNotifier, bool>((ref) {
  return DrawerStateNotifier();
});

/// Notifier to handle drawer open/close state
class DrawerStateNotifier extends StateNotifier<bool> {
  DrawerStateNotifier() : super(false);

  void open() => state = true;
  void close() => state = false;
  void toggle() => state = !state;
}

class AnimatedDrawer extends ConsumerStatefulWidget {
  final Widget drawer;
  final Widget child;
  final double drawerWidth;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool enableGestures;

  const AnimatedDrawer({
    super.key,
    required this.drawer,
    required this.child,
    this.drawerWidth = 0.8, // 80% of screen width
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.easeInOut,
    this.enableGestures = true,
  });

  @override
  ConsumerState<AnimatedDrawer> createState() => _AnimatedDrawerState();
}

class _AnimatedDrawerState extends ConsumerState<AnimatedDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  // For gesture detection
  double _dragStartX = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    if (!widget.enableGestures) return;

    setState(() {
      _isDragging = true;
      _dragStartX = details.globalPosition.dx;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.enableGestures || !_isDragging) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDrawerOpen = ref.read(drawerStateProvider);
    final delta = details.globalPosition.dx - _dragStartX;
    final drawerWidth = screenWidth * widget.drawerWidth;

    if (isDrawerOpen) {
      // If drawer is open, only allow dragging to close (leftwards)
      if (delta < 0) {
        final dragPercentage = delta.abs() / drawerWidth;
        _animationController.value = 1.0 - dragPercentage.clamp(0.0, 1.0);
      }
    }
    else {
      // If drawer is closed, only allow dragging to open (rightwards)
      if (delta > 0) {
        final dragPercentage = delta / drawerWidth;
        _animationController.value = dragPercentage.clamp(0.0, 1.0);
      }
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!widget.enableGestures || !_isDragging) return;

    setState(() => _isDragging = false);

    // Check velocity to determine whether to complete or reverse the animation
    final velocity = details.velocity.pixelsPerSecond.dx;
    final isDrawerOpen = ref.read(drawerStateProvider);

    if (isDrawerOpen) {
      // If drawer is open and swiping left (negative velocity)
      if (velocity < -300 || _animationController.value < 0.5) {
        ref.read(drawerStateProvider.notifier).close();
      } else {
        ref.read(drawerStateProvider.notifier).open();
      }
    }
    else {
      // If drawer is closed and swiping right (positive velocity)
      if (velocity > 300 || _animationController.value > 0.5) {
        ref.read(drawerStateProvider.notifier).open();
      }
      else {
        ref.read(drawerStateProvider.notifier).close();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDrawerOpen = ref.watch(drawerStateProvider);

    // Listen for drawer state changes and animate accordingly
    ref.listen<bool>(drawerStateProvider, (previous, current) {
      if (current) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return _buildContent(isDrawerOpen);
      },
    );
  }

  Widget _buildContent(bool isDrawerOpen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * widget.drawerWidth;
    final mainScreenOffset = drawerWidth * _animation.value;

    return Container(
      width: screenWidth,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          // Drawer content with gesture detector
          Positioned(
            left: -drawerWidth + mainScreenOffset,
            top: 0,
            bottom: 0,
            width: drawerWidth,
            child: GestureDetector(
              // Enable drag on drawer when drawer is open
              onHorizontalDragStart: isDrawerOpen ? _handleDragStart : null,
              onHorizontalDragUpdate: isDrawerOpen ? _handleDragUpdate : null,
              onHorizontalDragEnd: isDrawerOpen ? _handleDragEnd : null,
              child: Material(
                color: Theme
                    .of(context)
                    .drawerTheme
                    .backgroundColor ??
                    Theme
                        .of(context)
                        .scaffoldBackgroundColor
                        .withOpacity(0.95),
                child: widget.drawer,
              ),
            ),
          ),

          // Main content
          Positioned(
            left: mainScreenOffset,
            top: 0,
            right: -mainScreenOffset,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragStart: _handleDragStart,
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: _handleDragEnd,
              onTap: isDrawerOpen ? () => ref.read(drawerStateProvider.notifier).close() : null,
              child: AbsorbPointer(
                // Only absorb pointer events when drawer is open
                absorbing: isDrawerOpen,
                child: Material(
                  elevation: isDrawerOpen ? 8.0 : 0.0,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom AppBar with menu button that toggles the drawer
class AnimatedDrawerAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final Color? backgroundColor;

  const AnimatedDrawerAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.elevation,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => Size.fromHeight(bottom != null ? kToolbarHeight + bottom!.preferredSize.height : kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: Text(title),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => ref.read(drawerStateProvider.notifier).toggle(),
      ),
      actions: actions,
      bottom: bottom,
      elevation: elevation,
      backgroundColor: backgroundColor ?? Colors.transparent,
    );
  }
}