import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'utils/ppi_detector.dart';

enum GuideType {
  paperEdges,
  paperCenters,
  margins,
  staffBounds,
  rulerWings,
}

class ViewNotifier extends ChangeNotifier {
  static const String _keyThemeMode = 'view_theme_mode';
  static const String _keyAccent = 'view_accent';
  static const String _keyCalibration = 'view_calibration_factor';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  SarvAccent _accent = SarvAccent.sky;
  SarvAccent get accent => _accent;

  /// Physical display calibration factor.
  ///
  /// A value of 1.0 means the canvas renders at exactly 96 logical DPI.
  /// The user calibrates this by adjusting an on-screen reference ruler
  /// until it matches a physical ruler held to the screen.
  ///
  /// The "Actual Size" zoom preset sets zoom = calibrationFactor, so that
  /// 1 mm of manuscript paper occupies exactly 1 mm on the physical display.
  double _calibrationFactor = 1.0;
  double get calibrationFactor => _calibrationFactor;

  ViewNotifier([this._prefs]);

  /// Synchronously load persisted settings from the pre-initialized SharedPreferences instance.
  void initializeSync() {
    if (_prefs == null) return;

    // Load Theme Mode
    final themeIndex = _prefs?.getInt(_keyThemeMode);
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    // Load Accent
    final accentIndex = _prefs?.getInt(_keyAccent);
    if (accentIndex != null) {
      _accent = SarvAccent.values[accentIndex];
    }

    // Load Calibration
    final savedFactor = _prefs?.getDouble(_keyCalibration);
    if (savedFactor != null) {
      _calibrationFactor = savedFactor;
    } else {
      // Run physical PPI detection in the background so it does not block the UI startup
      _detectPpiBackground();
    }
  }

  Future<void> _detectPpiBackground() async {
    final detectedPpi = await detectPhysicalPpi();
    if (detectedPpi != null) {
      _calibrationFactor = (detectedPpi / 96.0).clamp(0.5, 4.0);
      notifyListeners();
    }
  }

  SharedPreferences? _prefs;

  /// Load persisted settings from disk/local storage.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    initializeSync();
    notifyListeners();
  }

  void updateCalibrationFactor(double factor) {
    _calibrationFactor = factor.clamp(0.3, 5.0);
    _prefs?.setDouble(_keyCalibration, _calibrationFactor);
    notifyListeners();
  }

  void resetCalibration() {
    _calibrationFactor = 1.0;
    _prefs?.remove(_keyCalibration);
    notifyListeners();
  }

  void updateThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs?.setInt(_keyThemeMode, mode.index);
    notifyListeners();
  }

  void toggleThemeMode() {
    if (_themeMode == ThemeMode.system) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    _prefs?.setInt(_keyThemeMode, _themeMode.index);
    notifyListeners();
  }

  void updateAccent(SarvAccent accent) {
    _accent = accent;
    _prefs?.setInt(_keyAccent, accent.index);
    notifyListeners();
  }

  final Set<GuideType> _activeGuides = {
    GuideType.paperEdges,
    GuideType.rulerWings
  };
  Set<GuideType> get activeGuides => _activeGuides;

  void toggleGuide(GuideType guide, bool active) {
    if (active) {
      _activeGuides.add(guide);
    } else {
      _activeGuides.remove(guide);
    }
    notifyListeners();
  }

  bool isGuideActive(GuideType guide) => _activeGuides.contains(guide);
}
