// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';

/// State representation for application localization.
class LocaleState {
  final Locale locale;
  final bool isTransitioning;

  const LocaleState({
    this.locale = const Locale('en'),
    this.isTransitioning = false,
  });

  bool get isPersian => locale.languageCode == 'fa';

  TextDirection get textDirection =>
      isPersian ? TextDirection.rtl : TextDirection.ltr;

  String get defaultFontFamily => isPersian ? 'IranNastaliq' : 'Roboto';

  LocaleState copyWith({
    Locale? locale,
    bool? isTransitioning,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
      isTransitioning: isTransitioning ?? this.isTransitioning,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocaleState &&
          runtimeType == other.runtimeType &&
          locale == other.locale &&
          isTransitioning == other.isTransitioning;

  @override
  int get hashCode => Object.hash(locale, isTransitioning);
}
