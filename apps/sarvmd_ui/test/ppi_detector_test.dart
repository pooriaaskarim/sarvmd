// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/core/utils/ppi_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Physical PPI Auto-Detection Tests', () {
    testWidgets('detectPhysicalPpi returns physical PPI estimate or fallback', (tester) async {
      final ppi = await detectPhysicalPpi();
      expect(ppi, isNotNull);
      expect(ppi! > 0, isTrue);
    });
  });
}
