import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

enum GuideType {
  paperEdges,
  paperCenters,
  margins,
  staffBounds,
  rulerWings,
}

class ViewNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  SarvAccent _accent = SarvAccent.sky;
  SarvAccent get accent => _accent;

  void updateThemeMode(ThemeMode mode) {
    _themeMode = mode;
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
    notifyListeners();
  }

  void updateAccent(SarvAccent accent) {
    _accent = accent;
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
