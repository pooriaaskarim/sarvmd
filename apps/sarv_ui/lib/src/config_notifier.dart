import 'package:flutter/material.dart';
import 'package:sarv_core/sarv_core.dart' as core;

class ConfigNotifier extends ChangeNotifier {
  core.PageConfig _config = const core.PageConfig();

  core.PageConfig get config => _config;

  core.PageLayout get layout => core.computeLayout(_config);

  void updatePageSize(core.PageSize size) {
    _config = core.PageConfig(
      pageSize: size,
      layoutType: _config.layoutType,
      staffConfig: _config.staffConfig,
      margins: _config.margins,
    );
    notifyListeners();
  }

  void updateLayoutType(core.LayoutType type) {
    _config = core.PageConfig(
      pageSize: _config.pageSize,
      layoutType: type,
      staffConfig: _config.staffConfig,
      margins: _config.margins,
    );
    notifyListeners();
  }

  void updateStaffConfig(core.StaffConfig staff) {
    _config = core.PageConfig(
      pageSize: _config.pageSize,
      layoutType: _config.layoutType,
      staffConfig: staff,
      margins: _config.margins,
    );
    notifyListeners();
  }

  void updateMargins(core.Margins margins) {
    _config = core.PageConfig(
      pageSize: _config.pageSize,
      layoutType: _config.layoutType,
      staffConfig: _config.staffConfig,
      margins: margins,
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
}
