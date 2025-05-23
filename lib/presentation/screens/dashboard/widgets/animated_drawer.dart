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
    Key? key,
    required this.drawer,
    required this.child,
    this.drawerWidth = 0.8, // 80% of screen width
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.easeInOut,
    this.enableGestures = true,
  }) : super(key: key);

  @override
  ConsumerState<AnimatedDrawer> createState() => _AnimatedDrawerState();
}

class _AnimatedDrawerState extends ConsumerState<AnimatedDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late double _drawerWidth;

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

    // REMOVE the ref.listen from here
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    ref.read(drawerStateProvider.notifier).toggle();
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

    if (isDrawerOpen) {
      // If drawer is open, only allow dragging to close (leftwards)
      if (delta < 0) {
        final dragPercentage = delta.abs() / (_drawerWidth * screenWidth);
        _animationController.value = 1.0 - dragPercentage.clamp(0.0, 1.0);
      }
    } else {
      // If drawer is closed, only allow dragging to open (rightwards)
      if (delta > 0) {
        final dragPercentage = delta / (_drawerWidth * screenWidth);
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
    } else {
      // If drawer is closed and swiping right (positive velocity)
      if (velocity > 300 || _animationController.value > 0.5) {
        ref.read(drawerStateProvider.notifier).open();
      } else {
        ref.read(drawerStateProvider.notifier).close();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDrawerOpen = ref.watch(drawerStateProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    _drawerWidth = widget.drawerWidth;

    // MOVE the listener to the build method
    // Listen for drawer state changes and animate accordingly
    ref.listen<bool>(drawerStateProvider, (previous, current) {
      if (current) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });

    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final slideAmount = _drawerWidth * screenWidth * _animation.value;

          return Stack(
            children: [
              // Drawer background - fills the entire screen
              Container(
                color: Theme.of(context).drawerTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
              ),

              // Drawer content - positioned on the left
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _drawerWidth * screenWidth,
                child: widget.drawer,
              ),

              // Main content - slides to the right
              Transform.translate(
                offset: Offset(slideAmount, 0),
                child: Material(
                  elevation: 8.0,
                  child: Container(
                    height: double.infinity,
                    width: screenWidth,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: widget.child,
                  ),
                ),
              ),

              // Semi-transparent overlay to capture taps when drawer is open
              if (isDrawerOpen)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: screenWidth - (screenWidth * _drawerWidth),
                  child: GestureDetector(
                    onTap: () => ref.read(drawerStateProvider.notifier).close(),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// No changes needed to AnimatedDrawerAppBar since it doesn't use ref.listen
class AnimatedDrawerAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final Color? backgroundColor;

  const AnimatedDrawerAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.bottom,
    this.elevation,
    this.backgroundColor,
  }) : super(key: key);

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