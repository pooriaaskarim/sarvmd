// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';

import 'sarv_brand_header.dart';

/// Reactive, interactive SarvMD branding logo widget.
///
/// Delegates directly to the canonical [SarvBrandHeader] in reactive mode.
class SarvReactiveBrandLogo extends StatelessWidget {
  const SarvReactiveBrandLogo({
    super.key,
    this.logoHeight = 26.0,
    this.isMenuMode = false,
    this.enableExpandAnimation = true,
  });

  final double logoHeight;
  final bool isMenuMode;
  final bool enableExpandAnimation;

  @override
  Widget build(BuildContext context) {
    return SarvBrandHeader(
      mode: SarvBrandHeaderMode.reactive,
      logoHeight: logoHeight,
      isMenuMode: isMenuMode,
      enableExpandAnimation: enableExpandAnimation,
      enableInteractiveAbout: !isMenuMode,
    );
  }
}

