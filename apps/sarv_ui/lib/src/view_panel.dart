import 'package:flutter/material.dart';
import 'view_notifier.dart';

class ViewPanel extends StatelessWidget {
  const ViewPanel({
    super.key,
    required this.viewNotifier,
    required this.transformationController,
  });

  final ViewNotifier viewNotifier;
  final TransformationController transformationController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 48),
                Text(
                  'VIEW',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),
                const _SectionHeader(title: 'Theme'),
                ListenableBuilder(
                  listenable: viewNotifier,
                  builder: (context, _) {
                    IconData iconData;
                    String tooltip;
                    if (viewNotifier.themeMode == ThemeMode.system) {
                      iconData = Icons.brightness_auto;
                      tooltip = 'System Theme';
                    } else if (viewNotifier.themeMode == ThemeMode.dark) {
                      iconData = Icons.dark_mode;
                      tooltip = 'Dark Theme';
                    } else {
                      iconData = Icons.light_mode;
                      tooltip = 'Light Theme';
                    }

                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Tooltip(
                        message: tooltip,
                        child: IconButton(
                          icon: Icon(iconData,
                              color: Theme.of(context).colorScheme.primary),
                          onPressed: viewNotifier.toggleThemeMode,
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Divider(
                    color: Theme.of(context).colorScheme.outline, height: 32),
                const _SectionHeader(title: 'Zoom'),
                ListenableBuilder(
                  listenable: transformationController,
                  builder: (context, _) {
                    final currentZoom =
                        transformationController.value.getMaxScaleOnAxis();
                    return _ZoomControls(
                      value: currentZoom.clamp(0.1, 4.0),
                      min: 0.1,
                      max: 4.0,
                      onChanged: (v) {
                        final t =
                            transformationController.value.getTranslation();
                        transformationController.value =
                            Matrix4.translationValues(t.x, t.y, 0.0)
                              ..multiply(Matrix4.diagonal3Values(v, v, 1.0));
                      },
                    );
                  },
                ),
                Divider(
                    color: Theme.of(context).colorScheme.outline, height: 32),
                const _SectionHeader(title: 'Guides'),
                ListenableBuilder(
                  listenable: viewNotifier,
                  builder: (context, _) {
                    return Column(
                      children: [
                        _GuideToggle(
                          label: 'Mouse Wings',
                          value:
                              viewNotifier.isGuideActive(GuideType.rulerWings),
                          onChanged: (v) => viewNotifier.toggleGuide(
                              GuideType.rulerWings, v ?? false),
                        ),
                        _GuideToggle(
                          label: 'Paper Edges',
                          value:
                              viewNotifier.isGuideActive(GuideType.paperEdges),
                          onChanged: (v) => viewNotifier.toggleGuide(
                              GuideType.paperEdges, v ?? false),
                        ),
                        _GuideToggle(
                          label: 'Paper Centers',
                          value: viewNotifier
                              .isGuideActive(GuideType.paperCenters),
                          onChanged: (v) => viewNotifier.toggleGuide(
                              GuideType.paperCenters, v ?? false),
                        ),
                        _GuideToggle(
                          label: 'Document Margins',
                          value: viewNotifier.isGuideActive(GuideType.margins),
                          onChanged: (v) => viewNotifier.toggleGuide(
                              GuideType.margins, v ?? false),
                        ),
                        _GuideToggle(
                          label: 'Staff Bounds',
                          value:
                              viewNotifier.isGuideActive(GuideType.staffBounds),
                          onChanged: (v) => viewNotifier.toggleGuide(
                              GuideType.staffBounds, v ?? false),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ZoomControls extends StatefulWidget {
  const _ZoomControls({
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;

  @override
  State<_ZoomControls> createState() => _ZoomControlsState();
}

class _ZoomControlsState extends State<_ZoomControls> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(_ZoomControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String? text) {
    if (text == null) return;
    final parsed = double.tryParse(text);
    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
      _controller.text = clamped.toStringAsFixed(2);
    } else {
      _controller.text = widget.value.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle_outline,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20),
                  onPressed: () => widget.onChanged(
                      (widget.value - 0.1).clamp(widget.min, widget.max)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20),
                  onPressed: () => widget.onChanged(
                      (widget.value + 0.1).clamp(widget.min, widget.max)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: TextField(
                controller: _controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
                onSubmitted: _submit,
                onTapOutside: (_) {
                  _submit(_controller.text);
                  FocusManager.instance.primaryFocus?.unfocus();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: widget.value,
          min: widget.min,
          max: widget.max,
          onChanged: widget.onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ],
    );
  }
}

class _GuideToggle extends StatelessWidget {
  const _GuideToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: Theme.of(context)
            .colorScheme
            .onSurfaceVariant
            .withValues(alpha: 0.5),
      ),
      child: CheckboxListTile(
        title: Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13)),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
        checkColor: Theme.of(context).colorScheme.surface,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
      ),
    );
  }
}
