import 'package:flutter/material.dart';
import 'package:sarv_core/sarv_core.dart' as core;

class ClefConfigWidget extends StatelessWidget {
  const ClefConfigWidget({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final core.ClefConfig? value;
  final ValueChanged<core.ClefConfig?> onChanged;

  bool _isPreset(core.ClefSymbol sym, int line) {
    return value?.symbol == sym && value?.anchorLine == line;
  }

  Widget _buildPresetChip(
      BuildContext context, String title, core.ClefSymbol sym, int line) {
    final selected = _isPreset(sym, line);
    return FilterChip(
      label: Text(title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) =>
          onChanged(core.ClefConfig(symbol: sym, anchorLine: line)),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabled = value == null;
    final activeValue = value ??
        const core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2);
    final selectedSym = activeValue.symbol;

    Widget buildHorizontalTab(core.ClefSymbol sym, String glyph) {
      final isSelected = sym == selectedSym;
      final colorScheme = Theme.of(context).colorScheme;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (isSelected) return;
              int defaultLine = 3;
              if (sym == core.ClefSymbol.g) defaultLine = 2; // Treble
              if (sym == core.ClefSymbol.f) defaultLine = 4; // Bass
              onChanged(core.ClefConfig(symbol: sym, anchorLine: defaultLine));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                glyph,
                style: TextStyle(
                    fontFamily: 'NotoMusic',
                    fontSize: 34,
                    height: 1.0,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
              ),
            ),
          ),
        ),
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Horizontal Tabs Row
        Row(
          children: [
            buildHorizontalTab(core.ClefSymbol.g, '\u{1D11E}'),
            const SizedBox(width: 8),
            buildHorizontalTab(core.ClefSymbol.c, '\u{1D121}'),
            const SizedBox(width: 8),
            buildHorizontalTab(core.ClefSymbol.f, '\u{1D122}'),
          ],
        ),
        const SizedBox(height: 12),

        // Interactive Mini Staff Canvas
        LayoutBuilder(builder: (context, constraints) {
          final gap = constraints.maxWidth / 10;
          return Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.5)),
            ),
            child: Stack(
              children: [
                GestureDetector(
                  onTapUp: (details) {
                    final tappedY = details.localPosition.dy;
                    final staffTop = gap * 2.5;
                    final i = ((tappedY - staffTop) / gap).round();
                    if (i >= 0 && i <= 4) {
                      onChanged(core.ClefConfig(
                          symbol: activeValue.symbol, anchorLine: 5 - i));
                    }
                  },
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, gap * 8.5),
                    painter: MiniStaffClefPainter(
                        activeValue, gap, Theme.of(context).colorScheme),
                  ),
                ),
                // Elegant overlay label
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Line ${activeValue.anchorLine}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),

        // Presets specific to this symbol
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (selectedSym == core.ClefSymbol.g) ...[
              _buildPresetChip(context, 'Treble', core.ClefSymbol.g, 2),
            ],
            if (selectedSym == core.ClefSymbol.c) ...[
              _buildPresetChip(context, 'Alto', core.ClefSymbol.c, 3),
              _buildPresetChip(context, 'Tenor', core.ClefSymbol.c, 4),
              _buildPresetChip(context, 'Soprano', core.ClefSymbol.c, 1),
              _buildPresetChip(context, 'Mezzo', core.ClefSymbol.c, 2),
            ],
            if (selectedSym == core.ClefSymbol.f) ...[
              _buildPresetChip(context, 'Bass', core.ClefSymbol.f, 4),
              _buildPresetChip(context, 'Baritone', core.ClefSymbol.f, 3),
            ],
          ],
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            Switch(
                value: !disabled,
                onChanged: (on) {
                  if (on) {
                    onChanged(const core.ClefConfig(
                        symbol: core.ClefSymbol.g, anchorLine: 2));
                  } else {
                    onChanged(null);
                  }
                }),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedOpacity(
          opacity: disabled ? 0.4 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: disabled,
            child: content,
          ),
        ),
      ],
    );
  }
}

class MiniStaffClefPainter extends CustomPainter {
  const MiniStaffClefPainter(this.clef, this.gap, this.scheme);
  final core.ClefConfig clef;
  final double gap;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final staffColor = scheme.onSurface;
    final highlightColor = scheme.primary;
    final staffTop = gap * 2.5;

    for (var i = 0; i < 5; i++) {
      final lineNum = 5 - i;
      final y = staffTop + i * gap;
      final isAnchor = lineNum == clef.anchorLine;
      canvas.drawLine(
        Offset(gap * 1.6, y),
        Offset(size.width - gap * 0.2, y),
        Paint()
          ..color =
              isAnchor ? highlightColor : staffColor.withValues(alpha: 0.4)
          ..strokeWidth = isAnchor ? gap * 0.12 : gap * 0.05
          ..strokeCap = StrokeCap.round,
      );
    }

    final double anchorSp = switch (clef.symbol) {
      core.ClefSymbol.g => 0.876,
      core.ClefSymbol.c => 2.0,
      core.ClefSymbol.f => 2.578,
    };
    final String glyph = switch (clef.symbol) {
      core.ClefSymbol.g => '\u{1D11E}',
      core.ClefSymbol.c => '\u{1D121}',
      core.ClefSymbol.f => '\u{1D122}',
    };

    final tp = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
            fontFamily: 'NotoMusic', fontSize: gap * 4.0, color: staffColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final ascent = tp.computeLineMetrics().first.ascent;
    final anchorYPx = staffTop + (5 - clef.anchorLine) * gap;
    tp.paint(canvas, Offset(gap * 0.05, anchorYPx + anchorSp * gap - ascent));
  }

  @override
  bool shouldRepaint(MiniStaffClefPainter old) =>
      old.clef != clef || old.gap != gap;
}
