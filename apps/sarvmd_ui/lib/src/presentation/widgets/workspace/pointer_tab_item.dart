import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/document/document_state.dart';
import '../../../logic/workspace/document_session.dart';

/// An individual tab item in the desktop [PointerTabBar].
class PointerTabItem extends StatefulWidget {
  final DocumentSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onMiddleClick;

  const PointerTabItem({
    super.key,
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    required this.onMiddleClick,
  });

  @override
  State<PointerTabItem> createState() => _PointerTabItemState();
}

class _PointerTabItemState extends State<PointerTabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentCubit, DocumentState>(
      bloc: widget.session.cubit,
      builder: (context, docState) {
        final cs = Theme.of(context).colorScheme;
        final isActive = widget.isActive;
        final isDirty = docState.isDirty;
        final title = docState.displayName;

        final backgroundColor = isActive
            ? cs.surface
            : _isHovered
                ? cs.surfaceContainerHigh.withValues(alpha: 0.7)
                : Colors.transparent;

        final textColor = isActive
            ? cs.onSurface
            : _isHovered
                ? cs.onSurface
                : cs.onSurfaceVariant;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Listener(
            onPointerDown: (event) {
              if (event.buttons == kMiddleMouseButton) {
                widget.onMiddleClick();
              }
            },
            child: GestureDetector(
              onTap: widget.onTap,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(
                  minWidth: 100.0,
                  maxWidth: 180.0,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: isActive ? cs.primary : Colors.transparent,
                      width: 2.0,
                    ),
                    right: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                    bottom: BorderSide(
                      color: isActive ? Colors.transparent : cs.outlineVariant.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Small musical manuscript icon
                    Icon(
                      Icons.article_outlined,
                      size: 14.0,
                      color: isActive ? cs.primary : cs.outline,
                    ),
                    const SizedBox(width: 6.0),

                    // Truncated Title
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4.0),

                    // Dirty Dot Indicator and/or Close Button
                    SizedBox(
                      height: 18.0,
                      child: Center(
                        child: _buildRightAction(context, cs, isDirty, isActive),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRightAction(BuildContext context, ColorScheme cs, bool isDirty, bool isActive) {
    final dirtyDot = Container(
      key: ValueKey('tab_dirty_${widget.session.id}'),
      width: 7.0,
      height: 7.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primary,
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.5),
            blurRadius: 3.0,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );

    final closeButton = Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('tab_close_${widget.session.id}'),
        borderRadius: BorderRadius.circular(9.0),
        onTap: widget.onClose,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Icon(
            Icons.close,
            size: 13.0,
            color: isActive ? cs.outline : cs.onSurfaceVariant,
          ),
        ),
      ),
    );

    if (isActive) {
      if (isDirty) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dirtyDot,
            const SizedBox(width: 4.0),
            closeButton,
          ],
        );
      }
      return closeButton;
    }

    if (_isHovered) {
      return closeButton;
    }

    if (isDirty) {
      return Tooltip(
        message: 'Unsaved changes',
        child: dirtyDot,
      );
    }

    return const SizedBox.shrink();
  }
}
