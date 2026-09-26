// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/view/view_cubit.dart';
import '../../logic/view/view_state.dart';

/// Categorizes the device or window dimensions into standardized form factors.
enum SarvFormFactor {
  /// Handheld mobile phones and very narrow split-screen viewports (< 600px width).
  phone,

  /// Tablets and medium window viewports (600px - 1023px width).
  tablet,

  /// Desktop monitors and wide viewports (>= 1024px width).
  desktop,
}

/// Immutable data describing the current display environment, input intent, and form factor.
@immutable
class SarvDisplayData {
  const SarvDisplayData({
    required this.inputMode,
    required this.formFactor,
    required this.orientation,
    required this.size,
  });

  /// The active user interaction modality (pointer vs. touch).
  final InputMode inputMode;

  /// The viewport size classification (phone, tablet, or desktop).
  final SarvFormFactor formFactor;

  /// Portrait or landscape orientation.
  final Orientation orientation;

  /// The physical or logical screen size.
  final Size size;

  /// Whether the current device viewport corresponds to a phone (< 600px width).
  bool get isPhone => formFactor == SarvFormFactor.phone;

  /// Whether the current device viewport corresponds to a tablet (600 - 1023px width).
  bool get isTablet => formFactor == SarvFormFactor.tablet;

  /// Whether the current device viewport corresponds to a desktop (>= 1024px width).
  bool get isDesktop => formFactor == SarvFormFactor.desktop;

  /// Whether the user has active touch input modality.
  bool get isTouch => inputMode == InputMode.touch;

  /// Whether the user has active pointer/mouse input modality.
  bool get isPointer => inputMode == InputMode.pointer;

  /// Whether the viewport is in landscape orientation.
  bool get isLandscape => orientation == Orientation.landscape;

  /// Whether the viewport is in portrait orientation.
  bool get isPortrait => orientation == Orientation.portrait;

  /// Recommends presenting full-content modals as bottom sheets on phones or small heights (< 600px).
  bool get preferBottomSheet => isPhone || size.height < 600;

  /// Returns true if the screen width is narrower than 600px.
  bool get isCompactWidth => size.width < 600;

  /// Returns true if the dialog tab bar is in narrow mode (< 500px).
  bool get isNarrowTab => size.width < 500;

  /// Derives display data from the given [BuildContext].
  ///
  /// Can optionally override [inputMode] if already known.
  factory SarvDisplayData.fromContext(BuildContext context, {InputMode? inputMode}) {
    final media = MediaQuery.maybeOf(context);
    final size = media?.size ?? Size.zero;
    final orientation = media?.orientation ??
        (size.width >= size.height ? Orientation.landscape : Orientation.portrait);

    InputMode resolvedMode = inputMode ?? InputMode.pointer;
    if (inputMode == null) {
      try {
        resolvedMode = BlocProvider.of<ViewCubit>(context, listen: false).state.inputMode;
      } catch (_) {
        // Fall back to pointer mode when ViewCubit is absent in isolated tests
      }
    }

    final formFactor = size.width < 600
        ? SarvFormFactor.phone
        : (size.width < 1024 ? SarvFormFactor.tablet : SarvFormFactor.desktop);

    return SarvDisplayData(
      inputMode: resolvedMode,
      formFactor: formFactor,
      orientation: orientation,
      size: size,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SarvDisplayData &&
          runtimeType == other.runtimeType &&
          inputMode == other.inputMode &&
          formFactor == other.formFactor &&
          orientation == other.orientation &&
          size == other.size;

  @override
  int get hashCode => Object.hash(inputMode, formFactor, orientation, size);
}

/// An [InheritedWidget] providing [SarvDisplayData] down the widget tree.
class SarvDisplayContext extends InheritedWidget {
  const SarvDisplayContext({
    super.key,
    required this.data,
    required super.child,
  });

  final SarvDisplayData data;

  /// Retrieves [SarvDisplayData] from the nearest [SarvDisplayContext], or falls
  /// back to calculating it dynamically from [BuildContext].
  static SarvDisplayData of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<SarvDisplayContext>();
    if (inherited != null) return inherited.data;
    return SarvDisplayData.fromContext(context);
  }

  /// Retrieves [SarvDisplayData] from the nearest [SarvDisplayContext] if present.
  static SarvDisplayData? maybeOf(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<SarvDisplayContext>();
    return inherited?.data;
  }

  @override
  bool updateShouldNotify(SarvDisplayContext oldWidget) {
    return data != oldWidget.data;
  }
}

/// A convenience widget that listens to [MediaQuery] and exposes [SarvDisplayContext].
class SarvDisplayScope extends StatelessWidget {
  const SarvDisplayScope({
    super.key,
    required this.child,
    this.inputModeOverride,
  });

  final Widget child;
  final InputMode? inputModeOverride;

  @override
  Widget build(BuildContext context) {
    final data = SarvDisplayData.fromContext(context, inputMode: inputModeOverride);
    return SarvDisplayContext(
      data: data,
      child: child,
    );
  }
}

/// Context extension for quick access to display data.
extension SarvDisplayContextExtension on BuildContext {
  SarvDisplayData get sarvDisplay => SarvDisplayContext.of(this);
}
