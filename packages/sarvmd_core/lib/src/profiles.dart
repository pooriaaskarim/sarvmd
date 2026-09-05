/// Pre-configured staff profiles for common manuscript layouts.
///
/// A [StaffProfile] bundles a [LayoutType] with a predefined [ClefConfig] pair,
/// providing fast, one-tap configuration for the most common musical setups.

import 'config.dart';
import 'domain/clef.dart';

/// Categories for grouping staff profiles in the UI.
enum ProfileCategory { standard, ensemble, tablature, percussion, blank }

/// An immutable, named preset that bundles a system layout configuration.
class StaffProfile {
  const StaffProfile({
    required this.id,
    required this.label,
    required this.systemLayout,
    this.description,
    this.category = ProfileCategory.standard,
    this.uiHints = const StaffUIHints(),
  });

  /// Unique identifier for this profile.
  final String id;

  /// Human-readable name shown in the UI.
  final String label;

  /// The system layout this profile generates.
  final SystemLayout systemLayout;

  /// Short description of this profile's intended use.
  final String? description;

  /// The category this profile belongs to.
  final ProfileCategory category;

  /// Metadata for the UI to adapt its controls and labels.
  final StaffUIHints uiHints;

  /// Apply this profile to an existing [PageConfig], preserving all spacing
  /// and margin settings while overriding the layout.
  PageConfig applyTo(PageConfig config) => config.copyWith(
        systemLayout: systemLayout,
      );
}

/// Built-in staff profiles for common manuscript layouts.
abstract final class StaffProfiles {
  /// Piano / keyboard grand staff (treble + bass).
  static const piano = StaffProfile(
    id: 'piano',
    label: 'Piano',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        connector: SystemConnector.brace,
        children: [
          StaffDefinition(lines: 5, clef: Clef.treble),
          StaffDefinition(lines: 5, clef: Clef.bass),
        ],
      ),
    ),
    description: 'Grand staff for piano or keyboard.',
  );

  /// Standard treble clef (violin, flute, soprano, etc.).
  static const treble = StaffProfile(
    id: 'treble',
    label: 'Treble',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        children: [
          StaffDefinition(lines: 5, clef: Clef.treble),
        ],
      ),
    ),
    description: 'Standard G clef — violin, flute, soprano.',
  );

  /// Standard bass clef (cello, bass guitar, tuba, etc.).
  static const bass = StaffProfile(
    id: 'bass',
    label: 'Bass',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        children: [
          StaffDefinition(lines: 5, clef: Clef.bass),
        ],
      ),
    ),
    description: 'Standard F clef — cello, bass guitar, tuba.',
  );

  /// Alto clef (viola).
  static const alto = StaffProfile(
    id: 'alto',
    label: 'Alto',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        children: [
          StaffDefinition(lines: 5, clef: Clef.alto),
        ],
      ),
    ),
    description: 'C clef on middle line — viola.',
  );

  /// 6-line Guitar Tablature
  static const guitarTab = StaffProfile(
    id: 'guitarTab',
    label: 'Guitar TAB',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        children: [
          StaffDefinition(lines: 6, clef: Clef.tab),
        ],
      ),
    ),
    description: '6-line tablature for guitar.',
    category: ProfileCategory.tablature,
    uiHints: StaffUIHints(
      lineGapLabel: 'String Spacing',
    ),
  );

  /// Standard Treble paired with 6-line Tablature
  static const guitarGrand = StaffProfile(
    id: 'guitarGrand',
    label: 'Guitar + TAB',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        connector: SystemConnector.bracket,
        children: [
          StaffDefinition(lines: 5, clef: Clef.treble),
          StaffDefinition(lines: 6, clef: Clef.tab),
        ],
      ),
    ),
    description: 'Standard treble staff paired with 6-line tablature.',
    category: ProfileCategory.tablature,
    uiHints: StaffUIHints(
      interStaffGapLabel: 'Tab Distance',
    ),
  );

  /// 4-line Bass or Ukulele Tablature
  static const bassTab = StaffProfile(
    id: 'bassTab',
    label: 'Bass TAB',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        children: [
          StaffDefinition(lines: 4, clef: Clef.tab),
        ],
      ),
    ),
    description: '4-line tablature for bass guitar or ukulele.',
    category: ProfileCategory.tablature,
    uiHints: StaffUIHints(
      lineGapLabel: 'String Spacing',
    ),
  );

  /// 5-line Banjo Tablature
  static const banjoTab = StaffProfile(
    id: 'banjoTab',
    label: 'Banjo TAB',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        children: [
          StaffDefinition(lines: 5, clef: Clef.tab),
        ],
      ),
    ),
    description: '5-line tablature for 5-string banjo.',
    category: ProfileCategory.tablature,
    uiHints: StaffUIHints(
      lineGapLabel: 'String Spacing',
    ),
  );

  /// 5-line Drum Set notation
  static const drumSet = StaffProfile(
    id: 'drumSet',
    label: 'Drum Set',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        children: [
          StaffDefinition(lines: 5, clef: Clef.percussion),
        ],
      ),
    ),
    description: 'Standard 5-line notation for full drum kits.',
    category: ProfileCategory.percussion,
  );

  /// 1-line Percussion Staff
  static const percussion1 = StaffProfile(
    id: 'percussion1',
    label: 'Percussion (1-line)',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        children: [
          StaffDefinition(lines: 1, clef: Clef.percussion),
        ],
      ),
    ),
    description: 'Single line for unpitched percussion.',
    category: ProfileCategory.percussion,
  );

  /// 3-line Percussion Staff
  static const percussion3 = StaffProfile(
    id: 'percussion3',
    label: 'Percussion (3-line)',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        children: [
          StaffDefinition(lines: 3, clef: Clef.percussion),
        ],
      ),
    ),
    description: '3-line staff for multiple unpitched percussion instruments.',
    category: ProfileCategory.percussion,
  );

  /// String Quartet (2 Violins, Viola, Cello).
  static const stringQuartet = StaffProfile(
    id: 'stringQuartet',
    label: 'String Quartet',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        connector: SystemConnector.bracket,
        children: [
          StaffDefinition(lines: 5, clef: Clef.treble),
          StaffDefinition(lines: 5, clef: Clef.treble),
          StaffDefinition(lines: 5, clef: Clef.alto),
          StaffDefinition(lines: 5, clef: Clef.bass),
        ],
      ),
    ),
    description: 'Full score for 2 Violins, Viola, and Cello.',
    category: ProfileCategory.ensemble,
  );

  /// Blank staff with no clef.
  static const blank = StaffProfile(
    id: 'blank',
    label: 'Blank',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        children: [
          StaffDefinition(lines: 5),
        ],
      ),
    ),
    description: 'Anonymous 5-line staff, no clef.',
    category: ProfileCategory.blank,
  );

  /// All built-in profiles in display order.
  static const all = [
    piano,
    treble,
    bass,
    alto,
    guitarTab,
    bassTab,
    banjoTab,
    guitarGrand,
    stringQuartet,
    drumSet,
    percussion1,
    percussion3,
    blank
  ];
}

/// Metadata used by the UI to adapt its labels and control visibility
/// based on the active [StaffProfile].
class StaffUIHints {
  const StaffUIHints({
    this.lineGapLabel = 'Staff Size',
    this.systemGapLabel = 'System Gap',
    this.interStaffGapLabel = 'Inter-staff Gap',
  });

  /// The label for the primary line-gap (stave size) control.
  final String lineGapLabel;

  /// The label for the gap between systems.
  final String systemGapLabel;

  /// The label for the gap between staves in a multi-staff system.
  final String interStaffGapLabel;
}
