// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive context menu controller supporting both:
/// 1. Click mode: Tap opens sticky context menu; user taps an option to select.
/// 2. Press-and-Hold Drag mode: Long press / hold opens context menu immediately,
///    tracks drag coordinates over menu items, highlights target under pointer,
///    and selects on release (or cancels if released outside).
class HoldDragContextMenu<T> extends StatefulWidget {
  const HoldDragContextMenu({
    super.key,
    required this.buttonBuilder,
    required this.menuBuilder,
    required this.items,
    required this.onSelect,
    this.previewBuilder,
    this.menuOffset = const Offset(0, 8),
  });

  final Widget Function(BuildContext context, VoidCallback onTap) buttonBuilder;
  final Widget Function(
    BuildContext context,
    T? hoveredValue,
    Map<T, GlobalKey> itemKeys,
    ValueChanged<T> onSelect,
  ) menuBuilder;
  final Widget Function(BuildContext context, T hoveredValue)? previewBuilder;
  final List<T> items;
  final ValueChanged<T> onSelect;
  final Offset menuOffset;

  @override
  State<HoldDragContextMenu<T>> createState() => _HoldDragContextMenuState<T>();
}

class _HoldDragContextMenuState<T> extends State<HoldDragContextMenu<T>> {
  final GlobalKey _buttonKey = GlobalKey();
  final Map<T, GlobalKey> _itemKeys = {};
  OverlayEntry? _overlayEntry;
  Timer? _holdTimer;
  Offset? _downPos;
  Offset? _currentPointerPos;
  bool _isHoldDragMode = false;
  T? _hoveredValue;

  @override
  void initState() {
    super.initState();
    _updateKeys();
  }

  @override
  void didUpdateWidget(HoldDragContextMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateKeys();
  }

  void _updateKeys() {
    for (final item in widget.items) {
      _itemKeys.putIfAbsent(item, () => GlobalKey());
    }
  }

  void _showOverlay({bool isHoldDrag = false}) {
    if (_overlayEntry != null) return;

    _isHoldDragMode = isHoldDrag;
    if (isHoldDrag) {
      HapticFeedback.selectionClick();
    }

    final renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final buttonPos = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    final screenSize = MediaQuery.sizeOf(context);
    final isRightSide = buttonPos.dx > (screenSize.width * 0.5);
    final renderAbove = buttonPos.dy > (screenSize.height * 0.5);
    final mediaPadding = MediaQuery.paddingOf(context);

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            final double? top = renderAbove
                ? null
                : buttonPos.dy + buttonSize.height + widget.menuOffset.dy;
            final double? bottom = renderAbove
                ? (screenSize.height - buttonPos.dy + widget.menuOffset.dy + 4.0)
                : null;

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) {},
              onHorizontalDragUpdate: (_) {},
              onHorizontalDragEnd: (_) {},
              onVerticalDragStart: (_) {},
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
              child: Stack(
                children: [
                  // Backdrop listener for tap mode dismiss
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => _hideOverlay(),
                      child: const SizedBox.expand(),
                    ),
                  ),

                  // Positioned Context Menu
                  Positioned(
                    top: top,
                    bottom: bottom,
                    left: isRightSide
                        ? null
                        : (buttonPos.dx + widget.menuOffset.dx).clamp(10.0, screenSize.width - 260.0),
                    right: isRightSide
                        ? (screenSize.width - buttonPos.dx - buttonSize.width - widget.menuOffset.dx)
                            .clamp(10.0, screenSize.width - 260.0)
                        : null,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Material(
                        color: Colors.transparent,
                        child: widget.menuBuilder(
                          context,
                          _hoveredValue,
                          _itemKeys,
                          (val) {
                            widget.onSelect(val);
                            _hideOverlay();
                          },
                        ),
                      ),
                    ),
                  ),

                  // Fingertip Active Selection Preview Bubble (Offset above user's finger)
                  if (_isHoldDragMode && _hoveredValue != null && _currentPointerPos != null)
                    Positioned(
                      left: (_currentPointerPos!.dx - 70.0).clamp(16.0, screenSize.width - 156.0),
                      top: (_currentPointerPos!.dy - 68.0).clamp(mediaPadding.top + 8.0, screenSize.height - 80.0),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: IgnorePointer(
                          child: Material(
                            color: Colors.transparent,
                            child: _FingertipPreviewBubble(
                              child: widget.previewBuilder != null
                                  ? widget.previewBuilder!(context, _hoveredValue!)
                                  : Text(
                                      _hoveredValue.toString(),
                                      style: TextStyle(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isHoldDragMode = false;
    _hoveredValue = null;
    _currentPointerPos = null;
  }

  void _updateHoverFromPointer(Offset pointerPos) {
    if (_overlayEntry == null) return;
    T? found;
    for (final entry in _itemKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.attached) {
        final pos = box.localToGlobal(Offset.zero);
        final rect = pos & box.size;
        if (rect.contains(pointerPos)) {
          found = entry.key;
          break;
        }
      }
    }

    if (_hoveredValue != found) {
      if (found != null) {
        HapticFeedback.selectionClick();
      }
      _hoveredValue = found;
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _downPos = event.position;
    _currentPointerPos = event.position;
    _isHoldDragMode = false;
    _hoveredValue = null;

    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(milliseconds: 180), () {
      if (_downPos != null) {
        _showOverlay(isHoldDrag: true);
        _updateHoverFromPointer(_downPos!);
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    _currentPointerPos = event.position;
    if (_downPos != null && !_isHoldDragMode) {
      final dist = (event.position - _downPos!).distance;
      if (dist > 8.0) {
        _holdTimer?.cancel();
        _showOverlay(isHoldDrag: true);
      }
    }

    if (_isHoldDragMode) {
      _updateHoverFromPointer(event.position);
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _holdTimer?.cancel();
    _holdTimer = null;

    if (_isHoldDragMode) {
      final selected = _hoveredValue;
      _hideOverlay();
      if (selected != null) {
        widget.onSelect(selected);
      }
    } else {
      if (_overlayEntry == null) {
        _showOverlay(isHoldDrag: false);
      }
    }
    _downPos = null;
    _currentPointerPos = null;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _hideOverlay();
    _downPos = null;
    _currentPointerPos = null;
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) {},
      onHorizontalDragUpdate: (_) {},
      onHorizontalDragEnd: (_) {},
      onVerticalDragStart: (_) {},
      onVerticalDragUpdate: (_) {},
      onVerticalDragEnd: (_) {},
      child: Listener(
        key: _buttonKey,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: widget.buttonBuilder(context, () {
          if (_overlayEntry == null) {
            _showOverlay(isHoldDrag: false);
          } else {
            _hideOverlay();
          }
        }),
      ),
    );
  }
}

/// Elevated callout bubble rendered clear of the user's fingertip during hold-drag selection.
class _FingertipPreviewBubble extends StatelessWidget {
  const _FingertipPreviewBubble({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedScale(
      scale: 1.05,
      duration: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: cs.primary,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.3),
              blurRadius: 16.0,
              spreadRadius: 1.0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12.0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
