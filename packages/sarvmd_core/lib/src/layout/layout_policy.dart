// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

/// Defines the directionality & layout contract mode for different UI subdomains in SarvMD.
enum LayoutPolicyMode {
  /// Standard application UI (sidebars, dialogs, property panels, headers).
  /// Labels align to start edge (Right in RTL, Left in LTR), while precision slider
  /// tracks preserve natural internal left-to-right gesture directions.
  bilingualFluid,

  /// Manuscript Canvas & Notation Previews (PreviewCanvas, RulerBox, LiveStaffPreview).
  /// Enforces strict LTR spatial coordinate system regardless of active UI locale.
  canvasStrict,

  /// Full standard RTL document flow (documentation, localized help dialogs).
  documentRtl,
}
