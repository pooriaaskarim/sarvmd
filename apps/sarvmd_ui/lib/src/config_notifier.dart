import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

class ConfigNotifier extends ChangeNotifier {
  core.PageConfig _config = const core.PageConfig();

  core.PageConfig get config => _config;

  core.PageLayout get layout => core.computeLayout(_config);

  void updatePageSize(core.PageSize size) {
    _config = core.PageConfig(
      pageSize: size,
      orientation: _config.orientation,
      layoutType: _config.layoutType,
      staffConfig: _config.staffConfig,
      margins: _config.margins,
      primaryClef: _config.primaryClef,
      secondaryClef: _config.secondaryClef,
    );
    notifyListeners();
  }

  void updateOrientation(core.PageOrientation orientation) {
    _config = core.PageConfig(
      pageSize: _config.pageSize,
      orientation: orientation,
      layoutType: _config.layoutType,
      staffConfig: _config.staffConfig,
      margins: _config.margins,
      primaryClef: _config.primaryClef,
      secondaryClef: _config.secondaryClef,
    );
    notifyListeners();
  }

  void updateLayoutType(core.LayoutType type) {
    _config = core.PageConfig(
      pageSize: _config.pageSize,
      orientation: _config.orientation,
      layoutType: type,
      staffConfig: _config.staffConfig,
      margins: _config.margins,
      primaryClef: _config.primaryClef,
      secondaryClef: _config.secondaryClef,
    );
    notifyListeners();
  }

  void updateStaffConfig(core.StaffConfig staff) {
    _config = core.PageConfig(
      pageSize: _config.pageSize,
      orientation: _config.orientation,
      layoutType: _config.layoutType,
      staffConfig: staff,
      margins: _config.margins,
      primaryClef: _config.primaryClef,
      secondaryClef: _config.secondaryClef,
    );
    notifyListeners();
  }

  void updateMargins(core.Margins margins) {
    _config = core.PageConfig(
      pageSize: _config.pageSize,
      orientation: _config.orientation,
      layoutType: _config.layoutType,
      staffConfig: _config.staffConfig,
      margins: margins,
      primaryClef: _config.primaryClef,
      secondaryClef: _config.secondaryClef,
    );
    notifyListeners();
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
    updateMargins(core.Margins(
      top: mm,
      bottom: mm,
      left: _config.margins.left,
      right: _config.margins.right,
    ));
  }

  void updateHorizontalMargins(double mm) {
    updateMargins(core.Margins(
      top: _config.margins.top,
      bottom: _config.margins.bottom,
      left: mm,
      right: mm,
    ));
  }

  void resetToDefaults() {
    _config = const core.PageConfig();
    notifyListeners();
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
    _config = core.PageConfig(
      pageSize: _config.pageSize,
      orientation: _config.orientation,
      layoutType: _config.layoutType,
      staffConfig: _config.staffConfig,
      margins: _config.margins,
      primaryClef: null,
      secondaryClef: null,
    );
    notifyListeners();
  }

  void updatePrimaryClef(core.ClefConfig? clef) {
    _config = core.PageConfig(
      pageSize: _config.pageSize,
      orientation: _config.orientation,
      layoutType: _config.layoutType,
      staffConfig: _config.staffConfig,
      margins: _config.margins,
      primaryClef: clef,
      secondaryClef: _config.secondaryClef,
    );
    notifyListeners();
  }

  void updateSecondaryClef(core.ClefConfig? clef) {
    _config = core.PageConfig(
      pageSize: _config.pageSize,
      orientation: _config.orientation,
      layoutType: _config.layoutType,
      staffConfig: _config.staffConfig,
      margins: _config.margins,
      primaryClef: _config.primaryClef,
      secondaryClef: clef,
    );
    notifyListeners();
  }

  /// Apply a [StaffProfile], overriding layout type and clefs while
  /// preserving all spacing and margin settings.
  void applyProfile(core.StaffProfile profile) {
    _config = profile.applyTo(_config);
    notifyListeners();
  }
}
