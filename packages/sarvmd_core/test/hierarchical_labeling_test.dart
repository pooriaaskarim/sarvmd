import 'dart:io';

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
      expect(innerX - flutesX, closeTo(7.94, 0.2));
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

      // Woodwinds connector clusters tightly outside Flutes connector
      final expectedWoodwindsOffset = flutesPlacement.connectorOffsetMm +
          GroupPlacementMetrics.connectorLevelSpacingMm;
      expect(woodwindsPlacement.connectorOffsetMm,
          closeTo(expectedWoodwindsOffset, 0.001));

      // Woodwinds label sits outside Flutes label in the outer column
      final minWoodwindsLabelOffset = flutesPlacement.labelOffsetMm +
          flutesPlacement.groupLabelWidthMm +
          GroupPlacementMetrics.groupLabelClearanceMm;
      expect(woodwindsPlacement.labelOffsetMm,
          greaterThanOrEqualTo(minWoodwindsLabelOffset));

      // System indent must accommodate Woodwinds label to avoid clipping left page margin
      final minSystemIndent = woodwindsPlacement.labelOffsetMm +
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

      // Check outer ensemble connector: clusters tightly outside guitar connector
      final ensemblePlacement =
          sys1.groupPlacements.firstWhere((g) => g.abbreviation == 'Ens.');
      expect(
        ensemblePlacement.connectorOffsetMm,
        closeTo(
          guitarPlacement.connectorOffsetMm +
              GroupPlacementMetrics.connectorLevelSpacingMm,
          0.001,
        ),
      );
      // Ensemble label sits outside guitar label
      expect(
        ensemblePlacement.labelOffsetMm,
        greaterThanOrEqualTo(
          guitarPlacement.labelOffsetMm + guitarPlacement.groupLabelWidthMm,
        ),
      );
    });

    test('Single-tier connected group (String Quartet) places connector flush at barline with labels outside', () {
      final vln1 = StaffDefinition(uid: 'v1', instrumentName: 'Violin I');
      final vln2 = StaffDefinition(uid: 'v2', instrumentName: 'Violin II');
      final vla = StaffDefinition(uid: 'va', instrumentName: 'Viola');
      final vc = StaffDefinition(uid: 'vc', instrumentName: 'Violoncello');

      final quartet = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: '', // No group label (Single-tier)
        children: [vln1, vln2, vla, vc],
      );

      final config = PageConfig(systemLayout: SystemLayout(rootGroup: quartet));
      final layout = computeLayout(config);

      final sys = layout.systems.first;
      expect(sys.groupPlacements, hasLength(1));

      final placement = sys.groupPlacements.first;
      // Single-tier connector must sit flush against starting barline
      expect(placement.connectorOffsetMm, equals(0.0));

      // Indent must accommodate longest name (Violoncello ~22mm) + clearance + cushion
      final vcWidth = estimateLabelWidthMm('Violoncello');
      final expectedIndent = vcWidth + GroupPlacementMetrics.staffLabelClearanceMm + 0.5;
      expect(sys.leftIndentMm, closeTo(expectedIndent, 0.1));
      // Far less than the old 30mm+ bloated indent
      expect(sys.leftIndentMm, lessThan(26.0));
    });

    test('Chamber Orchestra Strings ensemble reclaims canvas space and compacts on subsequent systems', () {
      final v1 = StaffDefinition(uid: 'v1', instrumentName: '1', instrumentAbbreviation: '1');
      final v2 = StaffDefinition(uid: 'v2', instrumentName: '2', instrumentAbbreviation: '2');
      final violins = StaffNodeGroup(
        connector: SystemConnector.subBracket,
        label: 'Violins',
        abbreviation: 'Vln.',
        children: [v1, v2],
      );

      final va = StaffDefinition(uid: 'va', instrumentName: 'Viola', instrumentAbbreviation: 'Vla.');
      final vc = StaffDefinition(uid: 'vc', instrumentName: 'Violoncello', instrumentAbbreviation: 'Vc.');
      final db = StaffDefinition(uid: 'db', instrumentName: 'Double Bass', instrumentAbbreviation: 'D.B.');

      final strings = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Strings',
        // No abbreviation on strings: Gould p. 515 mandates omitting family name on subsequent systems
        children: [violins, va, vc, db],
      );

      final config = PageConfig(systemLayout: SystemLayout(rootGroup: strings));
      final layout = computeLayout(config);
      expect(layout.systems.length, greaterThanOrEqualTo(2));

      final sys0 = layout.systems[0];
      final sys1 = layout.systems[1];

      final vlnPlacement0 = sys0.groupPlacements.firstWhere((g) => g.label == 'Violins');
      final strPlacement0 = sys0.groupPlacements.firstWhere((g) => g.label == 'Strings');

      // Violins sub-bracket offset must be locally scoped to "1" and "2" (~2.6mm), NOT inflated by Double Bass (24mm)!
      expect(vlnPlacement0.connectorOffsetMm, lessThan(10.0));
      expect(vlnPlacement0.innerStaffLabelWidthMm, closeTo(estimateLabelWidthMm('2'), 0.2));

      // Strings bracket clears Violins branch extent (~27mm)
      expect(strPlacement0.connectorOffsetMm, greaterThan(vlnPlacement0.connectorOffsetMm));
      expect(strPlacement0.connectorOffsetMm, lessThan(32.0));

      // System 1 indent is well under 46mm (reclaiming 25mm+ from the old 71mm bloat!)
      expect(sys0.leftIndentMm, lessThan(46.0));

      // System 2+ (subsequent systems): Strings family label is omitted!
      // System 2 indent drops drastically (under 25mm, reclaiming over 46mm of music notation width!)
      expect(sys1.leftIndentMm, lessThan(25.0));
    });

    test('compileToTex emits valid hierarchical connectors and text picture environment', () async {
      final v1 = StaffDefinition(uid: 'v1', instrumentName: '1', instrumentAbbreviation: '1');
      final v2 = StaffDefinition(uid: 'v2', instrumentName: '2', instrumentAbbreviation: '2');
      final violins = StaffNodeGroup(
        connector: SystemConnector.subBracket,
        label: 'Violins',
        children: [v1, v2],
      );

      final va = StaffDefinition(uid: 'va', instrumentName: 'Viola', instrumentAbbreviation: 'Vla.');
      final vc = StaffDefinition(uid: 'vc', instrumentName: 'Violoncello', instrumentAbbreviation: 'Vc.');

      final strings = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Strings',
        children: [violins, va, vc],
      );

      final config = PageConfig(systemLayout: SystemLayout(rootGroup: strings));
      final layout = computeLayout(config);

      final tex = ScoreCompiler.compileToTex(config, layout);

      expect(tex, contains(r'\usepackage{helvet}'));
      expect(tex, contains(r'\begin{picture}(0,0)(0,0)'));
      expect(tex, contains(r'\put'));
      expect(tex, contains(r'\textbf{Strings}'));
      expect(tex, contains(r'\textbf{Violins}'));
      expect(tex, contains(r'\makebox(0,0)[r]'));

      // If pdflatex is available, verify actual compilation succeeds without syntax errors
      final tempDir = Directory.systemTemp.createTempSync('sarvmd_tex_test_');
      try {
        final texFile = File('${tempDir.path}/test_score.tex');
        texFile.writeAsStringSync(tex);
        final pdfPath = await ScoreCompiler.compileTexFileToPdf(texFile.path, outputDir: tempDir.path);
        expect(File(pdfPath).existsSync(), isTrue);
        expect(File(pdfPath).lengthSync(), greaterThan(1000));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('toRomanNumeral and formatGroupStaffNumber generate accurate Roman and Arabic numbers', () {
      expect(toRomanNumeral(1), equals('I'));
      expect(toRomanNumeral(2), equals('II'));
      expect(toRomanNumeral(3), equals('III'));
      expect(toRomanNumeral(4), equals('IV'));
      expect(toRomanNumeral(5), equals('V'));
      expect(toRomanNumeral(6), equals('VI'));
      expect(toRomanNumeral(7), equals('VII'));
      expect(toRomanNumeral(8), equals('VIII'));
      expect(toRomanNumeral(9), equals('IX'));
      expect(toRomanNumeral(10), equals('X'));
      expect(toRomanNumeral(12), equals('XII'));

      expect(formatGroupStaffNumber(0, GroupNumberingStyle.none), equals(''));
      expect(formatGroupStaffNumber(0, GroupNumberingStyle.arabic), equals('1'));
      expect(formatGroupStaffNumber(1, GroupNumberingStyle.arabic), equals('2'));
      expect(formatGroupStaffNumber(0, GroupNumberingStyle.roman), equals('I'));
      expect(formatGroupStaffNumber(3, GroupNumberingStyle.roman), equals('IV'));
    });

    test('Model B (GroupNumberingStyle.arabic and .roman) auto-numbers child staves and keeps inner margin minimal', () {
      final flute1 = StaffDefinition(uid: 'fl1', instrumentName: 'Flute');
      final flute2 = StaffDefinition(uid: 'fl2', instrumentName: 'Flute');

      final flutesArabic = StaffNodeGroup(
        connector: SystemConnector.subBracket,
        label: 'Flutes',
        abbreviation: 'Fl.',
        numberingStyle: GroupNumberingStyle.arabic,
        children: [flute1, flute2],
      );

      final configArabic = PageConfig(
        systemLayout: SystemLayout(rootGroup: flutesArabic),
      );

      final layoutArabic = computeLayout(configArabic);
      final sysArabic = layoutArabic.systems.first;

      // Both staves must be dynamically resolved as '1' and '2'
      expect(sysArabic.staves[0].resolvedLabel, equals('1'));
      expect(sysArabic.staves[1].resolvedLabel, equals('2'));

      // Inner label width must be minimal (~2.6mm for '1' or '2')
      final placementArabic = sysArabic.groupPlacements.first;
      expect(placementArabic.innerStaffLabelWidthMm, lessThan(4.0));
      expect(placementArabic.innerStaffLabelWidthMm, greaterThan(2.0));

      // Test Roman numerals
      final hornsGroup = StaffNodeGroup(
        connector: SystemConnector.subBracket,
        label: 'Horns in F',
        numberingStyle: GroupNumberingStyle.roman,
        children: [
          StaffDefinition(uid: 'h1', instrumentName: 'Horn 1'),
          StaffDefinition(uid: 'h2', instrumentName: 'Horn 2'),
          StaffDefinition(uid: 'h3', instrumentName: 'Horn 3'),
          StaffDefinition(uid: 'h4', instrumentName: 'Horn 4'),
        ],
      );

      final configRoman = PageConfig(
        systemLayout: SystemLayout(rootGroup: hornsGroup),
      );
      final layoutRoman = computeLayout(configRoman);
      final sysRoman = layoutRoman.systems.first;

      expect(sysRoman.staves[0].resolvedLabel, equals('I'));
      expect(sysRoman.staves[1].resolvedLabel, equals('II'));
      expect(sysRoman.staves[2].resolvedLabel, equals('III'));
      expect(sysRoman.staves[3].resolvedLabel, equals('IV'));

      // Auxiliary instrument (e.g. Piccolo) in an Arabic group must preserve its specific name
      final flutesWithPicc = StaffNodeGroup(
        connector: SystemConnector.subBracket,
        label: 'Flutes',
        numberingStyle: GroupNumberingStyle.arabic,
        children: [
          StaffDefinition(uid: 'f1', instrumentName: 'Flute'),
          StaffDefinition(uid: 'f2', instrumentName: 'Flute'),
          StaffDefinition(uid: 'picc', instrumentName: 'Piccolo', instrumentAbbreviation: 'Picc.'),
        ],
      );

      final configPicc = PageConfig(
        systemLayout: SystemLayout(rootGroup: flutesWithPicc),
      );
      final layoutPicc = computeLayout(configPicc);
      final sysPicc = layoutPicc.systems.first;

      expect(sysPicc.staves[0].resolvedLabel, equals('1'));
      expect(sysPicc.staves[1].resolvedLabel, equals('2'));
      expect(sysPicc.staves[2].resolvedLabel, equals('Piccolo'));
    });

    test('Model C (GroupLabelPlacement.aboveStaff) eliminates horizontal indent space and emits section header', () async {
      final ob1 = StaffDefinition(uid: 'ob1', instrumentName: '1', instrumentAbbreviation: '1');
      final ob2 = StaffDefinition(uid: 'ob2', instrumentName: '2', instrumentAbbreviation: '2');
      final oboes = StaffNodeGroup(
        connector: SystemConnector.subBracket,
        label: 'Oboes',
        children: [ob1, ob2],
      );

      // Model A/B standard margin placement
      final woodwindsMargin = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'WOODWINDS',
        labelPlacement: GroupLabelPlacement.margin,
        children: [oboes],
      );

      final configMargin = PageConfig(systemLayout: SystemLayout(rootGroup: woodwindsMargin));
      final layoutMargin = computeLayout(configMargin);
      final sysMargin = layoutMargin.systems.first;

      // Model C: section header above staff
      final woodwindsAbove = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'WOODWINDS',
        labelPlacement: GroupLabelPlacement.aboveStaff,
        children: [oboes],
      );

      final configAbove = PageConfig(systemLayout: SystemLayout(rootGroup: woodwindsAbove));
      final layoutAbove = computeLayout(configAbove);
      final sysAbove = layoutAbove.systems.first;

      // Model C must have zero groupLabelWidthMm in horizontal indent calculations
      final placementAbove = sysAbove.groupPlacements.firstWhere((p) => p.label == 'WOODWINDS');
      expect(placementAbove.labelPlacement, equals(GroupLabelPlacement.aboveStaff));
      expect(placementAbove.groupLabelWidthMm, equals(0.0));
      expect(placementAbove.labelOffsetMm, equals(0.0));

      // Indent difference: Model C reclaims approximately the entire width of "WOODWINDS" + clearance!
      final indentSavedMm = sysMargin.leftIndentMm - sysAbove.leftIndentMm;
      expect(indentSavedMm, greaterThan(25.0));

      // Verify SVG emission
      final svg = ScoreCompiler.compileToSvg(configAbove, layoutAbove);
      expect(svg, contains('WOODWINDS'));
      expect(svg, contains('text-anchor="start"'));

      // Verify LaTeX emission
      final tex = ScoreCompiler.compileToTex(configAbove, layoutAbove);
      expect(tex, contains(r'\textbf{WOODWINDS}'));
      expect(tex, contains(r'\makebox(0,0)[bl]'));

      // Verify PDF emission
      final pdfBytes = await ScoreCompiler.compileToPdf(configAbove, layoutAbove);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}

