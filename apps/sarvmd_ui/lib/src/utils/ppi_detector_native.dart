import 'dart:io';

Future<double?> detectPhysicalPpi() async {
  try {
    if (Platform.isLinux) {
      return _getPpiLinux();
    } else if (Platform.isMacOS) {
      return _getPpiMacOS();
    } else if (Platform.isWindows) {
      return _getPpiWindows();
    }
  } catch (e) {
    // Fail silently
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
