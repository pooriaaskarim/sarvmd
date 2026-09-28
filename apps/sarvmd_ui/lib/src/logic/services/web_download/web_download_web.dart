// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Web file load result carrier containing file name and text content.
class WebFileLoadResult {
  final String fileName;
  final String content;
  const WebFileLoadResult({required this.fileName, required this.content});
}

/// Modern Web implementation using package:web and JS Interop for triggering browser file downloads.
///
/// Defers URL revocation by 45 seconds to prevent browser download truncation and loss of file name.
void downloadFileWeb(String fileName, List<int> bytes, String mimeType) {
  final uint8List = Uint8List.fromList(bytes);
  final blob = web.Blob(
    [uint8List.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();

  // Safely defer revoking the blob URL so the browser download manager has ample time
  // to stream the data without truncating the file or reverting the filename to "download".
  Future<void>.delayed(const Duration(seconds: 45), () {
    web.URL.revokeObjectURL(url);
  });
}

/// Saves a document on Web.
///
/// Attempts to use the modern File System Access API (`window.showSaveFilePicker`)
/// which prompts the user for destination and suggested filename.
/// Falls back to browser download with safe deferred blob URL revocation.
Future<String?> saveFileWeb(String defaultFileName, Uint8List bytes) async {
  final windowObj = web.window as JSObject;

  if (windowObj.has('showSaveFilePicker')) {
    try {
      final options = JSObject();
      options['suggestedName'] = defaultFileName.toJS;

      final acceptObj = JSObject();
      acceptObj['application/json'] = ['.sarv'.toJS].toJS;

      final typeObj = JSObject();
      typeObj['description'] = 'SarvMD Manuscript (*.sarv)'.toJS;
      typeObj['accept'] = acceptObj;

      options['types'] = [typeObj].toJS;

      final promise = windowObj.callMethod(
        'showSaveFilePicker'.toJS,
        options,
      ) as JSPromise<JSObject>;
      final handle = await promise.toDart;

      final createWritablePromise = handle.callMethod(
        'createWritable'.toJS,
      ) as JSPromise<JSObject>;
      final writable = await createWritablePromise.toDart;

      final writePromise = writable.callMethod(
        'write'.toJS,
        bytes.toJS,
      ) as JSPromise<JSAny?>;
      await writePromise.toDart;

      final closePromise = writable.callMethod(
        'close'.toJS,
      ) as JSPromise<JSAny?>;
      await closePromise.toDart;

      final chosenName = (handle['name'] as JSString).toDart;
      return chosenName;
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('AbortError') || errorStr.contains('aborted')) {
        // User intentionally cancelled the Save As file dialog
        return null;
      }
      // If File System Access API failed unexpectedly, fall back to standard download
    }
  }

  // Fallback: trigger standard browser download with deferred cleanup
  downloadFileWeb(defaultFileName, bytes, 'application/json;charset=utf-8');
  return defaultFileName;
}

/// Prompts the user to pick a `.sarv` file on Web and reads its text content.
///
/// Uses the File System Access API (`window.showOpenFilePicker`) if available,
/// or falls back to an HTML file input element with `FileReader.readAsText`.
Future<WebFileLoadResult?> openFileWeb() async {
  final windowObj = web.window as JSObject;

  if (windowObj.has('showOpenFilePicker')) {
    try {
      final options = JSObject();
      final acceptObj = JSObject();
      acceptObj['application/json'] = ['.sarv'.toJS].toJS;

      final typeObj = JSObject();
      typeObj['description'] = 'SarvMD Manuscript (*.sarv)'.toJS;
      typeObj['accept'] = acceptObj;

      options['types'] = [typeObj].toJS;
      options['multiple'] = false.toJS;

      final promise = windowObj.callMethod(
        'showOpenFilePicker'.toJS,
        options,
      ) as JSPromise<JSArray<JSObject>>;
      final handles = await promise.toDart;
      final handleList = handles.toDart;
      if (handleList.isEmpty) return null;

      final handle = handleList.first;
      final filePromise = handle.callMethod(
        'getFile'.toJS,
      ) as JSPromise<web.File>;
      final file = await filePromise.toDart;

      final reader = web.FileReader();
      final completer = Completer<String?>();

      reader.onLoadEnd.listen((e) {
        final result = reader.result;
        if (result != null) {
          completer.complete((result as JSString).toDart);
        } else {
          completer.complete(null);
        }
      });

      reader.readAsText(file);
      final text = await completer.future;
      if (text == null) return null;

      return WebFileLoadResult(fileName: file.name, content: text);
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('AbortError') || errorStr.contains('aborted')) {
        // User cancelled picker
        return null;
      }
      // If File System Access API failed, fall through to HTML input fallback
    }
  }

  // Fallback: HTMLInputElement
  final completer = Completer<WebFileLoadResult?>();
  final uploadInput = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.sarv,application/json'
    ..multiple = false
    ..style.display = 'none';

  bool completed = false;

  void finish(WebFileLoadResult? result) {
    if (completed) return;
    completed = true;
    uploadInput.remove();
    completer.complete(result);
  }

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files == null || files.length == 0) {
      finish(null);
      return;
    }
    final file = files.item(0);
    if (file == null) {
      finish(null);
      return;
    }

    final reader = web.FileReader();
    reader.onLoadEnd.listen((e) {
      final result = reader.result;
      if (result != null) {
        final text = (result as JSString).toDart;
        finish(WebFileLoadResult(fileName: file.name, content: text));
      } else {
        finish(null);
      }
    });
    reader.readAsText(file);
  });

  // Listen to window focus for cancellation
  void focusListener(web.Event e) {
    web.window.removeEventListener('focus', focusListener.toJS);
    Future.delayed(const Duration(seconds: 1), () {
      if (!completed && (uploadInput.files == null || uploadInput.files!.length == 0)) {
        finish(null);
      }
    });
  }

  web.window.addEventListener('focus', focusListener.toJS);
  web.document.body?.appendChild(uploadInput);
  uploadInput.click();

  return await completer.future;
}

web.EventListener? _beforeUnloadListener;

/// Registers or unregisters a browser navigation/close guard (`beforeunload`).
///
/// When [shouldGuard] is true, the browser prompts the user before closing or
/// reloading the page to prevent losing unsaved manuscript changes.
void setWebUnsavedChangesGuard(bool shouldGuard) {
  if (shouldGuard) {
    if (_beforeUnloadListener != null) return;
    _beforeUnloadListener = ((web.Event event) {
      event.preventDefault();
      try {
        (event as JSObject)['returnValue'] = ''.toJS;
      } catch (_) {}
    }).toJS;
    web.window.addEventListener('beforeunload', _beforeUnloadListener);
  } else {
    if (_beforeUnloadListener != null) {
      web.window.removeEventListener('beforeunload', _beforeUnloadListener);
      _beforeUnloadListener = null;
    }
  }
}

