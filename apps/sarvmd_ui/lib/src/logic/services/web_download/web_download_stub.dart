import 'dart:typed_data';

/// Native stub for web file download operations.
void downloadFileWeb(String fileName, List<int> bytes, String mimeType) {
  // No-op on native platforms.
}

/// Web file load result carrier.
class WebFileLoadResult {
  final String fileName;
  final String content;
  const WebFileLoadResult({required this.fileName, required this.content});
}

/// Native stub for web file saving.
Future<String?> saveFileWeb(String defaultFileName, Uint8List bytes) async {
  return null;
}

/// Native stub for web file opening.
Future<WebFileLoadResult?> openFileWeb() async {
  return null;
}

/// Native stub for registering/unregistering browser navigation/close guard (`beforeunload`).
void setWebUnsavedChangesGuard(bool shouldGuard) {
  // No-op on native platforms.
}
