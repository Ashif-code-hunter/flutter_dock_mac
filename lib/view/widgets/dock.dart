import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

import 'package:mac_dock/core/constant/values.dart';

class Dock<T> extends StatefulWidget {

  /// Creates a dock widget.
  ///
  /// The [builder] parameter is required and defines how each item is rendered.
  /// The [items] parameter provides the list of items to display in the dock.
  /// The [onReorder] callback is optional and is called when items are reordered.
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
    this.onReorder,
  });

  final List<T> items;
  final Widget Function(T) builder;
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T> extends State<Dock<T>> with TickerProviderStateMixin {
  late final List<T> _items = widget.items.toList();
  Offset? _dragPosition;
  int? _draggedIndex;
  bool _isDragging = false;
  bool _isOutsideContainer = false;
  final GlobalKey _containerKey = GlobalKey();
  final List<GlobalKey> _keys = [];
  late AnimationController _scaleController;
  DateTime? _lastSwapTime;
  static const _swapDebounceTime = Duration(milliseconds: 150);
  Offset? _lastDragPosition;
  bool _isAnimatingSwap = false;


  @override
  void initState() {
    super.initState();
    _keys.addAll(List.generate(
      widget.items.length,
          (index) => GlobalKey(debugLabel: 'dock_item_$index'),
    ));

    _scaleController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }
  /// Determines if the given position is outside the dock container.
  ///
  /// Used to handle drag and drop behavior when items are moved outside the dock.
  bool _isPositionOutsideContainer(Offset position) {
    final RenderBox container = _containerKey.currentContext?.findRenderObject() as RenderBox;
    final containerPosition = container.localToGlobal(Offset.zero);
    final containerSize = container.size;

    final isOutside = position.dx < containerPosition.dx - baseWidth / 2 ||
        position.dx > containerPosition.dx + containerSize.width + baseWidth / 2 ||
        position.dy < containerPosition.dy - baseHeight / 2 ||
        position.dy > containerPosition.dy + containerSize.height + baseHeight / 2;
    return isOutside;
  }


  /// Calculates the scale factor for an item based on drag position.
  ///
  /// Uses a sine curve for smooth scaling transitions.
  double _calculateScale(int index) {
    if (!_isDragging || _dragPosition == null || _draggedIndex == index) {
      return 1.0;
    }

    final itemWidth = baseWidth + spacing;
    final dragCenter = _dragPosition!.dx;
    final itemCenter = index * itemWidth + itemWidth / 2;
    final distance = (dragCenter - itemCenter).abs();

    const maxDistance = 100.0;
    if (distance > maxDistance) return 1.0;

    final t = (maxDistance - distance) / maxDistance;
    return 1.0 + maxScaleIncrease * (math.sin(t * math.pi / 2));
  }

  /// Handles the animation when items are swapped during reordering.
  ///
  /// Includes debouncing to prevent rapid consecutive swaps.
  void _animateSwap(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;

    final now = DateTime.now();
    if (_lastSwapTime != null &&
        now.difference(_lastSwapTime!) < _swapDebounceTime) {
      return;
    }

    if (_isAnimatingSwap) return;

    _lastSwapTime = now;
    _isAnimatingSwap = true;

    setState(() {
      final item = _items.removeAt(fromIndex);
      _items.insert(toIndex, item);
      final key = _keys.removeAt(fromIndex);
      _keys.insert(toIndex, key);
      _draggedIndex = toIndex;
    });

    Future.delayed(swapDuration, () {
      if (mounted) {
        setState(() {
          _isAnimatingSwap = false;
        });
      }
    });
  }


  /// Returns an [Offset] that determines the item's animated position:
  /// - Returns [Offset.zero] if no drag operation is active
  /// - Returns [Offset(0.5, 0)] for items before the dragged item
  /// - Returns [Offset(-0.5, 0)] for items after the dragged item
  Offset _getItemOffset(int index) {
    if (!_isDragging || !_isOutsideContainer || _draggedIndex == null) {
      return Offset.zero;
    }

    if (index < _draggedIndex!) {
      return const Offset(0.5, 0);
    } else if (index > _draggedIndex!) {
      return const Offset(-0.5, 0);
    }
    return Offset.zero;
  }

  /// Updates [_dragPosition] with the converted local coordinates used for:
  /// - Calculating scaling effects
  /// - Determining item positions
  void _updateDragPosition(Offset globalPosition) {
    setState(() {
      final RenderBox box = context.findRenderObject() as RenderBox;
      _dragPosition = box.globalToLocal(globalPosition);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            key: _containerKey,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: IntrinsicWidth(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_items.length, (index) {
                  return _buildDockItem(index);
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds an individual dock item with scaling and animation effects.
  ///
  /// Handles drag and drop interactions and hover effects.

  Widget _buildDockItem(int index) {
    final item = _items[index];
    final isBeingDragged = index == _draggedIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:6),
      child: MouseRegion(
        onEnter: (_) {
          if (_isDragging && _draggedIndex != null && _draggedIndex != index && _isOutsideContainer) {
            _animateSwap(_draggedIndex!, index);
          }
        },
        child: Draggable<int>(
          key: _keys[index],
          data: index,
          feedback: Material(
            color: Colors.transparent,
            child: _buildIcon(item, 1.1, true),
          ),
          childWhenDragging: AnimatedOpacity(
            duration: swapDuration,
            opacity: 0,
            child: _buildIcon(item, 1.0, false),
          ),
          onDragStarted: () {
            setState(() {
              _draggedIndex = index;
              _isDragging = true;
              _isOutsideContainer = false;
            });
            _scaleController.forward();
          },
          onDragEnd: (details) {
            setState(() {
              _draggedIndex = null;
              _isDragging = false;
              _isOutsideContainer = false;
              _dragPosition = null;
            });
            _scaleController.reverse();
          },
          onDragUpdate: (details) {
            if (_lastDragPosition != null) {
              final distance = (details.globalPosition - _lastDragPosition!).distance;
              if (distance < 5.0) return; // Ignore tiny movements
            }
            _lastDragPosition = details.globalPosition;

            final isOutside = _isPositionOutsideContainer(details.globalPosition);
            if (isOutside != _isOutsideContainer) {
              setState(() {
                _isOutsideContainer = isOutside;
              });
            }
            _updateDragPosition(details.globalPosition);
          },
          child: DragTarget<int>(
            onMove: (details) {
              if (_draggedIndex != null && _draggedIndex != index) {
                _animateSwap(_draggedIndex!, index);
              }
            },
            onAccept: (fromIndex) {
              if (fromIndex != index) {
                setState(() {
                  final item = _items.removeAt(fromIndex);
                  _items.insert(index, item);
                  final key = _keys.removeAt(fromIndex);
                  _keys.insert(index, key);
                  _draggedIndex = index;
                });
                widget.onReorder?.call(fromIndex, index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              final scale = _calculateScale(index);

              return AnimatedSlide(
                duration: swapDuration,
                curve: animationCurve,
                offset: _getItemOffset(index),
                child: _buildIcon(item, scale, false),
              );
            },
          ),
        ),
      ),
    );
  }


  /// Creates a container with smooth animations for size changes, shadow effects,
  /// and scaling transitions. The appearance adapts based on whether the item
  /// is being dragged.
  Widget _buildIcon(T item, double scale, bool isDraggedItem) {
    final size = baseWidth + (maxWidth - baseWidth) * (scale - 1);
    final height = baseHeight + (maxHeight - baseHeight) * (scale - 1);

    return AnimatedContainer(
      duration: Duration(milliseconds: isDraggedItem ? 0 : 200),
      curve: animationCurve,
      width: size,
      height: height,
      decoration: BoxDecoration(
        color: Colors.primaries[item.hashCode % Colors.primaries.length],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDraggedItem ? 0.3 : 0.2),
            blurRadius: isDraggedItem ? 12 : 8,
            spreadRadius: isDraggedItem ? 2 : 0,
            offset: Offset(0, isDraggedItem ? 4 : 2),
          ),
        ],
      ),
      child: Center(
        child: AnimatedScale(
          duration: Duration(milliseconds: isDraggedItem ? 0 : 200),
          scale: scale,
          curve: animationCurve,
          child: widget.builder(item),
        ),
      ),
    );
  }



}