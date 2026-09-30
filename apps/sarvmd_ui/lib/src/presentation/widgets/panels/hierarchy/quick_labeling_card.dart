import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../../core/theme/app_metrics.dart';
import 'labeling/group_numbering_section.dart';
import 'labeling/label_typography_cluster.dart';

import '../../dialogs/group_engraving_dialog.dart';
import '../../../../logic/document/document_cubit.dart';

/// Semantic alias for [QuickLabelingCard].
typedef InlineLabelEditor = QuickLabelingCard;

/// Heuristically generates standard musical abbreviations from instrument/group names.
String generateAutoAbbreviation(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';

  final lower = trimmed.toLowerCase();
  if (lower.contains('woodwind')) return 'Ww.';
  if (lower.contains('brass')) return 'Br.';
  if (lower.contains('string')) return 'Str.';
  if (lower.contains('percussion')) return 'Perc.';
  if (lower.contains('choir') || lower.contains('vocal')) return 'Voc.';
  if (lower.contains('violin 1') || lower.contains('violin i')) return 'Vln. I';
  if (lower.contains('violin 2') || lower.contains('violin ii')) return 'Vln. II';
  if (lower.contains('violin')) return 'Vln.';
  if (lower.contains('viola')) return 'Vla.';
  if (lower.contains('violoncello') || lower.contains('cello')) return 'Vc.';
  if (lower.contains('double bass') || lower.contains('contrabass')) return 'Cb.';
  if (lower.contains('flute')) return 'Fl.';
  if (lower.contains('oboe')) return 'Ob.';
  if (lower.contains('clarinet')) return 'Cl.';
  if (lower.contains('bassoon')) return 'Bsn.';
  if (lower.contains('horn')) return 'Hn.';
  if (lower.contains('trumpet')) return 'Tpt.';
  if (lower.contains('trombone')) return 'Tbn.';
  if (lower.contains('tuba')) return 'Tba.';
  if (lower.contains('piano')) return 'Pno.';

  final words = trimmed.split(RegExp(r'\s+'));
  if (words.length == 1) {
    return words.first.length > 4 ? '${words.first.substring(0, 3)}.' : words.first;
  } else {
    return words.map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}.' : '').join('');
  }
}

/// Standalone interactive form card for inline label and engraving typography customization.
class QuickLabelingCard extends StatefulWidget {
  const QuickLabelingCard({
    super.key,
    required this.title,
    required this.initialName,
    required this.initialAbbreviation,
    required this.onSave,
    required this.onCancel,
    this.group,
    this.notifier,
    this.childStaves,
    this.onAutoNumberChildStaves,
    this.initialLabelPlacement,
    this.initialNumberingStyle,
    this.initialDescriptorPlacement,
    this.initialHeaderVisibility,
    this.initialLabelStyle,
    this.onSaveGroup,
    this.onSaveStaffStyle,
  });

  final String title;
  final String initialName;
  final String initialAbbreviation;
  final void Function(String name, String abbreviation) onSave;
  final VoidCallback onCancel;
  final core.StaffNodeGroup? group;
  final DocumentCubit? notifier;
  final List<core.StaffDefinition>? childStaves;
  final VoidCallback? onAutoNumberChildStaves;
  final core.GroupLabelPlacement? initialLabelPlacement;
  final core.GroupNumberingStyle? initialNumberingStyle;
  final core.DescriptorPlacement? initialDescriptorPlacement;
  final core.GroupHeaderVisibility? initialHeaderVisibility;
  final core.StaffLabelStyle? initialLabelStyle;
  final void Function(core.StaffLabelStyle style)? onSaveStaffStyle;
  final void Function(
    String name,
    String abbreviation,
    core.GroupLabelPlacement labelPlacement,
    core.GroupNumberingStyle numberingStyle,
    core.DescriptorPlacement descriptorPlacement,
    core.GroupHeaderVisibility headerVisibility,
  )? onSaveGroup;

  @override
  State<QuickLabelingCard> createState() => _QuickLabelingCardState();
}

class _QuickLabelingCardState extends State<QuickLabelingCard> {
  late TextEditingController _nameController;
  late TextEditingController _abbrevController;
  late FocusNode _nameFocusNode;
  late FocusNode _abbrevFocusNode;
  late core.GroupLabelPlacement _labelPlacement;
  late core.GroupNumberingStyle _numberingStyle;
  late core.DescriptorPlacement _descriptorPlacement;
  late core.GroupHeaderVisibility _headerVisibility;
  core.StaffLabelStyle? _staffStyle;
  String _suggestedAbbrev = '';
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _abbrevController = TextEditingController(text: widget.initialAbbreviation);
    _nameFocusNode = FocusNode();
    _abbrevFocusNode = FocusNode();
    _labelPlacement =
        widget.initialLabelPlacement ?? core.GroupLabelPlacement.margin;
    _numberingStyle =
        widget.initialNumberingStyle ?? core.GroupNumberingStyle.none;
    _descriptorPlacement = widget.initialDescriptorPlacement ??
        core.DescriptorPlacement.enclosedByConnector;
    _headerVisibility = widget.initialHeaderVisibility ??
        core.GroupHeaderVisibility.firstSystemOnly;
    _staffStyle = widget.initialLabelStyle;

    _updateSuggestion(_nameController.text);

