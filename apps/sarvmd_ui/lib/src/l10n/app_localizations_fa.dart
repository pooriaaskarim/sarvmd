// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'سرو';

  @override
  String get appSubtitle => 'طراح برگه نت';

  @override
  String get language => 'زبان';

  @override
  String get persian => 'فارسی';

  @override
  String get english => 'English';

  @override
  String get actualSize => 'ابعاد فیزیکی واقعی';

  @override
  String get zoomIn => 'افزایش زوم';

  @override
  String get zoomOut => 'کاهش زوم';

  @override
  String get resetZoom => 'بازنشانی زوم';

  @override
  String get exportPdf => 'خروجی PDF';

  @override
  String get saveConfig => 'ذخیره تنظیمات';

  @override
  String get loadPreset => 'بارگیری پیش‌فرض';

  @override
  String get presetSoloStaff => 'تک‌حامل ساده';

  @override
  String get presetPianoScore => 'آکولاد پیانو';

  @override
  String get presetOrchestralScore => 'پارتیتور ارکستر';

  @override
  String get presetStringQuartet => 'کوارتر زهی';

  @override
  String get presetChoirSATB => 'گروه کر (SATB)';

  @override
  String get presetLeadSheet => 'برگه نت اصلی';

  @override
  String get presetCustom => 'سفارشی';

  @override
  String get pageSettings => 'تنظیمات برگه';

  @override
  String get staffSettings => 'تنظیمات خطوط حامل';

  @override
  String get systemSettings => 'چیدمان سیستم‌ها';

  @override
  String get clefSelection => 'کلید موسیقی';

  @override
  String get lineWeight => 'ضخامت خطوط';

  @override
  String get margins => 'حاشیه‌ها (mm)';

  @override
  String get marginsLabel => 'حاشیه‌ها';

  @override
  String get systemIndentation => 'تورفتگی سیستم';

  @override
  String get mouseWings => 'خطوط راهنمای موس';

  @override
  String get cadTargets => 'نشانه‌های تراز هندسی';

  @override
  String get toggleTheme => 'تغییر تم';

  @override
  String get toggleLanguage => 'تغییر زبان';

  @override
  String get pdfExportSuccess => 'فایل PDF با موفقیت کامپایل شد.';

  @override
  String get pdfExportError =>
      'خطا در کامپایل PDF. لطفاً از نصب بودن pdflatex مطمئن شوید.';

  @override
  String get profiles => 'پروفایل‌ها';

  @override
  String get document => 'سند';

  @override
  String get staffSpacing => 'فاصله خطوط حامل';

  @override
  String systemsCount(int count) {
    return '$count سیستم';
  }

  @override
  String get reset => 'بازنشانی';

  @override
  String get resetAllSettings => 'بازنشانی تمامی تنظیمات به پیش‌فرض';

  @override
  String get view => 'نمایش';

  @override
  String get appearance => 'تنظیمات ظاهری';

  @override
  String get zoom => 'زوم';

  @override
  String get guides => 'راهنماها';

  @override
  String get paperEdges => 'لبه‌های کاغذ';

  @override
  String get paperCenters => 'مرکز کاغذ';

  @override
  String get documentMargins => 'حاشیه‌های سند';

  @override
  String get staffBounds => 'محدوده حامل‌ها';

  @override
  String get export => 'خروجی';

  @override
  String get portrait => 'عمودی';

  @override
  String get landscape => 'افقی';

  @override
  String get vertical => 'عمودی';

  @override
  String get horizontal => 'افقی';

  @override
  String get top => 'بالا';

  @override
  String get bottom => 'پایین';

  @override
  String get left => 'چپ';

  @override
  String get right => 'راست';

  @override
  String get marginsLinked => 'حاشیه‌های متصل';

  @override
  String get marginsIndependent => 'حاشیه‌های مستقل';

  @override
  String get lineGap => 'فاصله خطوط';

  @override
  String get systemGap => 'فاصله سیستم‌ها';

  @override
  String get interStaffGap => 'فاصله میان‌حاملی';

  @override
  String get aboutSarvMD => 'درباره سرو';

  @override
  String get versionInfo => 'اطلاعات نسخه';

  @override
  String get masterExportStudio => 'استودیوی خروجی';

  @override
  String get exportFormat => 'قالب خروجی';

  @override
  String get resolutionDpi => 'رزولوشن (DPI)';

  @override
  String get scaleFactor => 'ضریب مقیاس';

  @override
  String get cancel => 'لغو';

  @override
  String get done => 'تأیید';

  @override
  String get close => 'بستن';

  @override
  String get save => 'ذخیره';

  @override
  String get calibration => 'کالیبراسیون';

  @override
  String get paperCalibration => 'کالیبراسیون کاغذ';

  @override
  String get measuredWidth => 'عرض اندازه‌گیری شده';

  @override
  String get measuredHeight => 'ارتفاع اندازه‌گیری شده';

  @override
  String get darkMode => 'تاریک';

  @override
  String get lightMode => 'روشن';

  @override
  String get systemTheme => 'سیستم';

  @override
  String get accentColor => 'رنگ برجسته';

  @override
  String get gold => 'طلایی';

  @override
  String get emerald => 'زمردی';

  @override
  String get sapphire => 'یاقوتی';

  @override
  String get amethyst => 'جمشیدی';

  @override
  String get amber => 'کهربایی';

  @override
  String get crimson => 'سرخ';

  @override
  String get systemHierarchy => 'سلسله‌مراتب سیستم و کلیدها';

  @override
  String get addSystem => 'افزودن سیستم';

  @override
  String get deleteSystem => 'حذف سیستم';

  @override
  String get moveUp => 'انتقال به بالا';

  @override
  String get moveDown => 'انتقال به پایین';

  @override
  String get trebleClef => 'کلید سل';

  @override
  String get bassClef => 'کلید فا';

  @override
  String get altoClef => 'کلید دو (آلتو)';

  @override
  String get tenorClef => 'کلید دو (تنور)';

  @override
  String get percussionClef => 'کلید کوبه‌ای';

  @override
  String get neutralClef => 'کلید خنثی';

  @override
  String get categoryAll => 'همه';

  @override
  String get categoryStandard => 'استاندارد';

  @override
  String get categoryEnsemble => 'آنسامبل';

  @override
  String get categoryTablature => 'تبلچر';

  @override
  String get categoryPercussion => 'کوبه‌ای';

  @override
  String get categoryOther => 'سایر';

  @override
  String get addStaff => 'افزودن حامل';

  @override
  String get ensembleSummary => 'خلاصه آنسامبل';

  @override
  String get totalStaves => 'مجموع حامل‌ها';

  @override
  String get systemHeight => 'ارتفاع سیستم';

  @override
  String get density => 'تراکم';

  @override
  String get mainEnsemble => 'آنسامبل اصلی';

  @override
  String get subGroup => 'زیرگروه';

  @override
  String get continuousBarlines => 'خطوط میزان پیوسته';

  @override
  String get profilePianoTitle => 'پیانو';

  @override
  String get profilePianoDesc =>
      'حامل دوگانه (آکولاد) کلید سل و فا برای پیانو یا کیبورد.';

  @override
  String get profileTrebleTitle => 'کلید سل';

  @override
  String get profileTrebleDesc => 'کلید سل استاندارد — ویولن، فلوت، سوپرانو.';

  @override
  String get profileBassTitle => 'کلید فا';

  @override
  String get profileBassDesc => 'کلید فا استاندارد — ویولنسل، بیس، توبا.';

  @override
  String get profileAltoTitle => 'آلتو';

  @override
  String get profileAltoDesc => 'کلید دو روی خط سوم — ویولا.';

  @override
  String get profileTenorTitle => 'تنور';

  @override
  String get profileTenorDesc => 'کلید دو روی خط چهارم — فاگوت، ترومبون.';

  @override
  String get profileStringQuartetTitle => 'کوارتر زهی';

  @override
  String get profileStringQuartetDesc =>
      'پارتیتور چهارحاملی: ویولن ۱، ویولن ۲، ویولا، ویولنسل.';

  @override
  String get profileChoirSATBTitle => 'گروه کر (SATB)';

  @override
  String get profileChoirSATBDesc =>
      'چهار حامل مجزا برای سوپرانو، آلتو، تنور، بیس.';

  @override
  String get profileLeadSheetTitle => 'برگه نت اصلی';

  @override
  String get profileLeadSheetDesc =>
      'تک‌حامل به همراه فواصل آکورد و متن ترانه.';

  @override
  String get profileGuitarTabTitle => 'تبلچر گیتار';

  @override
  String get profileGuitarTabDesc => 'تبلچر ۶ خطی استاندارد برای گیتار.';

  @override
  String get profileGuitarGrandTitle => 'گیتار + تبلچر';

  @override
  String get profileGuitarGrandDesc =>
      'حامل سل استاندارد به همراه تبلچر ۶ خطی گیتار.';

  @override
  String get profileBassTabTitle => 'تبلچر بیس';

  @override
  String get profileBassTabDesc => 'تبلچر ۴ خطی استاندارد برای گیتار بیس.';

  @override
  String get profileBanjoTabTitle => 'تبلچر بنجو';

  @override
  String get profileBanjoTabDesc => 'تبلچر ۵ خطی استاندارد برای بنجوی ۵ سیم.';

  @override
  String get profileDrumKitTitle => 'کیت درامز';

  @override
  String get profileDrumKitDesc => 'حامل ۵ خطی پرکاشن برای درامز.';

  @override
  String get profilePercussion1Title => 'کوبه‌ای (تک‌خط)';

  @override
  String get profilePercussion1Desc => 'تک‌خط برای سازهای کوبه‌ای بدون کوک.';

  @override
  String get profilePercussion3Title => 'کوبه‌ای (۳ خط)';

  @override
  String get profilePercussion3Desc =>
      'حامل ۳ خطی برای چند ساز کوبه‌ای بدون کوک.';

  @override
  String get profileBlankTitle => 'خالی';

  @override
  String get profileBlankDesc => 'پنج‌خط حامل بدون کلید.';

  @override
  String get presetJumbo => 'خیلی بزرگ (12.0 mm)';

  @override
  String get presetLarge => 'بزرگ (8.5 mm)';

  @override
  String get presetMedium => 'متوسط (7.2 mm)';

  @override
  String get presetSmall => 'کوچک (5.8 mm)';

  @override
  String get presetCustomSize => 'سفارشی';

  @override
  String get selectStaffSizePreset => 'انتخاب اندازه پیش‌فرض حامل';

  @override
  String get staffHeightReadout => 'mm ارتفاع حامل';

  @override
  String get lineGapReadout => 'mm فاصله خطوط';

  @override
  String get pinDetails => 'سنجاق جزئیات';

  @override
  String get hideDetails => 'مخفی‌سازی جزئیات';

  @override
  String get molaEducationalTitle => 'استاندارد آموزشی';

  @override
  String get molaEducationalDesc =>
      'حامل‌های با ابعاد بزرگ مناسب برای هنرجویان تازه‌کار و کودکان. خوانایی بسیار بالا در متون آموزشی.';

  @override
  String get molaOptimalTitle => 'حالت ایده‌آل MOLA (8.5 mm)';

  @override
  String get molaOptimalDesc =>
      'استاندارد طلایی پارتیتورهای ارکستری. توصیه شده توسط انجمن کتابداران ارکسترهای بزرگ برای بیشترین خوانایی روی پوپیتر.';

  @override
  String get molaMinimumTitle => 'حداقل استاندارد MOLA (7.0 mm)';

  @override
  String get molaMinimumDesc =>
      'حداقل اندازه قابل قبول برای نوازندگان ارکستر. مقادیر کمتر از این طبق استانداردهای حرفه‌ای غیرمجاز است.';

  @override
  String get molaStudyTitle => 'مقیاس مطالعه و پیانو';

  @override
  String get molaStudyDesc =>
      'خوانا برای پارتیتورهای مطالعه و پیانو. مقادیر کمتر از 7.0 mm برای پارتیتورهای ارکستری مناسب نیستند.';

  @override
  String get molaTechnicalTitle => 'مینیاتور فنی';

  @override
  String get molaTechnicalDesc =>
      'کمتر از حد خوانایی (4.0 mm). فقط برای پارتیتورهای جیبی یا دیاگرام‌های فنی، نه اجرا.';

  @override
  String get staffSizeLabel => 'اندازه حامل';

  @override
  String get stringSpacingLabel => 'فاصله سیم‌ها';

  @override
  String get systemGapLabel => 'فاصله سیستم‌ها';

  @override
  String get interStaffGapLabel => 'فاصله میان‌حاملی';

  @override
  String get tabDistanceLabel => 'فاصله تبلچر';

  @override
  String get molaTooltipMessage =>
      'MOLA (انجمن کتابداران ارکسترهای بزرگ) مرجع جهانی استانداردهای پارتیتورهای موسیقی حرفه‌ای است. این استانداردها تضمین می‌کنند که نت‌ها از فاصله پوپیتر و زیر نور صحنه برای نوازندگان به طور کامل خوانا باشند.';

  @override
  String get configureStaffSettings => 'تنظیمات خط حامل';

  @override
  String get tabLabeling => 'نام‌گذاری و پیش‌فرض‌ها';

  @override
  String get tabClefLines => 'کلید و خطوط';

  @override
  String get tabFineTuning => 'تنظیمات دقیق';

  @override
  String get applyChanges => 'اعمال تغییرات';

  @override
  String get defaultInstrumentName => 'ساز';

  @override
  String get quickInstrumentPresets => 'پیش‌فرض‌های سریع سازها';

  @override
  String get selectFamilyPresetDesc =>
      'برای انتخاب پیش‌فرض ساز، یک خانواده ساز را انتخاب کنید';

  @override
  String get showLabelOnCanvas => 'نمایش نام ساز در صفحه';

  @override
  String get showLabelOnCanvasDesc =>
      'فعال/غیرفعال‌سازی نمایش نام ساز در حاشیه‌های کاغذ';

  @override
  String get instrumentNameLabel => 'نام کامل ساز';

  @override
  String get instrumentNameHint => 'مثال: ویولن ۱، ویولنسل...';

  @override
  String get abbreviationLabel => 'نام اختصاری';

  @override
  String get abbreviationHint => 'مثال: Vln. I, Vc.';

  @override
  String get familyWoodwinds => 'بادی چوبی';

  @override
  String get familyBrass => 'بادی برنجی';

  @override
  String get familyPercussion => 'کوبه‌ای';

  @override
  String get familyStrings => 'زهی';

  @override
  String get familyKeyboardPlucked => 'کیبورد و زخمه‌ای';

  @override
  String get clefSettingsHeader => 'تنظیمات کلید موسیقی';

  @override
  String get clefTrebleTitle => 'کلید سل (G)';

  @override
  String get clefTrebleDesc =>
      'برای سازهای با دامنه‌ی صوتی بالا (ویولن، فلوت، ابوا، سوپرانو، دست راست پیانو). تثبیت نغمه سل۴ روی خط دوم.';

  @override
  String get clefMovableCTitle => 'کلید دو متحرک (C)';

  @override
  String get clefMovableCDesc =>
      'برای سازهای دامنه‌ی میانی. واقع در خط سوم برای ویولا (آلتو) یا خط چهارم برای تنور (ویولنسل/ترومبون). تثبیت نغمه دو۴.';

  @override
  String get clefBassTitle => 'کلید فا (F)';

  @override
  String get clefBassDesc =>
      'برای سازهای با دامنه‌ی صوتی بم (ویولنسل، فاگوت، ترومبون، توبا، کنترباس، دست چپ پیانو). تثبیت نغمه فا۳ روی خط چهارم.';

  @override
  String get clefTabTitle => 'تبلچر (TAB)';

  @override
  String get clefTabDesc =>
      'برای سازهای زهی فرت‌دار (گیتار، بیس). خطوط حامل نشان‌دهنده سیم‌ها و اعداد نشان‌دهنده فرت‌ها هستند.';

  @override
  String get clefPercussionTitle => 'کلید کوبه‌ای (خنثی)';

  @override
  String get clefPercussionDesc =>
      'برای سازهای ریتمیک بدون کوک (اسنیر، طبل بزرگ، سنج، مثلث). تمرکز بر ریتم.';

  @override
  String get clefPresetRegisterHeader => 'پیش‌فرض کلید / منطقه صوتی';

  @override
  String get clefAnchorLineHeader => 'خط تثبیت کلید';

  @override
  String get clefAnchorLineDesc =>
      'تعیین خطی از حامل که مرکز کلید روی آن قرار می‌گیرد';

  @override
  String clefAnchorLineReadout(int line) {
    return 'خط $line';
  }

  @override
  String get clefAnchorTip =>
      'راهنما: می‌توانید مستقیماً روی هر خط در پیش‌نمایش بالا ضربه بزنید تا کلید روی همان خط تنظیم شود!';

  @override
  String get numberOfStaffLinesHeader => 'تعداد خطوط حامل';

  @override
  String get numberOfStaffLinesDesc =>
      'استاندارد ۵ خط است (تبلچر ۶ خط و پرکاشن متغیر است)';

  @override
  String numberOfLinesReadout(int count) {
    return '$count خط';
  }

  @override
  String get lineCountLockedNote =>
      'توجه: تعداد خطوط برای کلید تخصصی انتخاب‌شده قفل شده است.';

  @override
  String get typographyStylingHeader => 'تایپوگرافی و ظاهر نام';

  @override
  String get fontSerifTitle => 'کلاسیک (Serif)';

  @override
  String get fontSansTitle => 'مدرن (Sans)';

  @override
  String get labelFontSizeLabel => 'اندازه فونت نام';

  @override
  String get italicizeLabelHeader => 'مورب‌سازی (ایتالیک) نام';

  @override
  String get italicizeLabelDesc =>
      'استفاده از حالت ایتالیک استاندارد برای نام ساز';

  @override
  String get alignmentOffsetsHeader => 'تراز و جابه‌جایی‌های دقیق';

  @override
  String get horizontalOffsetLabel => 'جابه‌جایی افقی';

  @override
  String get verticalOffsetLabel => 'جابه‌جایی عمودی';

  @override
  String get livePreviewTip =>
      'راهنما: تغییرات بلافاصله در پیش‌نمایش زنده بالای دیالوگ اعمال می‌شوند.';

  @override
  String get exportManuscriptTitle => 'دریافت خروجی سند';

  @override
  String get exportManuscriptSubtitle =>
      'تنظیم قالب فایل، تعداد صفحات و لایه‌بندی.';

  @override
  String get outputFilenameLabel => 'نام فایل خروجی';

  @override
  String get resetToDefault => 'بازنشانی به پیش‌فرض';

  @override
  String get filenameHint => 'نام فایل نت...';

  @override
  String get formatSelectionLabel => 'انتخاب قالب فایل';

  @override
  String get formatPdfDesc => 'فایل PDF قابل چاپ نت.';

  @override
  String get formatSvgDesc => 'مسیرهای برداری قابل ویرایش.';

  @override
  String get formatTexDesc => 'کد LaTeX مستقیم.';

  @override
  String get numberOfPagesLabel => 'تعداد صفحات';

  @override
  String get presetsLabel => 'پیش‌فرض‌ها: ';

  @override
  String pageCountSuffix(int count) {
    return '$count صفحه';
  }

  @override
  String get svgLayerOrganizationLabel => 'سازمان‌دهی لایه‌های SVG';

  @override
  String get svgCategoryTitle => 'لایه‌بندی دسته‌ای (سراسری)';

  @override
  String get svgCategoryDesc =>
      'دسته‌بندی عناصر بر اساس نوع (خطوط حامل، کلیدها، خطوط میزان، نت‌ها).\nمناسب برای تغییر یکجای رنگ یا ضخامت خطوط در ایلوستریتور یا فیگما.';

  @override
  String get svgSystemTitle => 'لایه‌بندی سیستم و حامل (سلسله‌مراتب)';

  @override
  String get svgSystemDesc =>
      'دسته‌بندی عناصر بر اساس سیستم (سیستم ۱، سیستم ۲...).\nمناسب برای جابه‌جایی و انتخاب کامل یک سیستم با یک کلیک.';

  @override
  String get svgMinimalTitle => 'خام و مینیمال (بدون لایه)';

  @override
  String get svgMinimalDesc =>
      'مسیرهای برداری تمیز و بدون گروه.\nمناسب برای استفاده مستقیم در وب‌سایت‌ها یا برنامه‌های موبایل.';

  @override
  String get browserDownloads => 'دانلودهای مرورگر';

  @override
  String get changeOutputDir => 'تغییر مسیر...';

  @override
  String savedBannerTitle(String fileName) {
    return '$fileName ذخیره شد';
  }

  @override
  String savedBannerSubtitle(String size, int time) {
    return 'حجم: $size • زمان: $time ms';
  }

  @override
  String get copyPath => 'کپی مسیر';

  @override
  String get pathCopiedToast => 'مسیر فایل در حافظه کپی شد!';

  @override
  String get exportingState => 'در حال دریافت خروجی...';

  @override
  String exportButtonLabel(String format) {
    return 'دریافت خروجی $format';
  }

  @override
  String exportButtonWithPagesLabel(String format, int pages) {
    return 'دریافت خروجی $format ($pages صفحه)';
  }

  @override
  String get displayCalibrationTitle => 'کالیبراسیون صفحه نمایش';

  @override
  String get displayCalibrationSubtitle =>
      'کالیبره کردن اندازه واقعی روی نمایشگر فیزیکی شما.';

  @override
  String get calibrationStep1 => 'یک خط‌کش فیزیکی را روی صفحه نمایش بگذارید.';

  @override
  String get calibrationStep2 =>
      'با اسلایدر یا دکمه‌ها نوار را طوری تنظیم کنید که دقیقاً 50 mm روی خط‌کش شود.';

  @override
  String get calibrationStep3 => 'روی اعمال کلیک کنید. تمام.';

  @override
  String get baseline96Dpi => 'پایه (۹۶ DPI)';

  @override
  String get physicalDensity => 'تراکم فیزیکی';

  @override
  String get apply => 'اعمال';

  @override
  String get changingLanguage => 'در حال تغییر زبان...';

  @override
  String get continuousBarlinesTooltip => 'اتصال پیوسته خطوط میزان بین حامل‌ها';

  @override
  String staffNumber(int number) {
    return 'حامل $number';
  }

  @override
  String linesCount(int count) {
    return '$count خط';
  }

  @override
  String get noClef => 'بدون کلید';

  @override
  String clefWithLine(String clef, int line) {
    return '$clef (خط $line)';
  }

  @override
  String get hidden => 'مخفی';

  @override
  String get configureStaff => 'تنظیمات حامل';

  @override
  String get removeStaff => 'حذف حامل';

  @override
  String get connectorNone => 'بدون اتصال';

  @override
  String get connectorNoneTooltip => 'بدون خط اتصال';

  @override
  String get connectorBracket => 'قلاب';

  @override
  String get connectorBracketTooltip => 'خط اتصال قلاب (کروشه)';

  @override
  String get connectorBrace => 'آکولاد';

  @override
  String get connectorBraceTooltip => 'خط اتصال آکولاد';
}
