import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SarvMD'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Music Manuscript Generator'**
  String get appSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @persian.
  ///
  /// In en, this message translates to:
  /// **'فارسی'**
  String get persian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @actualSize.
  ///
  /// In en, this message translates to:
  /// **'Actual Size'**
  String get actualSize;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get zoomOut;

  /// No description provided for @resetZoom.
  ///
  /// In en, this message translates to:
  /// **'Reset Zoom'**
  String get resetZoom;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @saveConfig.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveConfig;

  /// No description provided for @loadPreset.
  ///
  /// In en, this message translates to:
  /// **'Load Preset'**
  String get loadPreset;

  /// No description provided for @presetSoloStaff.
  ///
  /// In en, this message translates to:
  /// **'Solo Staff'**
  String get presetSoloStaff;

  /// No description provided for @presetPianoScore.
  ///
  /// In en, this message translates to:
  /// **'Piano Grand Staff'**
  String get presetPianoScore;

  /// No description provided for @presetOrchestralScore.
  ///
  /// In en, this message translates to:
  /// **'Full Orchestra'**
  String get presetOrchestralScore;

  /// No description provided for @presetStringQuartet.
  ///
  /// In en, this message translates to:
  /// **'String Quartet'**
  String get presetStringQuartet;

  /// No description provided for @presetChoirSATB.
  ///
  /// In en, this message translates to:
  /// **'Choir (SATB)'**
  String get presetChoirSATB;

  /// No description provided for @presetLeadSheet.
  ///
  /// In en, this message translates to:
  /// **'Lead Sheet'**
  String get presetLeadSheet;

  /// No description provided for @presetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get presetCustom;

  /// No description provided for @pageSettings.
  ///
  /// In en, this message translates to:
  /// **'Page Settings'**
  String get pageSettings;

  /// No description provided for @staffSettings.
  ///
  /// In en, this message translates to:
  /// **'Staff Settings'**
  String get staffSettings;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Layout'**
  String get systemSettings;

  /// No description provided for @clefSelection.
  ///
  /// In en, this message translates to:
  /// **'Clef'**
  String get clefSelection;

  /// No description provided for @lineWeight.
  ///
  /// In en, this message translates to:
  /// **'Line Weight'**
  String get lineWeight;

  /// No description provided for @margins.
  ///
  /// In en, this message translates to:
  /// **'Margins (mm)'**
  String get margins;

  /// No description provided for @marginsLabel.
  ///
  /// In en, this message translates to:
  /// **'Margins'**
  String get marginsLabel;

  /// No description provided for @systemIndentation.
  ///
  /// In en, this message translates to:
  /// **'System Indent'**
  String get systemIndentation;

  /// No description provided for @mouseWings.
  ///
  /// In en, this message translates to:
  /// **'Mouse Guide Lines'**
  String get mouseWings;

  /// No description provided for @cadTargets.
  ///
  /// In en, this message translates to:
  /// **'CAD Alignment Targets'**
  String get cadTargets;

  /// No description provided for @toggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle Theme'**
  String get toggleTheme;

  /// No description provided for @toggleLanguage.
  ///
  /// In en, this message translates to:
  /// **'Switch Language'**
  String get toggleLanguage;

  /// No description provided for @pdfExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'PDF compiled successfully.'**
  String get pdfExportSuccess;

  /// No description provided for @pdfExportError.
  ///
  /// In en, this message translates to:
  /// **'PDF compilation failed. Please ensure pdflatex is installed.'**
  String get pdfExportError;

  /// No description provided for @profiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profiles;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @staffSpacing.
  ///
  /// In en, this message translates to:
  /// **'Staff Spacing'**
  String get staffSpacing;

  /// No description provided for @systemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Systems'**
  String systemsCount(int count);

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetAllSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset ALL settings to defaults'**
  String get resetAllSettings;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'VIEW'**
  String get view;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @zoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get zoom;

  /// No description provided for @guides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get guides;

  /// No description provided for @paperEdges.
  ///
  /// In en, this message translates to:
  /// **'Paper Edges'**
  String get paperEdges;

  /// No description provided for @paperCenters.
  ///
  /// In en, this message translates to:
  /// **'Paper Centers'**
  String get paperCenters;

  /// No description provided for @documentMargins.
  ///
  /// In en, this message translates to:
  /// **'Document Margins'**
  String get documentMargins;

  /// No description provided for @staffBounds.
  ///
  /// In en, this message translates to:
  /// **'Staff Bounds'**
  String get staffBounds;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'EXPORT'**
  String get export;

  /// No description provided for @portrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get portrait;

  /// No description provided for @landscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get landscape;

  /// No description provided for @vertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get vertical;

  /// No description provided for @horizontal.
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get horizontal;

  /// No description provided for @top.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get top;

  /// No description provided for @bottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get bottom;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// No description provided for @marginsLinked.
  ///
  /// In en, this message translates to:
  /// **'Margins Linked'**
  String get marginsLinked;

  /// No description provided for @marginsIndependent.
  ///
  /// In en, this message translates to:
  /// **'Margins Independent'**
  String get marginsIndependent;

  /// No description provided for @lineGap.
  ///
  /// In en, this message translates to:
  /// **'Line Gap'**
  String get lineGap;

  /// No description provided for @systemGap.
  ///
  /// In en, this message translates to:
  /// **'System Gap'**
  String get systemGap;

  /// No description provided for @interStaffGap.
  ///
  /// In en, this message translates to:
  /// **'Inter-Staff Gap'**
  String get interStaffGap;

  /// No description provided for @aboutSarvMD.
  ///
  /// In en, this message translates to:
  /// **'About SarvMD'**
  String get aboutSarvMD;

  /// No description provided for @versionInfo.
  ///
  /// In en, this message translates to:
  /// **'Version Info'**
  String get versionInfo;

  /// No description provided for @masterExportStudio.
  ///
  /// In en, this message translates to:
  /// **'Master Export Studio'**
  String get masterExportStudio;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get exportFormat;

  /// No description provided for @resolutionDpi.
  ///
  /// In en, this message translates to:
  /// **'Resolution (DPI)'**
  String get resolutionDpi;

  /// No description provided for @scaleFactor.
  ///
  /// In en, this message translates to:
  /// **'Scale Factor'**
  String get scaleFactor;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @calibration.
  ///
  /// In en, this message translates to:
  /// **'Calibration'**
  String get calibration;

  /// No description provided for @paperCalibration.
  ///
  /// In en, this message translates to:
  /// **'Paper Calibration'**
  String get paperCalibration;

  /// No description provided for @measuredWidth.
  ///
  /// In en, this message translates to:
  /// **'Measured Width'**
  String get measuredWidth;

  /// No description provided for @measuredHeight.
  ///
  /// In en, this message translates to:
  /// **'Measured Height'**
  String get measuredHeight;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @gold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// No description provided for @emerald.
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get emerald;

  /// No description provided for @sapphire.
  ///
  /// In en, this message translates to:
  /// **'Sapphire'**
  String get sapphire;

  /// No description provided for @amethyst.
  ///
  /// In en, this message translates to:
  /// **'Amethyst'**
  String get amethyst;

  /// No description provided for @amber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get amber;

  /// No description provided for @crimson.
  ///
  /// In en, this message translates to:
  /// **'Crimson'**
  String get crimson;

  /// No description provided for @systemHierarchy.
  ///
  /// In en, this message translates to:
  /// **'System Hierarchy & Clefs'**
  String get systemHierarchy;

  /// No description provided for @addSystem.
  ///
  /// In en, this message translates to:
  /// **'Add System'**
  String get addSystem;

  /// No description provided for @deleteSystem.
  ///
  /// In en, this message translates to:
  /// **'Delete System'**
  String get deleteSystem;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move Up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move Down'**
  String get moveDown;

  /// No description provided for @trebleClef.
  ///
  /// In en, this message translates to:
  /// **'Treble Clef'**
  String get trebleClef;

  /// No description provided for @bassClef.
  ///
  /// In en, this message translates to:
  /// **'Bass Clef'**
  String get bassClef;

  /// No description provided for @altoClef.
  ///
  /// In en, this message translates to:
  /// **'Alto Clef'**
  String get altoClef;

  /// No description provided for @tenorClef.
  ///
  /// In en, this message translates to:
  /// **'Tenor Clef'**
  String get tenorClef;

  /// No description provided for @percussionClef.
  ///
  /// In en, this message translates to:
  /// **'Percussion Clef'**
  String get percussionClef;

  /// No description provided for @neutralClef.
  ///
  /// In en, this message translates to:
  /// **'Neutral Clef'**
  String get neutralClef;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get categoryStandard;

  /// No description provided for @categoryEnsemble.
  ///
  /// In en, this message translates to:
  /// **'Ensemble'**
  String get categoryEnsemble;

  /// No description provided for @categoryTablature.
  ///
  /// In en, this message translates to:
  /// **'Tablature'**
  String get categoryTablature;

  /// No description provided for @categoryPercussion.
  ///
  /// In en, this message translates to:
  /// **'Percussion'**
  String get categoryPercussion;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @addStaff.
  ///
  /// In en, this message translates to:
  /// **'Add Staff'**
  String get addStaff;

  /// No description provided for @ensembleSummary.
  ///
  /// In en, this message translates to:
  /// **'Ensemble Summary'**
  String get ensembleSummary;

  /// No description provided for @totalStaves.
  ///
  /// In en, this message translates to:
  /// **'Total Staves'**
  String get totalStaves;

  /// No description provided for @systemHeight.
  ///
  /// In en, this message translates to:
  /// **'System Height'**
  String get systemHeight;

  /// No description provided for @density.
  ///
  /// In en, this message translates to:
  /// **'Density'**
  String get density;

  /// No description provided for @mainEnsemble.
  ///
  /// In en, this message translates to:
  /// **'Main Ensemble'**
  String get mainEnsemble;

  /// No description provided for @subGroup.
  ///
  /// In en, this message translates to:
  /// **'Sub Group'**
  String get subGroup;

  /// No description provided for @continuousBarlines.
  ///
  /// In en, this message translates to:
  /// **'Continuous Barlines'**
  String get continuousBarlines;

  /// No description provided for @profilePianoTitle.
  ///
  /// In en, this message translates to:
  /// **'Piano'**
  String get profilePianoTitle;

  /// No description provided for @profilePianoDesc.
  ///
  /// In en, this message translates to:
  /// **'Grand staff for piano or keyboard.'**
  String get profilePianoDesc;

  /// No description provided for @profileTrebleTitle.
  ///
  /// In en, this message translates to:
  /// **'Treble'**
  String get profileTrebleTitle;

  /// No description provided for @profileTrebleDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard G clef — violin, flute, soprano.'**
  String get profileTrebleDesc;

  /// No description provided for @profileBassTitle.
  ///
  /// In en, this message translates to:
  /// **'Bass'**
  String get profileBassTitle;

  /// No description provided for @profileBassDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard F clef — cello, bass guitar, tuba.'**
  String get profileBassDesc;

  /// No description provided for @profileAltoTitle.
  ///
  /// In en, this message translates to:
  /// **'Alto'**
  String get profileAltoTitle;

  /// No description provided for @profileAltoDesc.
  ///
  /// In en, this message translates to:
  /// **'C clef on line 3 — viola.'**
  String get profileAltoDesc;

  /// No description provided for @profileTenorTitle.
  ///
  /// In en, this message translates to:
  /// **'Tenor'**
  String get profileTenorTitle;

  /// No description provided for @profileTenorDesc.
  ///
  /// In en, this message translates to:
  /// **'C clef on line 4 — bassoon, trombone.'**
  String get profileTenorDesc;

  /// No description provided for @profileStringQuartetTitle.
  ///
  /// In en, this message translates to:
  /// **'String Quartet'**
  String get profileStringQuartetTitle;

  /// No description provided for @profileStringQuartetDesc.
  ///
  /// In en, this message translates to:
  /// **'Four-staff score: Violin I, II, Viola, Cello.'**
  String get profileStringQuartetDesc;

  /// No description provided for @profileChoirSATBTitle.
  ///
  /// In en, this message translates to:
  /// **'Choir (SATB)'**
  String get profileChoirSATBTitle;

  /// No description provided for @profileChoirSATBDesc.
  ///
  /// In en, this message translates to:
  /// **'Four staves for Soprano, Alto, Tenor, Bass.'**
  String get profileChoirSATBDesc;

  /// No description provided for @profileLeadSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Lead Sheet'**
  String get profileLeadSheetTitle;

  /// No description provided for @profileLeadSheetDesc.
  ///
  /// In en, this message translates to:
  /// **'Single melody staff with chord & lyrics spacing.'**
  String get profileLeadSheetDesc;

  /// No description provided for @profileGuitarTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Guitar Tab'**
  String get profileGuitarTabTitle;

  /// No description provided for @profileGuitarTabDesc.
  ///
  /// In en, this message translates to:
  /// **'6-line tablature for standard guitar.'**
  String get profileGuitarTabDesc;

  /// No description provided for @profileGuitarGrandTitle.
  ///
  /// In en, this message translates to:
  /// **'Guitar + TAB'**
  String get profileGuitarGrandTitle;

  /// No description provided for @profileGuitarGrandDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard treble staff paired with 6-line tablature.'**
  String get profileGuitarGrandDesc;

  /// No description provided for @profileBassTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Bass Tab'**
  String get profileBassTabTitle;

  /// No description provided for @profileBassTabDesc.
  ///
  /// In en, this message translates to:
  /// **'4-line tablature for bass guitar.'**
  String get profileBassTabDesc;

  /// No description provided for @profileBanjoTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Banjo Tab'**
  String get profileBanjoTabTitle;

  /// No description provided for @profileBanjoTabDesc.
  ///
  /// In en, this message translates to:
  /// **'5-line tablature for 5-string banjo.'**
  String get profileBanjoTabDesc;

  /// No description provided for @profileDrumKitTitle.
  ///
  /// In en, this message translates to:
  /// **'Drum Kit'**
  String get profileDrumKitTitle;

  /// No description provided for @profileDrumKitDesc.
  ///
  /// In en, this message translates to:
  /// **'5-line percussion staff for drum kit.'**
  String get profileDrumKitDesc;

  /// No description provided for @profilePercussion1Title.
  ///
  /// In en, this message translates to:
  /// **'Percussion (1-line)'**
  String get profilePercussion1Title;

  /// No description provided for @profilePercussion1Desc.
  ///
  /// In en, this message translates to:
  /// **'Single line for unpitched percussion.'**
  String get profilePercussion1Desc;

  /// No description provided for @profilePercussion3Title.
  ///
  /// In en, this message translates to:
  /// **'Percussion (3-line)'**
  String get profilePercussion3Title;

  /// No description provided for @profilePercussion3Desc.
  ///
  /// In en, this message translates to:
  /// **'3-line staff for multiple unpitched percussion instruments.'**
  String get profilePercussion3Desc;

  /// No description provided for @profileBlankTitle.
  ///
  /// In en, this message translates to:
  /// **'Blank'**
  String get profileBlankTitle;

  /// No description provided for @profileBlankDesc.
  ///
  /// In en, this message translates to:
  /// **'Anonymous 5-line staff, no clef.'**
  String get profileBlankDesc;

  /// No description provided for @presetJumbo.
  ///
  /// In en, this message translates to:
  /// **'Jumbo (12.0 mm)'**
  String get presetJumbo;

  /// No description provided for @presetLarge.
  ///
  /// In en, this message translates to:
  /// **'Large (8.5 mm)'**
  String get presetLarge;

  /// No description provided for @presetMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium (7.2 mm)'**
  String get presetMedium;

  /// No description provided for @presetSmall.
  ///
  /// In en, this message translates to:
  /// **'Small (5.8 mm)'**
  String get presetSmall;

  /// No description provided for @presetCustomSize.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get presetCustomSize;

  /// No description provided for @selectStaffSizePreset.
  ///
  /// In en, this message translates to:
  /// **'Select Staff Size Preset'**
  String get selectStaffSizePreset;

  /// No description provided for @staffHeightReadout.
  ///
  /// In en, this message translates to:
  /// **'mm staff height'**
  String get staffHeightReadout;

  /// No description provided for @lineGapReadout.
  ///
  /// In en, this message translates to:
  /// **'mm line gap'**
  String get lineGapReadout;

  /// No description provided for @pinDetails.
  ///
  /// In en, this message translates to:
  /// **'Pin Details'**
  String get pinDetails;

  /// No description provided for @hideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide Details'**
  String get hideDetails;

  /// No description provided for @molaEducationalTitle.
  ///
  /// In en, this message translates to:
  /// **'Educational Standard'**
  String get molaEducationalTitle;

  /// No description provided for @molaEducationalDesc.
  ///
  /// In en, this message translates to:
  /// **'Large-scale staff for beginners and children. Ensures high legibility for educational materials and teaching pieces.'**
  String get molaEducationalDesc;

  /// No description provided for @molaOptimalTitle.
  ///
  /// In en, this message translates to:
  /// **'MOLA Optimal Part (8.5mm)'**
  String get molaOptimalTitle;

  /// No description provided for @molaOptimalDesc.
  ///
  /// In en, this message translates to:
  /// **'The gold standard for orchestral parts. Highly recommended by Major Orchestra Librarians for maximum readability on a music stand.'**
  String get molaOptimalDesc;

  /// No description provided for @molaMinimumTitle.
  ///
  /// In en, this message translates to:
  /// **'MOLA Minimum Part (7.0mm)'**
  String get molaMinimumTitle;

  /// No description provided for @molaMinimumDesc.
  ///
  /// In en, this message translates to:
  /// **'The acceptable minimum for orchestral players. Anything smaller is considered unacceptable by professional standards for parts.'**
  String get molaMinimumDesc;

  /// No description provided for @molaStudyTitle.
  ///
  /// In en, this message translates to:
  /// **'Study & Score Scale'**
  String get molaStudyTitle;

  /// No description provided for @molaStudyDesc.
  ///
  /// In en, this message translates to:
  /// **'Legible for printed study scores and piano music. Below the 7.0mm limit, these are not suitable for professional orchestral parts.'**
  String get molaStudyDesc;

  /// No description provided for @molaTechnicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical Miniature'**
  String get molaTechnicalTitle;

  /// No description provided for @molaTechnicalDesc.
  ///
  /// In en, this message translates to:
  /// **'Below the legible score limit (4.0mm). Suitable only for pocket scores or specific technical diagrams, not for performance.'**
  String get molaTechnicalDesc;

  /// No description provided for @staffSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Staff Size'**
  String get staffSizeLabel;

  /// No description provided for @stringSpacingLabel.
  ///
  /// In en, this message translates to:
  /// **'String Spacing'**
  String get stringSpacingLabel;

  /// No description provided for @systemGapLabel.
  ///
  /// In en, this message translates to:
  /// **'System Gap'**
  String get systemGapLabel;

  /// No description provided for @interStaffGapLabel.
  ///
  /// In en, this message translates to:
  /// **'Inter-staff Gap'**
  String get interStaffGapLabel;

  /// No description provided for @tabDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Tab Distance'**
  String get tabDistanceLabel;

  /// No description provided for @molaTooltipMessage.
  ///
  /// In en, this message translates to:
  /// **'MOLA (Major Orchestra Librarians\' Association) is the global benchmark for professional music manuscript. Their standards ensure that notation remains perfectly legible for orchestral players from a music stand distance, even under challenging stage lighting conditions.'**
  String get molaTooltipMessage;

  /// No description provided for @configureStaffSettings.
  ///
  /// In en, this message translates to:
  /// **'Configure Staff Settings'**
  String get configureStaffSettings;

  /// No description provided for @tabLabeling.
  ///
  /// In en, this message translates to:
  /// **'Labeling'**
  String get tabLabeling;

  /// No description provided for @tabClefLines.
  ///
  /// In en, this message translates to:
  /// **'Clef & Lines'**
  String get tabClefLines;

  /// No description provided for @tabFineTuning.
  ///
  /// In en, this message translates to:
  /// **'Fine-Tuning'**
  String get tabFineTuning;

  /// No description provided for @applyChanges.
  ///
  /// In en, this message translates to:
  /// **'Apply Changes'**
  String get applyChanges;

  /// No description provided for @defaultInstrumentName.
  ///
  /// In en, this message translates to:
  /// **'Instrument'**
  String get defaultInstrumentName;

  /// No description provided for @quickInstrumentPresets.
  ///
  /// In en, this message translates to:
  /// **'Quick Instrument Presets'**
  String get quickInstrumentPresets;

  /// No description provided for @selectFamilyPresetDesc.
  ///
  /// In en, this message translates to:
  /// **'Select a family to pick an orchestral instrument preset'**
  String get selectFamilyPresetDesc;

  /// No description provided for @showLabelOnCanvas.
  ///
  /// In en, this message translates to:
  /// **'Show Label on Canvas'**
  String get showLabelOnCanvas;

  /// No description provided for @showLabelOnCanvasDesc.
  ///
  /// In en, this message translates to:
  /// **'Toggle visibility of instrument name on score margins'**
  String get showLabelOnCanvasDesc;

  /// No description provided for @instrumentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Instrument Name'**
  String get instrumentNameLabel;

  /// No description provided for @instrumentNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Violin I, Cello...'**
  String get instrumentNameHint;

  /// No description provided for @abbreviationLabel.
  ///
  /// In en, this message translates to:
  /// **'Abbreviation'**
  String get abbreviationLabel;

  /// No description provided for @abbreviationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Vln. I, Vc.'**
  String get abbreviationHint;

  /// No description provided for @familyWoodwinds.
  ///
  /// In en, this message translates to:
  /// **'Woodwinds'**
  String get familyWoodwinds;

  /// No description provided for @familyBrass.
  ///
  /// In en, this message translates to:
  /// **'Brass'**
  String get familyBrass;

  /// No description provided for @familyPercussion.
  ///
  /// In en, this message translates to:
  /// **'Percussion'**
  String get familyPercussion;

  /// No description provided for @familyStrings.
  ///
  /// In en, this message translates to:
  /// **'Strings'**
  String get familyStrings;

  /// No description provided for @familyKeyboardPlucked.
  ///
  /// In en, this message translates to:
  /// **'Keyboard & Plucked'**
  String get familyKeyboardPlucked;

  /// No description provided for @clefSettingsHeader.
  ///
  /// In en, this message translates to:
  /// **'Clef Settings'**
  String get clefSettingsHeader;

  /// No description provided for @clefTrebleTitle.
  ///
  /// In en, this message translates to:
  /// **'Treble Clef (G-Clef)'**
  String get clefTrebleTitle;

  /// No description provided for @clefTrebleDesc.
  ///
  /// In en, this message translates to:
  /// **'For high-register instruments (Violin, Flute, Oboe, Soprano, Piano RH). Anchors G4 on Line 2.'**
  String get clefTrebleDesc;

  /// No description provided for @clefMovableCTitle.
  ///
  /// In en, this message translates to:
  /// **'Movable C-Clef'**
  String get clefMovableCTitle;

  /// No description provided for @clefMovableCDesc.
  ///
  /// In en, this message translates to:
  /// **'For mid-register instruments. Placed on Line 3 for Viola (Alto) or Line 4 for Tenor Cello/Trombone. Anchors C4.'**
  String get clefMovableCDesc;

  /// No description provided for @clefBassTitle.
  ///
  /// In en, this message translates to:
  /// **'Bass Clef (F-Clef)'**
  String get clefBassTitle;

  /// No description provided for @clefBassDesc.
  ///
  /// In en, this message translates to:
  /// **'For low-register instruments (Cello, Bassoon, Trombone, Tuba, Double Bass, Piano LH). Anchors F3 on Line 4.'**
  String get clefBassDesc;

  /// No description provided for @clefTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Tablature (TAB)'**
  String get clefTabTitle;

  /// No description provided for @clefTabDesc.
  ///
  /// In en, this message translates to:
  /// **'For fretted string instruments (Guitar, Bass). Staff lines represent strings, and numbers represent fret positions.'**
  String get clefTabDesc;

  /// No description provided for @clefPercussionTitle.
  ///
  /// In en, this message translates to:
  /// **'Percussion Clef (Neutral)'**
  String get clefPercussionTitle;

  /// No description provided for @clefPercussionDesc.
  ///
  /// In en, this message translates to:
  /// **'For non-pitched rhythm instruments (Snare Drum, Bass Drum, Cymbals, Triangle). Focuses purely on rhythm.'**
  String get clefPercussionDesc;

  /// No description provided for @clefPresetRegisterHeader.
  ///
  /// In en, this message translates to:
  /// **'Clef Preset / Register'**
  String get clefPresetRegisterHeader;

  /// No description provided for @clefAnchorLineHeader.
  ///
  /// In en, this message translates to:
  /// **'Clef Anchor Line'**
  String get clefAnchorLineHeader;

  /// No description provided for @clefAnchorLineDesc.
  ///
  /// In en, this message translates to:
  /// **'Sets which staff line the clef anchors to'**
  String get clefAnchorLineDesc;

  /// No description provided for @clefAnchorLineReadout.
  ///
  /// In en, this message translates to:
  /// **'Line {line}'**
  String clefAnchorLineReadout(int line);

  /// No description provided for @clefAnchorTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: You can also tap directly on any line in the visual preview above to snap the clef to that line!'**
  String get clefAnchorTip;

  /// No description provided for @numberOfStaffLinesHeader.
  ///
  /// In en, this message translates to:
  /// **'Number of Staff Lines'**
  String get numberOfStaffLinesHeader;

  /// No description provided for @numberOfStaffLinesDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard is 5 lines (TAB is 6, percussion varies)'**
  String get numberOfStaffLinesDesc;

  /// No description provided for @numberOfLinesReadout.
  ///
  /// In en, this message translates to:
  /// **'{count} Lines'**
  String numberOfLinesReadout(int count);

  /// No description provided for @lineCountLockedNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Line count is locked for the selected specialized clef.'**
  String get lineCountLockedNote;

  /// No description provided for @typographyStylingHeader.
  ///
  /// In en, this message translates to:
  /// **'Typography & Styling'**
  String get typographyStylingHeader;

  /// No description provided for @fontSerifTitle.
  ///
  /// In en, this message translates to:
  /// **'Classic Serif'**
  String get fontSerifTitle;

  /// No description provided for @fontSansTitle.
  ///
  /// In en, this message translates to:
  /// **'Modern Sans'**
  String get fontSansTitle;

  /// No description provided for @labelFontSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Label Font Size'**
  String get labelFontSizeLabel;

  /// No description provided for @italicizeLabelHeader.
  ///
  /// In en, this message translates to:
  /// **'Italicize Label'**
  String get italicizeLabelHeader;

  /// No description provided for @italicizeLabelDesc.
  ///
  /// In en, this message translates to:
  /// **'Use standard italics for score titles'**
  String get italicizeLabelDesc;

  /// No description provided for @alignmentOffsetsHeader.
  ///
  /// In en, this message translates to:
  /// **'Fine Alignment & Offsets'**
  String get alignmentOffsetsHeader;

  /// No description provided for @horizontalOffsetLabel.
  ///
  /// In en, this message translates to:
  /// **'Horizontal Offset'**
  String get horizontalOffsetLabel;

  /// No description provided for @verticalOffsetLabel.
  ///
  /// In en, this message translates to:
  /// **'Vertical Offset'**
  String get verticalOffsetLabel;

  /// No description provided for @livePreviewTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Changes are instantly previewed in the live staff above.'**
  String get livePreviewTip;

  /// No description provided for @exportManuscriptTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Manuscript'**
  String get exportManuscriptTitle;

  /// No description provided for @exportManuscriptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure file format, page count, and layer options.'**
  String get exportManuscriptSubtitle;

  /// No description provided for @outputFilenameLabel.
  ///
  /// In en, this message translates to:
  /// **'Output Filename'**
  String get outputFilenameLabel;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// No description provided for @filenameHint.
  ///
  /// In en, this message translates to:
  /// **'Manuscript filename...'**
  String get filenameHint;

  /// No description provided for @formatSelectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Format Selection'**
  String get formatSelectionLabel;

  /// No description provided for @formatPdfDesc.
  ///
  /// In en, this message translates to:
  /// **'Printable sheet music PDF.'**
  String get formatPdfDesc;

  /// No description provided for @formatSvgDesc.
  ///
  /// In en, this message translates to:
  /// **'Editable vector paths.'**
  String get formatSvgDesc;

  /// No description provided for @formatTexDesc.
  ///
  /// In en, this message translates to:
  /// **'pdfliteral LaTeX code.'**
  String get formatTexDesc;

  /// No description provided for @numberOfPagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Pages'**
  String get numberOfPagesLabel;

  /// No description provided for @presetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Presets: '**
  String get presetsLabel;

  /// No description provided for @pageCountSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count} pgs'**
  String pageCountSuffix(int count);

  /// No description provided for @svgLayerOrganizationLabel.
  ///
  /// In en, this message translates to:
  /// **'SVG Layer Organization'**
  String get svgLayerOrganizationLabel;

  /// No description provided for @svgCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Category Layers (Page-Wide)'**
  String get svgCategoryTitle;

  /// No description provided for @svgCategoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Groups elements by type (Staff Lines, Clefs, Barlines, Notes).\nBest for changing colors or line weights globally in Illustrator / Figma.'**
  String get svgCategoryDesc;

  /// No description provided for @svgSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'System & Staff Layers (Hierarchical)'**
  String get svgSystemTitle;

  /// No description provided for @svgSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Groups elements by System (System 1, System 2...).\nBest for selecting, moving, or re-ordering whole staff systems with one click.'**
  String get svgSystemDesc;

  /// No description provided for @svgMinimalTitle.
  ///
  /// In en, this message translates to:
  /// **'Minimal (Raw Vector Paths)'**
  String get svgMinimalTitle;

  /// No description provided for @svgMinimalDesc.
  ///
  /// In en, this message translates to:
  /// **'Clean, un-grouped vector paths without layer tags.\nBest for embedding directly into websites or mobile applications.'**
  String get svgMinimalDesc;

  /// No description provided for @browserDownloads.
  ///
  /// In en, this message translates to:
  /// **'Browser Downloads'**
  String get browserDownloads;

  /// No description provided for @changeOutputDir.
  ///
  /// In en, this message translates to:
  /// **'Change...'**
  String get changeOutputDir;

  /// No description provided for @savedBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved {fileName}'**
  String savedBannerTitle(String fileName);

  /// No description provided for @savedBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Size: {size} • Time: {time}ms'**
  String savedBannerSubtitle(String size, int time);

  /// No description provided for @copyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy Path'**
  String get copyPath;

  /// No description provided for @pathCopiedToast.
  ///
  /// In en, this message translates to:
  /// **'File path copied to clipboard!'**
  String get pathCopiedToast;

  /// No description provided for @exportingState.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get exportingState;

  /// No description provided for @exportButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Export {format}'**
  String exportButtonLabel(String format);

  /// No description provided for @exportButtonWithPagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Export {format} ({pages} Pages)'**
  String exportButtonWithPagesLabel(String format, int pages);

  /// No description provided for @displayCalibrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Display Calibration'**
  String get displayCalibrationTitle;

  /// No description provided for @displayCalibrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calibrate \"Actual Size\" to your physical display.'**
  String get displayCalibrationSubtitle;

  /// No description provided for @calibrationStep1.
  ///
  /// In en, this message translates to:
  /// **'Hold a physical ruler flat against your screen.'**
  String get calibrationStep1;

  /// No description provided for @calibrationStep2.
  ///
  /// In en, this message translates to:
  /// **'Use the slider or buttons to nudge the bar until it spans exactly 50 mm on your ruler.'**
  String get calibrationStep2;

  /// No description provided for @calibrationStep3.
  ///
  /// In en, this message translates to:
  /// **'Click Apply. Done.'**
  String get calibrationStep3;

  /// No description provided for @baseline96Dpi.
  ///
  /// In en, this message translates to:
  /// **'baseline (96 DPI)'**
  String get baseline96Dpi;

  /// No description provided for @physicalDensity.
  ///
  /// In en, this message translates to:
  /// **'physical density'**
  String get physicalDensity;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
