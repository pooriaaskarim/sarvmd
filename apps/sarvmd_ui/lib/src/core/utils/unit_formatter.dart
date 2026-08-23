// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

/// A centralized, locale-aware formatting utility for physical measurements and technical metrics in SarvMD.
///
/// Per SarvMD design specification, technical metrics (millimeter dimensions, point spacing, percentages)
/// strictly preserve standard English/ASCII digits (`0-9`) across all application locales for professional clarity.
abstract class UnitFormatter {
  /// Formats millimeter dimensions (e.g., `210.0 mm`).
  static String formatMm(double mm, {int decimals = 1, bool includeUnit = true}) {
    final formatted = mm.toStringAsFixed(decimals);
    return includeUnit ? '$formatted mm' : formatted;
  }

  /// Formats point measurements (e.g., `7.0 pt`).
  static String formatPt(double pt, {int decimals = 1, bool includeUnit = true}) {
    final formatted = pt.toStringAsFixed(decimals);
    return includeUnit ? '$formatted pt' : formatted;
  }

  /// Formats percentage scale (e.g., `100%`).
  static String formatPercent(double scale, {bool includeSymbol = true}) {
    final percent = (scale * 100).round();
    return includeSymbol ? '$percent%' : '$percent';
  }

  /// Formats paper dimension pair (e.g., `210.0 × 297.0 mm`).
  static String formatDimensions(double width, double height, {int decimals = 1}) {
    return '${width.toStringAsFixed(decimals)} × ${height.toStringAsFixed(decimals)} mm';
  }

  /// Formats pixel resolutions with optional DPI (e.g., `1920 × 1080 px` or `1920 × 1080 px (300 DPI)`).
  static String formatResolution(int width, int height, {int? dpi}) {
    final base = '$width × $height px';
    return dpi != null ? '$base ($dpi DPI)' : base;
  }

  /// Formats display density readouts (e.g., `96 PPI`).
  static String formatPpi(int ppi) {
    return '$ppi PPI';
  }
}
