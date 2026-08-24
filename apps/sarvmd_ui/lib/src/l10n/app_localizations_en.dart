// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SarvMD';

  @override
  String get appSubtitle => 'Music Manuscript Generator';

  @override
  String get language => 'Language';

  @override
  String get persian => 'فارسی';

  @override
  String get english => 'English';

  @override
  String get actualSize => 'Actual Size';

  @override
  String get zoomIn => 'Zoom In';

  @override
  String get zoomOut => 'Zoom Out';

  @override
  String get resetZoom => 'Reset Zoom';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get saveConfig => 'Save Settings';

  @override
  String get loadPreset => 'Load Preset';

  @override
  String get presetSoloStaff => 'Solo Staff';

  @override
  String get presetPianoScore => 'Piano Grand Staff';

  @override
  String get presetOrchestralScore => 'Full Orchestra';

  @override
  String get presetStringQuartet => 'String Quartet';

  @override
  String get presetChoirSATB => 'Choir (SATB)';

  @override
  String get presetLeadSheet => 'Lead Sheet';

  @override
  String get presetCustom => 'Custom';

  @override
  String get pageSettings => 'Page Settings';

  @override
  String get staffSettings => 'Staff Settings';

  @override
  String get systemSettings => 'System Layout';

  @override
  String get clefSelection => 'Clef';

  @override
  String get lineWeight => 'Line Weight';

  @override
  String get margins => 'Margins (mm)';

  @override
  String get marginsLabel => 'Margins';

  @override
  String get systemIndentation => 'System Indent';

  @override
  String get mouseWings => 'Mouse Guide Lines';

  @override
  String get cadTargets => 'CAD Alignment Targets';

  @override
  String get toggleTheme => 'Toggle Theme';

  @override
  String get toggleLanguage => 'Switch Language';

  @override
  String get pdfExportSuccess => 'PDF compiled successfully.';

  @override
  String get pdfExportError =>
      'PDF compilation failed. Please ensure pdflatex is installed.';

  @override
  String get profiles => 'Profiles';

  @override
  String get document => 'Document';

  @override
  String get staffSpacing => 'Staff Spacing';

  @override
  String systemsCount(int count) {
    return '$count Systems';
  }

  @override
  String get reset => 'Reset';

  @override
  String get resetAllSettings => 'Reset ALL settings to defaults';

  @override
  String get view => 'VIEW';

  @override
  String get appearance => 'Appearance';

  @override
  String get zoom => 'Zoom';

  @override
  String get guides => 'Guides';

  @override
  String get paperEdges => 'Paper Edges';

  @override
  String get paperCenters => 'Paper Centers';

  @override
  String get documentMargins => 'Document Margins';

  @override
  String get staffBounds => 'Staff Bounds';

  @override
  String get export => 'EXPORT';

  @override
  String get portrait => 'Portrait';

  @override
  String get landscape => 'Landscape';

  @override
  String get vertical => 'Vertical';

  @override
  String get horizontal => 'Horizontal';

  @override
  String get top => 'Top';

  @override
  String get bottom => 'Bottom';

  @override
  String get left => 'Left';

  @override
  String get right => 'Right';

  @override
  String get marginsLinked => 'Margins Linked';

  @override
  String get marginsIndependent => 'Margins Independent';

  @override
  String get lineGap => 'Line Gap';

  @override
  String get systemGap => 'System Gap';

  @override
  String get interStaffGap => 'Inter-Staff Gap';

  @override
  String get aboutSarvMD => 'About SarvMD';

  @override
  String get versionInfo => 'Version Info';

  @override
  String get masterExportStudio => 'Master Export Studio';

  @override
  String get exportFormat => 'Export Format';

  @override
  String get resolutionDpi => 'Resolution (DPI)';

  @override
  String get scaleFactor => 'Scale Factor';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get calibration => 'Calibration';

  @override
  String get paperCalibration => 'Paper Calibration';

  @override
  String get measuredWidth => 'Measured Width';

  @override
  String get measuredHeight => 'Measured Height';

  @override
  String get darkMode => 'Dark';

  @override
  String get lightMode => 'Light';

  @override
  String get systemTheme => 'System';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get gold => 'Gold';

  @override
  String get emerald => 'Emerald';

  @override
  String get sapphire => 'Sapphire';

  @override
  String get amethyst => 'Amethyst';

  @override
  String get amber => 'Amber';

  @override
  String get crimson => 'Crimson';

  @override
  String get systemHierarchy => 'System Hierarchy & Clefs';

  @override
  String get addSystem => 'Add System';

  @override
  String get deleteSystem => 'Delete System';

  @override
  String get moveUp => 'Move Up';

  @override
  String get moveDown => 'Move Down';

  @override
  String get trebleClef => 'Treble Clef';

  @override
  String get bassClef => 'Bass Clef';

  @override
  String get altoClef => 'Alto Clef';

  @override
  String get tenorClef => 'Tenor Clef';

  @override
  String get percussionClef => 'Percussion Clef';

  @override
  String get neutralClef => 'Neutral Clef';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryStandard => 'Standard';

  @override
  String get categoryEnsemble => 'Ensemble';

  @override
  String get categoryTablature => 'Tablature';

  @override
  String get categoryPercussion => 'Percussion';

  @override
  String get categoryOther => 'Other';

  @override
  String get addStaff => 'Add Staff';

  @override
  String get ensembleSummary => 'Ensemble Summary';

  @override
  String get totalStaves => 'Total Staves';

  @override
  String get systemHeight => 'System Height';

  @override
  String get density => 'Density';

  @override
  String get mainEnsemble => 'Main Ensemble';

  @override
  String get subGroup => 'Sub Group';

  @override
  String get continuousBarlines => 'Continuous Barlines';

  @override
  String get profilePianoTitle => 'Piano';

  @override
  String get profilePianoDesc => 'Grand staff for piano or keyboard.';

  @override
  String get profileTrebleTitle => 'Treble';

  @override
  String get profileTrebleDesc => 'Standard G clef — violin, flute, soprano.';

  @override
  String get profileBassTitle => 'Bass';

  @override
  String get profileBassDesc => 'Standard F clef — cello, bass guitar, tuba.';

  @override
  String get profileAltoTitle => 'Alto';

  @override
  String get profileAltoDesc => 'C clef on line 3 — viola.';

  @override
  String get profileTenorTitle => 'Tenor';

  @override
  String get profileTenorDesc => 'C clef on line 4 — bassoon, trombone.';

  @override
  String get profileStringQuartetTitle => 'String Quartet';

  @override
  String get profileStringQuartetDesc =>
      'Four-staff score: Violin I, II, Viola, Cello.';

  @override
  String get profileChoirSATBTitle => 'Choir (SATB)';

  @override
  String get profileChoirSATBDesc =>
      'Four staves for Soprano, Alto, Tenor, Bass.';

  @override
  String get profileLeadSheetTitle => 'Lead Sheet';

  @override
  String get profileLeadSheetDesc =>
      'Single melody staff with chord & lyrics spacing.';

  @override
  String get profileGuitarTabTitle => 'Guitar Tab';

  @override
  String get profileGuitarTabDesc => '6-line tablature for standard guitar.';

  @override
  String get profileGuitarGrandTitle => 'Guitar + TAB';

  @override
  String get profileGuitarGrandDesc =>
      'Standard treble staff paired with 6-line tablature.';

  @override
  String get profileBassTabTitle => 'Bass Tab';

  @override
  String get profileBassTabDesc => '4-line tablature for bass guitar.';

  @override
  String get profileBanjoTabTitle => 'Banjo Tab';

  @override
  String get profileBanjoTabDesc => '5-line tablature for 5-string banjo.';

  @override
  String get profileDrumKitTitle => 'Drum Kit';

  @override
  String get profileDrumKitDesc => '5-line percussion staff for drum kit.';

  @override
  String get profilePercussion1Title => 'Percussion (1-line)';

  @override
  String get profilePercussion1Desc => 'Single line for unpitched percussion.';

  @override
  String get profilePercussion3Title => 'Percussion (3-line)';

  @override
  String get profilePercussion3Desc =>
      '3-line staff for multiple unpitched percussion instruments.';

  @override
  String get profileBlankTitle => 'Blank';

  @override
  String get profileBlankDesc => 'Anonymous 5-line staff, no clef.';

  @override
  String get presetJumbo => 'Jumbo (12.0 mm)';

  @override
  String get presetLarge => 'Large (8.5 mm)';

  @override
  String get presetMedium => 'Medium (7.2 mm)';

  @override
  String get presetSmall => 'Small (5.8 mm)';

  @override
  String get presetCustomSize => 'Custom';

  @override
  String get selectStaffSizePreset => 'Select Staff Size Preset';

  @override
  String get staffHeightReadout => 'mm staff height';

  @override
  String get lineGapReadout => 'mm line gap';

  @override
  String get pinDetails => 'Pin Details';

  @override
  String get hideDetails => 'Hide Details';

  @override
  String get molaEducationalTitle => 'Educational Standard';

  @override
  String get molaEducationalDesc =>
      'Large-scale staff for beginners and children. Ensures high legibility for educational materials and teaching pieces.';

  @override
  String get molaOptimalTitle => 'MOLA Optimal Part (8.5mm)';

  @override
  String get molaOptimalDesc =>
      'The gold standard for orchestral parts. Highly recommended by Major Orchestra Librarians for maximum readability on a music stand.';

  @override
  String get molaMinimumTitle => 'MOLA Minimum Part (7.0mm)';

  @override
  String get molaMinimumDesc =>
      'The acceptable minimum for orchestral players. Anything smaller is considered unacceptable by professional standards for parts.';

  @override
  String get molaStudyTitle => 'Study & Score Scale';

  @override
  String get molaStudyDesc =>
      'Legible for printed study scores and piano music. Below the 7.0mm limit, these are not suitable for professional orchestral parts.';

  @override
  String get molaTechnicalTitle => 'Technical Miniature';

  @override
  String get molaTechnicalDesc =>
      'Below the legible score limit (4.0mm). Suitable only for pocket scores or specific technical diagrams, not for performance.';

  @override
  String get staffSizeLabel => 'Staff Size';

  @override
  String get stringSpacingLabel => 'String Spacing';

  @override
  String get systemGapLabel => 'System Gap';

  @override
  String get interStaffGapLabel => 'Inter-staff Gap';

  @override
  String get tabDistanceLabel => 'Tab Distance';

  @override
  String get molaTooltipMessage =>
      'MOLA (Major Orchestra Librarians\' Association) is the global benchmark for professional music manuscript. Their standards ensure that notation remains perfectly legible for orchestral players from a music stand distance, even under challenging stage lighting conditions.';

  @override
  String get configureStaffSettings => 'Configure Staff Settings';

  @override
  String get tabLabeling => 'Labeling';

  @override
  String get tabClefLines => 'Clef & Lines';

  @override
  String get tabFineTuning => 'Fine-Tuning';

  @override
  String get applyChanges => 'Apply Changes';

  @override
  String get defaultInstrumentName => 'Instrument';

  @override
  String get quickInstrumentPresets => 'Quick Instrument Presets';

  @override
  String get selectFamilyPresetDesc =>
      'Select a family to pick an orchestral instrument preset';

  @override
  String get showLabelOnCanvas => 'Show Label on Canvas';

  @override
  String get showLabelOnCanvasDesc =>
      'Toggle visibility of instrument name on score margins';

  @override
  String get instrumentNameLabel => 'Instrument Name';

  @override
  String get instrumentNameHint => 'e.g. Violin I, Cello...';

  @override
  String get abbreviationLabel => 'Abbreviation';

  @override
  String get abbreviationHint => 'e.g. Vln. I, Vc.';

  @override
  String get familyWoodwinds => 'Woodwinds';

  @override
  String get familyBrass => 'Brass';

  @override
  String get familyPercussion => 'Percussion';

  @override
  String get familyStrings => 'Strings';

  @override
  String get familyKeyboardPlucked => 'Keyboard & Plucked';

  @override
  String get clefSettingsHeader => 'Clef Settings';

  @override
  String get clefTrebleTitle => 'Treble Clef (G-Clef)';

  @override
  String get clefTrebleDesc =>
      'For high-register instruments (Violin, Flute, Oboe, Soprano, Piano RH). Anchors G4 on Line 2.';

  @override
  String get clefMovableCTitle => 'Movable C-Clef';

  @override
  String get clefMovableCDesc =>
      'For mid-register instruments. Placed on Line 3 for Viola (Alto) or Line 4 for Tenor Cello/Trombone. Anchors C4.';

  @override
  String get clefBassTitle => 'Bass Clef (F-Clef)';

  @override
  String get clefBassDesc =>
      'For low-register instruments (Cello, Bassoon, Trombone, Tuba, Double Bass, Piano LH). Anchors F3 on Line 4.';

  @override
  String get clefTabTitle => 'Tablature (TAB)';

  @override
  String get clefTabDesc =>
      'For fretted string instruments (Guitar, Bass). Staff lines represent strings, and numbers represent fret positions.';

  @override
  String get clefPercussionTitle => 'Percussion Clef (Neutral)';

  @override
  String get clefPercussionDesc =>
      'For non-pitched rhythm instruments (Snare Drum, Bass Drum, Cymbals, Triangle). Focuses purely on rhythm.';

  @override
  String get clefPresetRegisterHeader => 'Clef Preset / Register';

  @override
  String get clefAnchorLineHeader => 'Clef Anchor Line';

  @override
  String get clefAnchorLineDesc => 'Sets which staff line the clef anchors to';

  @override
  String clefAnchorLineReadout(int line) {
    return 'Line $line';
  }

  @override
  String get clefAnchorTip =>
      'Tip: You can also tap directly on any line in the visual preview above to snap the clef to that line!';

  @override
  String get numberOfStaffLinesHeader => 'Number of Staff Lines';

  @override
  String get numberOfStaffLinesDesc =>
      'Standard is 5 lines (TAB is 6, percussion varies)';

  @override
  String numberOfLinesReadout(int count) {
    return '$count Lines';
  }

  @override
  String get lineCountLockedNote =>
      'Note: Line count is locked for the selected specialized clef.';

  @override
  String get typographyStylingHeader => 'Typography & Styling';

  @override
  String get fontSerifTitle => 'Classic Serif';

  @override
  String get fontSansTitle => 'Modern Sans';

  @override
  String get labelFontSizeLabel => 'Label Font Size';

  @override
  String get italicizeLabelHeader => 'Italicize Label';

  @override
  String get italicizeLabelDesc => 'Use standard italics for score titles';

  @override
  String get alignmentOffsetsHeader => 'Fine Alignment & Offsets';

  @override
  String get horizontalOffsetLabel => 'Horizontal Offset';

  @override
  String get verticalOffsetLabel => 'Vertical Offset';

  @override
  String get livePreviewTip =>
      'Tip: Changes are instantly previewed in the live staff above.';

  @override
  String get exportManuscriptTitle => 'Export Manuscript';

  @override
  String get exportManuscriptSubtitle =>
      'Configure file format, page count, and layer options.';

  @override
  String get outputFilenameLabel => 'Output Filename';

  @override
  String get resetToDefault => 'Reset to default';

  @override
  String get filenameHint => 'Manuscript filename...';

  @override
  String get formatSelectionLabel => 'Format Selection';

  @override
  String get formatPdfDesc => 'Printable sheet music PDF.';

  @override
  String get formatSvgDesc => 'Editable vector paths.';

  @override
  String get formatTexDesc => 'pdfliteral LaTeX code.';

  @override
  String get numberOfPagesLabel => 'Number of Pages';

  @override
  String get presetsLabel => 'Presets: ';

  @override
  String pageCountSuffix(int count) {
    return '$count pgs';
  }

  @override
  String get svgLayerOrganizationLabel => 'SVG Layer Organization';

  @override
  String get svgCategoryTitle => 'Category Layers (Page-Wide)';

  @override
  String get svgCategoryDesc =>
      'Groups elements by type (Staff Lines, Clefs, Barlines, Notes).\nBest for changing colors or line weights globally in Illustrator / Figma.';

  @override
  String get svgSystemTitle => 'System & Staff Layers (Hierarchical)';

  @override
  String get svgSystemDesc =>
      'Groups elements by System (System 1, System 2...).\nBest for selecting, moving, or re-ordering whole staff systems with one click.';

  @override
  String get svgMinimalTitle => 'Minimal (Raw Vector Paths)';

  @override
  String get svgMinimalDesc =>
      'Clean, un-grouped vector paths without layer tags.\nBest for embedding directly into websites or mobile applications.';

  @override
  String get browserDownloads => 'Browser Downloads';

  @override
  String get changeOutputDir => 'Change...';

  @override
  String savedBannerTitle(String fileName) {
    return 'Saved $fileName';
  }

  @override
  String savedBannerSubtitle(String size, int time) {
    return 'Size: $size • Time: ${time}ms';
  }

  @override
  String get copyPath => 'Copy Path';

  @override
  String get pathCopiedToast => 'File path copied to clipboard!';

  @override
  String get exportingState => 'Exporting...';

  @override
  String exportButtonLabel(String format) {
    return 'Export $format';
  }

  @override
  String exportButtonWithPagesLabel(String format, int pages) {
    return 'Export $format ($pages Pages)';
  }

  @override
  String get displayCalibrationTitle => 'Display Calibration';

  @override
  String get displayCalibrationSubtitle =>
      'Calibrate \"Actual Size\" to your physical display.';

  @override
  String get calibrationStep1 =>
      'Hold a physical ruler flat against your screen.';

  @override
  String get calibrationStep2 =>
      'Use the slider or buttons to nudge the bar until it spans exactly 50 mm on your ruler.';

  @override
  String get calibrationStep3 => 'Click Apply. Done.';

  @override
  String get baseline96Dpi => 'baseline (96 DPI)';

  @override
  String get physicalDensity => 'physical density';

  @override
  String get apply => 'Apply';

  @override
  String get changingLanguage => 'Changing language...';
}
