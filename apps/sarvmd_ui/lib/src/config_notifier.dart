import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:shared_preferences/shared_preferences.dart';

class ConfigNotifier extends ChangeNotifier {
  late core.PageConfig _config;
  core.StaffProfile? _activeProfile;
  Timer? _saveTimer;

  ConfigNotifier([SharedPreferences? prefs]) {
    _activeProfile = core.StaffProfiles.treble;
    _config = _activeProfile!.applyTo(const core.PageConfig());
    if (prefs != null) {
      _loadSync(prefs);
    } else {
      _loadFromPrefs();
    }
  }

  void _loadSync(SharedPreferences prefs) {
    final jsonStr = prefs.getString(_prefKey);
    if (jsonStr != null) {
      try {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        _config = core.PageConfig.fromJson(jsonMap);

        // Restore active profile if it matches
        _activeProfile = null;
        for (final p in core.StaffProfiles.all) {
          if (p.systemLayout == _config.systemLayout) {
            _activeProfile = p;
            break;
          }
        }
      } catch (e) {
        debugPrint('Error loading config from prefs: $e');
      }
    }
  }

  Future<void> initialize() async {
    // If already loaded synchronously, this is a no-op
  }

  static const _prefKey = 'sarvmd_config';

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKey);
    if (jsonStr != null) {
      try {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        _config = core.PageConfig.fromJson(jsonMap);

        // Restore active profile if it matches
        _activeProfile = null;
        for (final p in core.StaffProfiles.all) {
          if (p.systemLayout == _config.systemLayout) {
            _activeProfile = p;
            break;
          }
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading config from prefs: $e');
      }
    }
  }

  void _save() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () async {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_config.toJson());
      await prefs.setString(_prefKey, jsonStr);
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  core.PageConfig get config => _config;
  core.StaffProfile? get activeProfile => _activeProfile;

  core.StaffUIHints get uiHints {
    // Contextual hints: if current layout matches a profile, use its hints.
    for (final profile in core.StaffProfiles.all) {
      if (profile.systemLayout == _config.systemLayout) {
        return profile.uiHints;
      }
    }
    return const core.StaffUIHints();
  }

  core.PageLayout get layout => core.computeLayout(_config);

  void updatePageSize(core.PageSize size) {
    _config = _config.copyWith(pageSize: size);
    notifyListeners();
    _save();
  }

  void updateOrientation(core.PageOrientation orientation) {
    _config = _config.copyWith(orientation: orientation);
    notifyListeners();
    _save();
  }

  void updateStaffConfig(core.StaffConfig staff) {
    _config = _config.copyWith(staffConfig: staff);
    notifyListeners();
    _save();
  }

  void updateMargins(core.Margins margins) {
    _config = _config.copyWith(margins: margins);
    notifyListeners();
    _save();
  }

  void updateLineGap(double mm) {
    updateStaffConfig(core.StaffConfig(
      lineGapMm: mm,
      lineThicknessPt: _config.staffConfig.lineThicknessPt,
      systemGapMm: _config.staffConfig.systemGapMm,
      interStaffGapMm: _config.staffConfig.interStaffGapMm,
    ));
  }

  void updateSystemGap(double mm) {
    updateStaffConfig(core.StaffConfig(
      lineGapMm: _config.staffConfig.lineGapMm,
      lineThicknessPt: _config.staffConfig.lineThicknessPt,
      systemGapMm: mm,
      interStaffGapMm: _config.staffConfig.interStaffGapMm,
    ));
  }

  void updateInterStaffGap(double mm) {
    updateStaffConfig(core.StaffConfig(
      lineGapMm: _config.staffConfig.lineGapMm,
      lineThicknessPt: _config.staffConfig.lineThicknessPt,
      systemGapMm: _config.staffConfig.systemGapMm,
      interStaffGapMm: mm,
    ));
  }

  void updateVerticalMargins(double mm) {
    updateMargins(_config.margins.copyWith(top: mm, bottom: mm));
  }

  void updateHorizontalMargins(double mm) {
    updateMargins(_config.margins.copyWith(left: mm, right: mm));
  }

  void resetToDefaults() {
    applyProfile(core.StaffProfiles.treble);
  }

  /// Reset only margins to their default values.
  void resetMargins() {
    updateMargins(const core.Margins());
  }

  /// Reset only staff spacing to default values.
  void resetSpacing() {
    updateStaffConfig(const core.StaffConfig());
  }

  /// Reset only clef configuration to defaults (no clef).
  void resetClefs() {
    final root = _config.systemLayout.rootGroup;
    final newChildren = root.children.map((c) {
      if (c is core.StaffDefinition) return c.copyWith(clef: () => null);
      return c;
    }).toList();

    _updateSystemLayout(_config.systemLayout.copyWith(
      rootGroup: root.copyWith(children: newChildren),
    ));
  }

  void updatePrimaryClef(core.ClefConfig? clef) {
    _updateStaffDefinition(0, (staff) => staff.copyWith(clef: () => clef));
  }

  void updateSecondaryClef(core.ClefConfig? clef) {
    _updateStaffDefinition(1, (staff) => staff.copyWith(clef: () => clef));
  }

  void _updateStaffDefinition(
      int index, core.StaffDefinition Function(core.StaffDefinition) updater) {
    final root = _config.systemLayout.rootGroup;
    if (index >= root.children.length) return;

    final child = root.children[index];
    if (child is core.StaffDefinition) {
      final newChildren = List<Object>.from(root.children);
      newChildren[index] = updater(child);

      _updateSystemLayout(_config.systemLayout.copyWith(
        rootGroup: root.copyWith(children: newChildren),
      ));
    }
  }

  // --- Tree Mutation Methods ---

  void addStaff({core.StaffDefinition? def}) {
    final root = _config.systemLayout.rootGroup;
    final newDef = (def ?? const core.StaffDefinition()).copyWith(
      uid: DateTime.now().microsecondsSinceEpoch.toString(),
    );
    final newChildren = List<Object>.from(root.children)..add(newDef);
    _updateSystemLayout(_config.systemLayout.copyWith(
      rootGroup: root.copyWith(children: newChildren),
    ));
  }

  void removeStaff(int index) {
    final root = _config.systemLayout.rootGroup;
    if (index < 0 || index >= root.children.length) return;

    final newChildren = List<Object>.from(root.children)..removeAt(index);
    _updateSystemLayout(_config.systemLayout.copyWith(
      rootGroup: root.copyWith(children: newChildren),
    ));
  }

  void updateStaffLines(String uid, int lines) {
    _updateStaffByUid(uid, (staff) => staff.copyWith(lines: lines));
  }

  void updateStaffClef(String uid, core.ClefConfig? clef) {
    _updateStaffByUid(uid, (staff) => staff.copyWith(clef: () => clef));
  }

  void updateStaffInstrumentName(String uid, String? name) {
    _updateStaffByUid(
        uid, (staff) => staff.copyWith(instrumentName: () => name));
  }

  void updateStaffConfigDetails(
    String uid, {
    String? Function()? name,
    String? Function()? abbreviation,
    bool? visible,
    int? lines,
    core.ClefConfig? Function()? clef,
    double? horizontalOffset,
    double? verticalOffset,
    String? fontFamily,
    double? fontSize,
    bool? italic,
  }) {
    _updateStaffByUid(
      uid,
      (staff) => staff.copyWith(
        instrumentName: name,
        instrumentAbbreviation: abbreviation,
        labelVisible: visible,
        lines: lines,
        clef: clef,
        labelHorizontalOffset: horizontalOffset,
        labelVerticalOffset: verticalOffset,
        labelFontFamily: fontFamily,
        labelFontSize: fontSize,
        labelItalic: italic,
      ),
    );
  }

  void _updateStaffByUid(
      String uid, core.StaffDefinition Function(core.StaffDefinition) updater) {
    final root = _config.systemLayout.rootGroup;

    Object? findAndUpdate(Object node) {
      if (node is core.StaffDefinition) {
        if (node.uid == uid) return updater(node);
        return node;
      } else if (node is core.StaffGroup) {
        final newChildren =
            node.children.map((c) => findAndUpdate(c)!).toList();
        return node.copyWith(children: newChildren);
      }
      return node;
    }

    final newRoot = findAndUpdate(root) as core.StaffGroup;
    _updateSystemLayout(_config.systemLayout.copyWith(rootGroup: newRoot));
  }

  void updateGroupConnector(core.SystemConnector connector) {
    final root = _config.systemLayout.rootGroup;
    _updateSystemLayout(_config.systemLayout.copyWith(
      rootGroup: root.copyWith(connector: connector),
    ));
  }

  void updateGroupContinuousBarlines(bool value) {
    final root = _config.systemLayout.rootGroup;
    _updateSystemLayout(_config.systemLayout.copyWith(
      rootGroup: root.copyWith(continuousBarlines: value),
    ));
  }

  void reorderGroupChildren(int groupHash, int oldIndex, int newIndex) {
    final root = _config.systemLayout.rootGroup;

    Object? findAndReorder(Object node) {
      if (node is core.StaffGroup) {
        if (node.hashCode == groupHash) {
          final children = List<Object>.from(node.children);
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = children.removeAt(oldIndex);
          children.insert(newIndex, item);
          return node.copyWith(children: children);
        } else {
          final newChildren =
              node.children.map((c) => findAndReorder(c)!).toList();
          return node.copyWith(children: newChildren);
        }
      }
      return node;
    }

    final newRoot = findAndReorder(root) as core.StaffGroup;
    _updateSystemLayout(_config.systemLayout.copyWith(rootGroup: newRoot));
  }

  void _updateSystemLayout(core.SystemLayout layout) {
    _config = _config.copyWith(systemLayout: layout);

    // Sync active profile: if current layout matches a known profile, set it.
    _activeProfile = null;
    for (final p in core.StaffProfiles.all) {
      if (p.systemLayout == layout) {
        _activeProfile = p;
        break;
      }
    }

    notifyListeners();
    _save();
  }

  // --- Computed Getters for Fast Lane UI ---

  core.StaffDefinition? get _primaryDef {
    final root = _config.systemLayout.rootGroup;
    if (root.children.isEmpty) return null;
    final child = root.children.first;
    return child is core.StaffDefinition ? child : null;
  }

  core.StaffDefinition? get _secondaryDef {
    final root = _config.systemLayout.rootGroup;
    if (root.children.length < 2) return null;
    final child = root.children[1];
    return child is core.StaffDefinition ? child : null;
  }

  core.ClefConfig? get primaryClef => _primaryDef?.clef;
  core.ClefConfig? get secondaryClef => _secondaryDef?.clef;
  int get primaryLines => _primaryDef?.lines ?? 5;
  int get secondaryLines => _secondaryDef?.lines ?? 5;

  /// Apply a [StaffProfile], overriding layout type and clefs while
  /// preserving all spacing and margin settings.
  void applyProfile(core.StaffProfile profile) {
    var newConfig = profile.applyTo(_config);

    // Ensure all staves have unique IDs for stable keying
    final root = newConfig.systemLayout.rootGroup;
    final newChildren = root.children.asMap().entries.map((entry) {
      final index = entry.key;
      final c = entry.value;
      if (c is core.StaffDefinition) {
        return c.copyWith(
          uid: '${DateTime.now().microsecondsSinceEpoch}_$index',
        );
      }
      return c;
    }).toList();

    _config = newConfig.copyWith(
      systemLayout: newConfig.systemLayout.copyWith(
        rootGroup: root.copyWith(children: newChildren),
      ),
    );
    _activeProfile = profile;
    notifyListeners();
    _save();
  }
}
