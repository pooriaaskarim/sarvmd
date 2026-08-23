// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';

/// State representation for application localization.
class LocaleState {
  final Locale locale;

  const LocaleState({
    this.locale = const Locale('fa'),
  });

  bool get isPersian => locale.languageCode == 'fa';

  TextDirection get textDirection =>
      isPersian ? TextDirection.rtl : TextDirection.ltr;

  String get defaultFontFamily => isPersian ? 'IranNastaliq' : 'Roboto';

  LocaleState copyWith({Locale? locale}) {
    return LocaleState(
      locale: locale ?? this.locale,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocaleState &&
          runtimeType == other.runtimeType &&
          locale == other.locale;

  @override
  int get hashCode => locale.hashCode;
}
