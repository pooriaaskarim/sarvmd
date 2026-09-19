// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';

import 'sarv_brand_header.dart';

/// The primary branding header for SarvMD, featuring the handwriting logo
/// and the 'MANUSCRIPT DESIGNER' subtitle with Hero shared-element transition support.
class SarvHeader extends StatelessWidget {
  const SarvHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SarvBrandHeader(
      mode: SarvBrandHeaderMode.full,
      enableInteractiveAbout: true,
      showInfoIcon: true,
    );
  }
}

