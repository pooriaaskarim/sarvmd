import 'dart:io' if (dart.library.js_interop) 'dart:html';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';

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

  SharedPreferences? _prefs;

  /// Load persisted settings from disk/local storage.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

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
      // If no manual calibration exists, try to detect physical PPI from the OS.
      final detectedPpi = await _detectPhysicalPpi();
      if (detectedPpi != null) {
        _calibrationFactor = (detectedPpi / 96.0).clamp(0.5, 4.0);
      }
    }

    notifyListeners();
  }

  /// Coordinates physical PPI detection across different platforms using shell utilities.
  Future<double?> _detectPhysicalPpi() async {
    if (kIsWeb) return null;

    try {
      if (Platform.isLinux) {
        return _getPpiLinux();
      } else if (Platform.isMacOS) {
        return _getPpiMacOS();
      } else if (Platform.isWindows) {
        return _getPpiWindows();
      }
    } catch (e) {
      debugPrint('Smart PPI detection failed: $e');
    }

    return null;
  }

  /// Detects PPI on Linux by parsing xrandr output.
  Future<double?> _getPpiLinux() async {
    final result = await Process.run('xrandr', ['--current']);
    if (result.exitCode != 0) return null;

    final output = result.stdout as String;
    // Regex matches "1920x1080+0+0 ... 344mm x 194mm"
    final match = RegExp(r'(\d+)x(\d+)\+\d+\+\d+.* (\d+)mm x (\d+)mm')
        .firstMatch(output);

    if (match != null) {
      final pxW = double.parse(match.group(1)!);
      final mmW = double.parse(match.group(3)!);
      if (mmW > 0) return (pxW / mmW) * 25.4;
    }
    return null;
  }

  /// Detects PPI on macOS using system_profiler.
  Future<double?> _getPpiMacOS() async {
    final result = await Process.run('system_profiler', ['SPDisplaysDataType']);
    if (result.exitCode != 0) return null;

    final output = result.stdout as String;
    // Look for Resolution and physical dimensions if available
    // Note: SPDisplaysDataType often provides "Resolution" and "Display Type: Retina"
    if (output.contains('Retina')) return 227.0; // Standard MacBook Retina density
    
    return null; // Fallback to manual
  }

  /// Detects PPI on Windows using PowerShell WMI query.
  Future<double?> _getPpiWindows() async {
    final result = await Process.run('powershell', [
      '-Command',
      'Get-CimInstance -Namespace root\\wmi -ClassName WmiMonitorBasicDisplayParams | Select-Object -Property MaxHorizontalImageSize'
    ]);
    if (result.exitCode != 0) return null;

    final output = result.stdout as String;
    // MaxHorizontalImageSize is in centimeters
    final match = RegExp(r'(\d+)').firstMatch(output);
    if (match != null) {
      final cmW = double.parse(match.group(1)!);
      if (cmW > 0) {
        // We need resolution too. Since we don't have context here, 
        // we'll use a standard guess or rely on future improvements.
        // For now, assume a standard 1080p if we found physical size.
        return (1920 / (cmW * 10)) * 25.4;
      }
    }
    return null;
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

