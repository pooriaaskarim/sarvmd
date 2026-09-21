import 'package:sarvmd_core/sarvmd_core.dart';
import 'package:test/test.dart';

void main() {
  group('Hierarchical Labeling & Layout Indent Tests', () {
    test('estimateLabelWidthMm calculates correct typographic metrics', () {
      expect(estimateLabelWidthMm(''), equals(0.0));
      expect(estimateLabelWidthMm('   '), equals(0.0));

      final widthSingle = estimateLabelWidthMm('1');
      expect(widthSingle, greaterThan(0.0));
      // 0.55 em * 11pt * (25.4/72) + 0.5mm cushion ≈ 2.63 mm
      expect(widthSingle, closeTo(2.63, 0.2));

      final widthFlutes = estimateLabelWidthMm('Flutes', isGroup: true);
      // Character-weighted bold font advance ≈ 12.4 mm
      expect(widthFlutes, greaterThan(10.0));
      expect(widthFlutes, closeTo(12.4, 0.6));

      // Multi-word strings budget the full string rather than single words
      final widthBassTrombone = estimateLabelWidthMm('Bass Trombone');
      expect(widthBassTrombone, greaterThan(25.0));

      // Explicit newlines budget the longest line
      final widthMultiLine = estimateLabelWidthMm('Trumpets\nin C');
      expect(widthMultiLine, lessThan(widthBassTrombone));
    });

    test('Two-tier labeled group computes two-tier indent without collision', () {
      final staff1 = StaffDefinition(
        uid: 'flute1',
        instrumentName: '1',
        instrumentAbbreviation: '1',
      );
      final staff2 = StaffDefinition(
        uid: 'flute2',
        instrumentName: '2',
        instrumentAbbreviation: '2',
      );

      final flutesGroup = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Flutes',
        abbreviation: 'Fl.',
        children: [staff1, staff2],
      );

      final config = PageConfig(
        systemLayout: SystemLayout(
          rootGroup: flutesGroup,
        ),
      );

      final layout = computeLayout(config);
      expect(layout.systems, isNotEmpty);

      final system = layout.systems.first;
      expect(system.groupPlacements, hasLength(1));

      final placement = system.groupPlacements.first;
      expect(placement.label, equals('Flutes'));
      expect(placement.groupLabelWidthMm, greaterThan(10.0));
      expect(placement.innerStaffLabelWidthMm, greaterThan(1.5));
      expect(system.maxInnerLabelWidthMm, equals(placement.innerStaffLabelWidthMm));

      // Indent must accommodate group label + clearance + bracket offset + inner label + clearance
      final expectedMinIndent = placement.groupLabelWidthMm +
          GroupPlacementMetrics.groupLabelClearanceMm +
          placement.innerStaffLabelWidthMm +
          GroupPlacementMetrics.staffLabelClearanceMm;

      expect(system.leftIndentMm, greaterThan(expectedMinIndent));
    });

    test('Single-tier fallback when group label is empty', () {
      final staff1 = StaffDefinition(
        uid: 'vln1',
        instrumentName: 'Violin I',
      );
      final staff2 = StaffDefinition(
        uid: 'vln2',
        instrumentName: 'Violin II',
      );

      final group = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: '', // Empty group label
        children: [staff1, staff2],
      );

      final config = PageConfig(
        systemLayout: SystemLayout(rootGroup: group),
      );

      final layout = computeLayout(config);
      final system = layout.systems.first;
      final placement = system.groupPlacements.first;

      // Group label width is 0, inner staff label width accounts for staves in connected group
      expect(placement.groupLabelWidthMm, equals(0.0));
      expect(system.maxInnerLabelWidthMm, equals(placement.innerStaffLabelWidthMm));

      // System indent still accommodates Violin names + bracket offset
      expect(system.leftIndentMm, greaterThan(15.0));
    });

    test('Zero indent when all labels are empty or hidden', () {
      final staff1 = StaffDefinition(
        uid: 's1',
        instrumentName: '',
        labelVisible: false,
      );
      final staff2 = StaffDefinition(
        uid: 's2',
        instrumentName: '',
        labelVisible: false,
      );

      final group = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: '',
        labelVisible: false,
        children: [staff1, staff2],
      );

      final config = PageConfig(
        systemLayout: SystemLayout(rootGroup: group),
      );

      final layout = computeLayout(config);
      final system = layout.systems.first;

      expect(system.leftIndentMm, equals(0.0));
      expect(system.maxInnerLabelWidthMm, equals(0.0));
    });

    test('Odd-staff 3-staff group calculates distinct inner and outer tiers', () {
      final tbn1 = StaffDefinition(uid: 't1', instrumentName: '1');
      final tbn2 = StaffDefinition(uid: 't2', instrumentName: '2');
      final tbn3 = StaffDefinition(uid: 't3', instrumentName: '3');

      final trombones = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Trombones',
        children: [tbn1, tbn2, tbn3],
      );

      final config = PageConfig(
        systemLayout: SystemLayout(rootGroup: trombones),
      );

      final layout = computeLayout(config);
      final system = layout.systems.first;

      expect(system.staves, hasLength(3));
      expect(system.groupPlacements.first.label, equals('Trombones'));
      expect(system.groupPlacements.first.innerStaffLabelWidthMm, greaterThan(0.0));
      expect(system.leftIndentMm, greaterThan(20.0));
    });

    test('emitSvg renders two-tier labels and connectors without coordinate collision', () {
      final flute1 = StaffDefinition(uid: 'f1', instrumentName: '1');
      final flute2 = StaffDefinition(uid: 'f2', instrumentName: '2');
      final flutes = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Flutes',
        children: [flute1, flute2],
      );

      final config = PageConfig(
        systemLayout: SystemLayout(rootGroup: flutes),
      );

      final layout = computeLayout(config);
      final svg = emitSvg(config, layout);

      expect(svg, contains('Flutes'));
      expect(svg, contains('1'));
      expect(svg, contains('2'));

      final flutesMatch =
          RegExp(r'<text x="([\d\.]+)"[^>]*>Flutes</text>').firstMatch(svg);
      expect(flutesMatch, isNotNull);
      final flutesX = double.parse(flutesMatch!.group(1)!);

      final innerMatch =
          RegExp(r'<text x="([\d\.]+)"[^>]*>1</text>').firstMatch(svg);
      expect(innerMatch, isNotNull);
      final innerX = double.parse(innerMatch!.group(1)!);

      // Outer group label sits to the left of the connector and inner label
      expect(flutesX, lessThan(innerX));
      expect(innerX - flutesX, closeTo(9.63, 0.2));
    });

    test('Nested sub-group labels do not collide with parent connectors', () {
      final f1 = StaffDefinition(uid: 'f1', instrumentName: '1');
      final f2 = StaffDefinition(uid: 'f2', instrumentName: '2');
      final flutes = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Flutes',
        children: [f1, f2],
      );

      final ob1 = StaffDefinition(uid: 'ob1', instrumentName: '1');
      final ob2 = StaffDefinition(uid: 'ob2', instrumentName: '2');
      final oboes = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Oboes',
        children: [ob1, ob2],
      );

      final woodwinds = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Woodwinds',
        children: [flutes, oboes],
      );

      final config = PageConfig(
        systemLayout: SystemLayout(rootGroup: woodwinds),
      );

      final layout = computeLayout(config);
      final system = layout.systems.first;

      final flutesPlacement =
          system.groupPlacements.firstWhere((g) => g.label == 'Flutes');
      final woodwindsPlacement =
          system.groupPlacements.firstWhere((g) => g.label == 'Woodwinds');

      // Flutes sits at level 0
      expect(flutesPlacement.level, equals(0));
      // Woodwinds sits at level 1
      expect(woodwindsPlacement.level, equals(1));

      // Woodwinds connector offset MUST be strictly greater than Flutes connector offset + Flutes label width
      final minWoodwindsOffset = flutesPlacement.connectorOffsetMm +
          GroupPlacementMetrics.groupLabelClearanceMm +
          flutesPlacement.groupLabelWidthMm;
      expect(woodwindsPlacement.connectorOffsetMm,
          greaterThanOrEqualTo(minWoodwindsOffset));

      // System indent must accommodate Woodwinds label to avoid clipping left page margin
      final minSystemIndent = woodwindsPlacement.connectorOffsetMm +
          GroupPlacementMetrics.groupLabelClearanceMm +
          woodwindsPlacement.groupLabelWidthMm;
      expect(system.leftIndentMm, greaterThan(minSystemIndent));
    });

    test('emitPdf renders two-tier hierarchical labels without error', () async {
      final flute1 = StaffDefinition(uid: 'f1', instrumentName: '1');
      final flute2 = StaffDefinition(uid: 'f2', instrumentName: '2');
      final flutes = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Flutes',
        children: [flute1, flute2],
      );

      final config = PageConfig(
        systemLayout: SystemLayout(rootGroup: flutes),
      );

      final layout = computeLayout(config);
      final pdfBytes = await emitPdf(config, layout);

      expect(pdfBytes, isNotEmpty);
      expect(String.fromCharCodes(pdfBytes.take(4)), equals('%PDF'));
    });

    test('StaffNodeGroupTreeX depth inspection and Gould constants', () {
      expect(GroupPlacementMetrics.standardMaxNestingDepth, equals(2));
      expect(GroupPlacementMetrics.emergencyMaxNestingDepth, equals(3));

      final f1 = StaffDefinition(uid: 'f1', instrumentName: '1');
      final f2 = StaffDefinition(uid: 'f2', instrumentName: '2');
      final flutes = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Flutes',
        children: [f1, f2],
      );

      final ob1 = StaffDefinition(uid: 'ob1', instrumentName: '1');
      final ob2 = StaffDefinition(uid: 'ob2', instrumentName: '2');
      final oboes = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Oboes',
        children: [ob1, ob2],
      );

      final woodwinds = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Woodwinds',
        children: [flutes, oboes],
      );

      final root = StaffNodeGroup(
        children: [woodwinds],
      );

      // Depth of root is 0
      expect(root.findGroupDepth(root.hashCode), equals(0));
      // Depth of woodwinds (child of root) is 1
      expect(root.findGroupDepth(woodwinds.hashCode), equals(1));
      // Depth of flutes (child of woodwinds) is 2
      expect(root.findGroupDepth(flutes.hashCode), equals(2));
      // Depth of f1's parent group (flutes) is 2
      expect(root.findStaffParentDepth('f1'), equals(2));
      expect(root.findStaffParentDepth('nonexistent'), isNull);

      // Subgroup depth: root has woodwinds (1) -> flutes (2), so maxSubGroupDepth = 2
      expect(root.maxSubGroupDepth, equals(2));
      expect(woodwinds.maxSubGroupDepth, equals(1));
      expect(flutes.maxSubGroupDepth, equals(0));

      // allStaves
      final staves = root.allStaves;
      expect(staves, hasLength(4));
      expect(staves.map((s) => s.uid), equals(['f1', 'f2', 'ob1', 'ob2']));
    });

    test('Sub-group abbreviations and staff abbreviations maintain clear margin from bracket ticks', () {
      final pBass = StaffDefinition(
        uid: 'pb',
        instrumentName: 'Piano Bass',
        instrumentAbbreviation: 'P.B.',
      );
      final pTreb = StaffDefinition(
        uid: 'pt',
        instrumentName: 'Piano Treble',
        instrumentAbbreviation: 'P.T.',
      );
      final piano = StaffNodeGroup(
        connector: SystemConnector.brace,
        label: 'Piano',
        abbreviation: 'Pno.',
        children: [pBass, pTreb],
      );

      final gTreb = StaffDefinition(
        uid: 'gt',
        instrumentName: 'Guitar Treble',
        instrumentAbbreviation: 'G.Tr.',
      );
      final gTab = StaffDefinition(
        uid: 'gb',
        instrumentName: 'Guitar Tab',
        instrumentAbbreviation: 'G.Tb.',
      );
      final guitar = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Guitar',
        abbreviation: 'Gui.',
        children: [gTreb, gTab],
      );

      final ensemble = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Ensemble',
        abbreviation: 'Ens.',
        children: [piano, guitar],
      );

      final config = PageConfig(
        systemLayout: SystemLayout(rootGroup: ensemble),
      );

      final layout = computeLayout(config);
      expect(layout.systems.length, greaterThanOrEqualTo(2));

      // Examine system 1 (subsequent system where abbreviations are active)
      final sys1 = layout.systems[1];
      final gTabWidth = estimateLabelWidthMm('G.Tb.');

      final guitarPlacement =
          sys1.groupPlacements.firstWhere((g) => g.abbreviation == 'Gui.');

      // The connector offset for guitar bracket must clear the inner abbreviation + bracket tick + clearance
      final expectedMinConnectorOffset = gTabWidth +
          GroupPlacementMetrics.staffLabelClearanceMm +
          GroupPlacementMetrics.bracketTickLengthMm +
          GroupPlacementMetrics.staffLabelConnectorClearanceMm;

      expect(guitarPlacement.connectorOffsetMm,
          greaterThanOrEqualTo(expectedMinConnectorOffset));

      // Right tip of the bracket tick:
      // connectorX = leftX - guitarPlacement.connectorOffsetMm
      // tickTipX = connectorX + bracketTickLengthMm
      // Leftmost edge of label:
      // labelRightX = leftX - staffLabelClearanceMm
      // labelLeftX = labelRightX - gTabWidth
      // We must have: labelLeftX - tickTipX >= staffLabelConnectorClearanceMm
      final double tickEndOffsetFromBarline =
          guitarPlacement.connectorOffsetMm -
              GroupPlacementMetrics.bracketTickLengthMm;
      final double labelLeftOffsetFromBarline =
          GroupPlacementMetrics.staffLabelClearanceMm + gTabWidth;
      final double clearanceBetweenTickAndLabel =
          tickEndOffsetFromBarline - labelLeftOffsetFromBarline;

      expect(clearanceBetweenTickAndLabel,
          greaterThanOrEqualTo(GroupPlacementMetrics.staffLabelConnectorClearanceMm - 0.001));

      // Check outer ensemble connector: must be further out than Gui. label
      final ensemblePlacement =
          sys1.groupPlacements.firstWhere((g) => g.abbreviation == 'Ens.');
      expect(ensemblePlacement.connectorOffsetMm,
          greaterThan(guitarPlacement.connectorOffsetMm + guitarPlacement.groupLabelWidthMm));
    });
  });
}

