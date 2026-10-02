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
  /// and margin settings while overriding the layout with uniquely stamped UIDs.
  PageConfig applyTo(PageConfig config) {
    int counter = 0;
    final stampedRoot = systemLayout.rootGroup.assignUids(
      counter: () => counter++,
    );
    return config.copyWith(
      systemLayout: systemLayout.copyWith(rootGroup: stampedRoot),
    );
  }

  /// Returns whether this profile structurally matches [config]'s system layout.
  bool matches(PageConfig config) =>
      systemLayout.matchesStructure(config.systemLayout);

  /// Returns whether this profile structurally matches [layout].
  bool matchesLayout(SystemLayout layout) =>
      systemLayout.matchesStructure(layout);
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
        label: 'Piano',
        abbreviation: 'Pno.',
        labelVisible: false,
        descriptorPlacement: DescriptorPlacement.outsideConnector,
        children: [
          StaffDefinition(
            lines: 5,
            clef: Clef.treble,
            instrumentName: 'Treble',
            instrumentAbbreviation: 'Tr.',
            labelVisible: false,
          ),
          StaffDefinition(
            lines: 5,
            clef: Clef.bass,
            instrumentName: 'Bass',
            instrumentAbbreviation: 'B.',
            labelVisible: false,
          ),
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
        initialBarline: false,
        children: [
          StaffDefinition(
            lines: 5,
            clef: Clef.treble,
            instrumentName: 'Treble',
            instrumentAbbreviation: 'Tr.',
            labelVisible: false,
          ),
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
        initialBarline: false,
        children: [
          StaffDefinition(
            lines: 5,
            clef: Clef.bass,
            instrumentName: 'Bass',
            instrumentAbbreviation: 'B.',
            labelVisible: false,
          ),
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
        initialBarline: false,
        children: [
          StaffDefinition(
            lines: 5,
            clef: Clef.alto,
            instrumentName: 'Viola',
            instrumentAbbreviation: 'Vla.',
            labelVisible: false,
          ),
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
          StaffDefinition(
            lines: 6,
            clef: Clef.tab,
            instrumentName: 'Guitar TAB',
            instrumentAbbreviation: 'TAB',
            labelVisible: false,
          ),
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
        label: 'Guitar',
        abbreviation: 'Gtr.',
        labelVisible: false,
        children: [
          StaffDefinition(
            lines: 5,
            clef: Clef.treble,
            instrumentName: 'Guitar',
            instrumentAbbreviation: 'Gtr.',
            labelVisible: false,
          ),
          StaffDefinition(
            lines: 6,
            clef: Clef.tab,
            instrumentName: 'TAB',
            instrumentAbbreviation: 'TAB',
            labelVisible: false,
          ),
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
          StaffDefinition(
            lines: 4,
            clef: Clef.tab,
            instrumentName: 'Bass TAB',
            instrumentAbbreviation: 'TAB',
            labelVisible: false,
          ),
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
          StaffDefinition(
            lines: 5,
            clef: Clef.tab,
            instrumentName: 'Banjo TAB',
            instrumentAbbreviation: 'TAB',
            labelVisible: false,
          ),
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
        initialBarline: false,
        children: [
          StaffDefinition(
            lines: 5,
            clef: Clef.percussion,
            instrumentName: 'Drum Set',
            instrumentAbbreviation: 'D.S.',
            labelVisible: false,
          ),
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
        initialBarline: false,
        children: [
          StaffDefinition(
            lines: 1,
            clef: Clef.percussion,
            instrumentName: 'Percussion',
            instrumentAbbreviation: 'Perc.',
            labelVisible: false,
          ),
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
        initialBarline: false,
        children: [
          StaffDefinition(
            lines: 3,
            clef: Clef.percussion,
            instrumentName: 'Percussion',
            instrumentAbbreviation: 'Perc.',
            labelVisible: false,
          ),
        ],
      ),
    ),
    description: '3-line staff for multiple unpitched percussion instruments.',
    category: ProfileCategory.percussion,
  );

  /// String Quartet (2 Violins, Viola, Violoncello).
  ///
  /// Standard Gould / Gardner Read notation for classical string quartet.
  static const stringQuartet = StaffProfile(
    id: 'stringQuartet',
    label: 'String Quartet',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'String Quartet',
        abbreviation: 'Str. Qt.',
        labelVisible: false,
        children: [
          StaffDefinition(
            lines: 5,
            clef: Clef.treble,
            instrumentName: 'Violin I',
            instrumentAbbreviation: 'Vln. I',
            labelVisible: true,
          ),
          StaffDefinition(
            lines: 5,
            clef: Clef.treble,
            instrumentName: 'Violin II',
            instrumentAbbreviation: 'Vln. II',
            labelVisible: true,
          ),
          StaffDefinition(
            lines: 5,
            clef: Clef.alto,
            instrumentName: 'Viola',
            instrumentAbbreviation: 'Vla.',
            labelVisible: true,
          ),
          StaffDefinition(
            lines: 5,
            clef: Clef.bass,
            instrumentName: 'Violoncello',
            instrumentAbbreviation: 'Vc.',
            labelVisible: true,
          ),
        ],
      ),
    ),
    description:
        'Full score for 2 Violins, Viola, and Violoncello (Gould standard).',
    category: ProfileCategory.ensemble,
  );

  /// String Orchestra: 5-part string section with violin pair sub-bracket.
  ///
  /// Demonstrates nested grouping — a primary [SystemConnector.bracket] wraps
  /// all strings, while a [SystemConnector.subBracket] marks the identical
  /// violin pair within the section, following MOLA engraving conventions.
  static const stringOrchestra = StaffProfile(
    id: 'stringOrchestra',
    label: 'String Orchestra',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Strings',
        abbreviation: 'Str.',
        labelVisible: false,
        children: [
          // Violin I + II grouped with a sub-bracket
          StaffNodeGroup(
            connector: SystemConnector.subBracket,
            label: 'Violins',
            abbreviation: 'Vln.',
            numberingStyle: GroupNumberingStyle.none,
            labelVisible: false,
            children: [
              StaffDefinition(
                lines: 5,
                clef: Clef.treble,
                instrumentName: 'Violin I',
                instrumentAbbreviation: 'Vln. I',
                labelVisible: true,
              ),
              StaffDefinition(
                lines: 5,
                clef: Clef.treble,
                instrumentName: 'Violin II',
                instrumentAbbreviation: 'Vln. II',
                labelVisible: true,
              ),
            ],
          ),
          StaffDefinition(
            lines: 5,
            clef: Clef.alto,
            instrumentName: 'Viola',
            instrumentAbbreviation: 'Vla.',
            labelVisible: true,
          ),
          StaffDefinition(
            lines: 5,
            clef: Clef.bass,
            instrumentName: 'Violoncello',
            instrumentAbbreviation: 'Vc.',
            labelVisible: true,
          ),
          StaffDefinition(
            lines: 5,
            clef: Clef.bass,
            instrumentName: 'Double Bass',
            instrumentAbbreviation: 'D.B.',
            labelVisible: true,
          ),
        ],
      ),
    ),
    description:
        '5-part string orchestra (Vln I, Vln II, Vla, Vc, Db) with violin sub-bracket — MOLA compliant.',
    category: ProfileCategory.ensemble,
  );

  /// Classical Chamber Orchestra (Haydn / Mozart / Beethoven instrumentation).
  ///
  /// Features a full standard classical hierarchy:
  /// - Woodwinds: Flute, Oboe, Clarinet in B♭, Bassoon
  /// - Brass: Horn in F
  /// - Strings: Violins I & II (sub-bracketed), Viola, Violoncello, Double Bass
  static const chamberOrchestra = StaffProfile(
    id: 'chamberOrchestra',
    label: 'Chamber Orchestra',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        connector: SystemConnector.none,
        continuousBarlines: false,
        labelPlacement: GroupLabelPlacement.aboveStaff,
        descriptorPlacement: DescriptorPlacement.outsideConnector,
        children: [
          // Woodwinds section
          StaffNodeGroup(
            connector: SystemConnector.bracket,
            label: 'Woodwinds',
            abbreviation: 'W.W.',
            labelVisible: true,
            labelPlacement: GroupLabelPlacement.aboveStaff,
            descriptorPlacement: DescriptorPlacement.outsideConnector,
            children: [
              StaffDefinition(
                lines: 5,
                clef: Clef.treble,
                scale: 0.70,
                instrumentName: 'Flute',
                instrumentAbbreviation: 'Fl.',
                labelVisible: true,
              ),
              StaffDefinition(
                lines: 5,
                clef: Clef.treble,
                scale: 0.70,
                instrumentName: 'Oboe',
                instrumentAbbreviation: 'Ob.',
                labelVisible: true,
              ),
              StaffDefinition(
                lines: 5,
                clef: Clef.treble,
                scale: 0.70,
                instrumentName: 'Clarinet in B♭',
                instrumentAbbreviation: 'Cl.',
                labelVisible: true,
              ),
              StaffDefinition(
                lines: 5,
                clef: Clef.bass,
                scale: 0.70,
                instrumentName: 'Bassoon',
                instrumentAbbreviation: 'Bsn.',
                labelVisible: true,
              ),
            ],
          ),
          // Brass section
          StaffNodeGroup(
            connector: SystemConnector.bracket,
            label: 'Brass',
            abbreviation: 'Br.',
            labelVisible: true,
            labelPlacement: GroupLabelPlacement.aboveStaff,
            descriptorPlacement: DescriptorPlacement.outsideConnector,
            children: [
              StaffDefinition(
                lines: 5,
                clef: Clef.treble,
                scale: 0.70,
                instrumentName: 'Horn in F',
                instrumentAbbreviation: 'Hn.',
                labelVisible: true,
              ),
            ],
          ),
          // Strings section
          StaffNodeGroup(
            connector: SystemConnector.bracket,
            label: 'Strings',
            abbreviation: 'Str.',
            labelVisible: true,
            labelPlacement: GroupLabelPlacement.aboveStaff,
            descriptorPlacement: DescriptorPlacement.outsideConnector,
            children: [
              StaffNodeGroup(
                connector: SystemConnector.subBracket,
                label: 'Violins',
                abbreviation: 'Vln.',
                numberingStyle: GroupNumberingStyle.none,
                labelVisible: false,
                labelPlacement: GroupLabelPlacement.aboveStaff,
                descriptorPlacement: DescriptorPlacement.outsideConnector,
                children: [
                  StaffDefinition(
                    lines: 5,
                    clef: Clef.treble,
                    scale: 0.70,
                    instrumentName: 'Violin I',
                    instrumentAbbreviation: 'Vln. I',
                    labelVisible: true,
                  ),
                  StaffDefinition(
                    lines: 5,
                    clef: Clef.treble,
                    scale: 0.70,
                    instrumentName: 'Violin II',
                    instrumentAbbreviation: 'Vln. II',
                    labelVisible: true,
                  ),
                ],
              ),
              StaffDefinition(
                lines: 5,
                clef: Clef.alto,
                scale: 0.70,
                instrumentName: 'Viola',
                instrumentAbbreviation: 'Vla.',
                labelVisible: true,
              ),
              StaffDefinition(
                lines: 5,
                clef: Clef.bass,
                scale: 0.70,
                instrumentName: 'Violoncello',
                instrumentAbbreviation: 'Vc.',
                labelVisible: true,
              ),
              StaffDefinition(
                lines: 5,
                clef: Clef.bass,
                scale: 0.70,
                instrumentName: 'Double Bass',
                instrumentAbbreviation: 'D.B.',
                labelVisible: true,
              ),
            ],
          ),
        ],
      ),
    ),
    description:
        'Classical chamber orchestra with Woodwinds, Horn, and 5-part Strings.',
    category: ProfileCategory.ensemble,
  );

  /// Blank staff with no clef.
  static const blank = StaffProfile(
    id: 'blank',
    label: 'Blank',
    systemLayout: SystemLayout(
      rootGroup: StaffNodeGroup(
        initialBarline: false,
        children: [
          StaffDefinition(lines: 5, labelVisible: false),
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
    stringOrchestra,
    chamberOrchestra,
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