    _nameController.addListener(() {
      _updateSuggestion(_nameController.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
        Scrollable.ensureVisible(
          context,
          alignment: 0.2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _updateSuggestion(String name) {
    final auto = generateAutoAbbreviation(name);
    if (auto != _suggestedAbbrev) {
      setState(() {
        _suggestedAbbrev = auto;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _abbrevController.dispose();
    _nameFocusNode.dispose();
    _abbrevFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted) return;
    _submitted = true;
    final name = _nameController.text.trim();
    var abbrev = _abbrevController.text.trim();
    if (abbrev.isEmpty && _suggestedAbbrev.isNotEmpty) {
      abbrev = _suggestedAbbrev;
    }
    if (widget.onSaveGroup != null) {
      widget.onSaveGroup!(
        name,
        abbrev,
        _labelPlacement,
        _numberingStyle,
        _descriptorPlacement,
        _headerVisibility,
      );
    } else {
      widget.onSave(name, abbrev);
      if (widget.onSaveStaffStyle != null && _staffStyle != null) {
        widget.onSaveStaffStyle!(_staffStyle!);
      }
    }
  }

  void _cancel() {
    if (_submitted) return;
    _submitted = true;
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _submit();
        }
      },
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            _cancel();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TapRegion(
          groupId: 'quick_labeling_${widget.hashCode}',
          onTapOutside: (_) => _submit(),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: cs.primary.withValues(alpha: 0.5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title and compact action buttons
                Row(
                  children: [
                    Icon(Icons.label_outlined, size: 15, color: cs.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: _cancel,
                      constraints:
                          const BoxConstraints(minWidth: 26, minHeight: 26),
                      padding: EdgeInsets.zero,
                      tooltip: 'Cancel (Esc)',
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Save',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Full Name Field
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    scrollPadding: AppSpacing.keyboardScrollPadding,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Full Name / Instrument',
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                      floatingLabelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                      hintText: 'e.g., Violin I',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.6),
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.7),
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: cs.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onSubmitted: (_) {
                      if (_abbrevController.text.isNotEmpty ||
                          _suggestedAbbrev.isNotEmpty) {
                        _submit();
                      } else {
                        _abbrevFocusNode.requestFocus();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Abbreviation Field + Auto Chip
                LayoutBuilder(
                  builder: (context, abbrevConstraints) {
                    final isAbbrevNarrow = abbrevConstraints.maxWidth < 250;
                    final chipWidget = (_suggestedAbbrev.isNotEmpty &&
                            _suggestedAbbrev != _abbrevController.text)
                        ? InkWell(
                            onTap: () {
                              setState(() {
                                _abbrevController.text = _suggestedAbbrev;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: cs.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome,
                                      size: 11, color: cs.onPrimaryContainer),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _suggestedAbbrev,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onPrimaryContainer,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null;

                    final abbrevField = SizedBox(
                      height: 42,
                      child: TextField(
                        controller: _abbrevController,
                        focusNode: _abbrevFocusNode,
                        scrollPadding: AppSpacing.keyboardScrollPadding,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Abbreviation',
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                          floatingLabelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                          ),
                          hintText: 'e.g., Vln. 1',
                          hintStyle: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.6),
                              width: 1.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.7),
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: cs.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    );

                    if (isAbbrevNarrow && chipWidget != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          abbrevField,
                          const SizedBox(height: 6),
                          chipWidget,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: abbrevField),
                        if (chipWidget != null) ...[
                          const SizedBox(width: 8),
                          chipWidget,
                        ],
                      ],
                    );
                  },
                ),
                if (widget.initialLabelPlacement != null ||
                    widget.onSaveGroup != null) ...[
                  if (widget.group != null && widget.notifier != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        showGroupEngravingDialog(
                          context,
                          group: widget.group!,
                          notifier: widget.notifier!,
                          onAutoNumberChildStaves:
                              widget.onAutoNumberChildStaves,
                        );
                      },
                      icon: Icon(Icons.tune_rounded,
                          size: 14, color: cs.primary),
                      label: Text(
                        'Engraving Options Modal...',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        side: BorderSide(
                            color: cs.primary.withValues(alpha: 0.5)),
                      ),
                    ),
                  ],
                  GroupNumberingSection(
                    labelPlacement: _labelPlacement,
                    numberingStyle: _numberingStyle,
                    descriptorPlacement: _descriptorPlacement,
                    headerVisibility: _headerVisibility,
                    onLabelPlacementChanged: (val) =>
                        setState(() => _labelPlacement = val),
                    onNumberingStyleChanged: (val) =>
                        setState(() => _numberingStyle = val),
                    onDescriptorPlacementChanged: (val) =>
                        setState(() => _descriptorPlacement = val),
                    onHeaderVisibilityChanged: (val) =>
                        setState(() => _headerVisibility = val),
                    childStaves: widget.childStaves,
                    onAutoNumberChildStaves: widget.onAutoNumberChildStaves,
                  ),
                ],
                if (widget.initialLabelStyle != null && _staffStyle != null) ...[
                  const SizedBox(height: 10),
                  LabelTypographyCluster(
                    style: _staffStyle!,
                    onChanged: (newStyle) =>
                        setState(() => _staffStyle = newStyle),
                  ),
                ],
                const SizedBox(height: 8),

                // Agile shortcut hint footer
                Row(
                  children: [
                    Icon(
                      Icons.keyboard_return_rounded,
                      size: 11,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Enter to save • Esc to cancel • Click outside to finish',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
