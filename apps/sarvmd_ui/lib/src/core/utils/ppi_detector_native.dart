// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:io';
import 'package:flutter/widgets.dart';

Future<double?> detectPhysicalPpi() async {
  try {
    if (Platform.isAndroid) {
      return _getPpiMobile();
    } else if (Platform.isIOS) {
      return _getPpiMobile();
    } else if (Platform.isLinux) {
      final ppi = await _getPpiLinux();
      return ppi ?? _getPpiFlutterView();
    } else if (Platform.isMacOS) {
      final ppi = await _getPpiMacOS();
      return ppi ?? _getPpiFlutterView();
    } else if (Platform.isWindows) {
      final ppi = await _getPpiWindows();
      return ppi ?? _getPpiFlutterView();
    }
  } catch (e) {
    // Fail silently
  }
  return _getPpiFlutterView();
}

double? _getPpiMobile() {
  final view = WidgetsBinding.instance.platformDispatcher.implicitView ??
      (WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
          ? WidgetsBinding.instance.platformDispatcher.views.first
          : null);
  if (view != null) {
    final dpr = view.devicePixelRatio;
    if (dpr > 0) {
      return dpr * 160.0;
    }
  }
  return 160.0;
}

double? _getPpiFlutterView() {
  final view = WidgetsBinding.instance.platformDispatcher.implicitView ??
      (WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
          ? WidgetsBinding.instance.platformDispatcher.views.first
          : null);
  if (view != null) {
    final dpr = view.devicePixelRatio;
    if (dpr > 0) {
      final baseDpi = dpr >= 2.0 ? 160.0 : 96.0;
      return dpr * baseDpi;
    }
  }
  return null;
}

Future<double?> _getPpiLinux() async {
  final result = await Process.run('xrandr', ['--current']);
  if (result.exitCode != 0) return null;
  final output = result.stdout as String;
  final match =
      RegExp(r'(\d+)x(\d+)\+\d+\+\d+.* (\d+)mm x (\d+)mm').firstMatch(output);
  if (match != null) {
    final pxW = double.parse(match.group(1)!);
    final mmW = double.parse(match.group(3)!);
    if (mmW > 0) return (pxW / mmW) * 25.4;
  }
  return null;
}

Future<double?> _getPpiMacOS() async {
  final result = await Process.run('system_profiler', ['SPDisplaysDataType']);
  if (result.exitCode != 0) return null;
  final output = result.stdout as String;
  if (output.contains('Retina')) return 227.0;
  return null;
}

Future<double?> _getPpiWindows() async {
  final result = await Process.run('powershell', [
    '-Command',
    'Get-CimInstance -Namespace root\\wmi -ClassName WmiMonitorBasicDisplayParams | Select-Object -Property MaxHorizontalImageSize'
  ]);
  if (result.exitCode != 0) return null;
  final output = result.stdout as String;
  final match = RegExp(r'(\d+)').firstMatch(output);
  if (match != null) {
    final cmW = double.parse(match.group(1)!);
    if (cmW > 0) return (1920 / (cmW * 10)) * 25.4;
  }
  return null;
}
