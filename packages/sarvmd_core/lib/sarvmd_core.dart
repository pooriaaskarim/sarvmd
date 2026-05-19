// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

/// Sarv Core — Music score notebook engine.
///
/// Provides configuration, layout computation, LaTeX emission, and PDF
/// compilation for generating blank manuscript paper.
library;

export 'src/config.dart';
export 'src/layout.dart';
export 'src/emitter.dart';
export 'src/compiler.dart';
export 'src/profiles.dart';
export 'src/svg_emitter.dart';

// Domain models
export 'src/domain/duration.dart';
export 'src/domain/pitch.dart';
export 'src/domain/clef.dart';
export 'src/domain/signature.dart';
export 'src/domain/musical_event.dart';
export 'src/domain/measure.dart';
export 'src/domain/score.dart';
