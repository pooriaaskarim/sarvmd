// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// Deprecated UI alias for [core.LayoutPolicyMode].
@Deprecated('Use core.LayoutPolicyMode from package:sarvmd_core instead')
typedef LayoutPolicyMode = core.LayoutPolicyMode;

/// An InheritedWidget that provides explicit layout policy contracts to its subtree.
class LayoutPolicy extends InheritedWidget {
  const LayoutPolicy({
    super.key,
    required this.mode,
    required super.child,
  });

  final core.LayoutPolicyMode mode;

  /// Retrieves the nearest [LayoutPolicyMode] from the widget tree context.
  /// Defaults to [LayoutPolicyMode.bilingualFluid] if not explicitly specified.
  static core.LayoutPolicyMode of(BuildContext context) {
    final policy = context.dependOnInheritedWidgetOfExactType<LayoutPolicy>();
    return policy?.mode ?? core.LayoutPolicyMode.bilingualFluid;
  }

  /// Convenience helper to check if the current context is strictly LTR canvas territory.
  static bool isCanvasStrict(BuildContext context) {
    return of(context) == core.LayoutPolicyMode.canvasStrict;
  }

  @override
  bool updateShouldNotify(LayoutPolicy oldWidget) {
    return mode != oldWidget.mode;
  }
}

/// A convenience widget that enforces [LayoutPolicyMode.canvasStrict] and
/// locks directionality to LTR for manuscript workspace & rendering canvases.
class CanvasStrictScope extends StatelessWidget {
  const CanvasStrictScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutPolicy(
      mode: core.LayoutPolicyMode.canvasStrict,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: child,
      ),
    );
  }
}

/// A convenience widget that enforces [LayoutPolicyMode.bilingualFluid] for application UI.
class BilingualFluidScope extends StatelessWidget {
  const BilingualFluidScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isPersian = Localizations.localeOf(context).languageCode == 'fa';
    return LayoutPolicy(
      mode: core.LayoutPolicyMode.bilingualFluid,
      child: Directionality(
        textDirection: isPersian ? TextDirection.rtl : TextDirection.ltr,
        child: child,
      ),
    );
  }
}

/// Responsive breakpoints helper for SarvMD UI layouts.
abstract final class SarvBreakpoints {
  /// Returns true if the screen width is strictly less than 600px (mobile form factor).
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  /// Returns true if the screen width is between 600px and 1024px (tablet form factor).
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600 && width < 1024;
  }

  /// Returns true if the screen width is 1024px or greater (desktop form factor).
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;
}

