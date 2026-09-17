// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/widgets.dart';

Future<double?> detectPhysicalPpi() async {
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
