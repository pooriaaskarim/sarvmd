# واژه‌نامه و اصطلاحات تخصصی سرو (SarvMD Bilingual Terminology)

This document serves as the official bilingual glossary and translation reference for the SarvMD project. It ensures absolute linguistic consistency across Persian and English documentation, source code comments, CLI outputs, and UI localizations.

---

## ۱. معماری نرم‌افزار و هسته فنی (Software Architecture & Pipeline)

| English Term | معادل فنی/فارسی (برنامه‌نویسان) | Definition & Context / تعریف و کاربرد |
| :--- | :--- | :--- |
| **Pipeline** | Pipeline (پایپ‌لاین) | The sequence of data stages (`Config` $\rightarrow$ `Layout` $\rightarrow$ `Emitter` $\rightarrow$ `Compiler`) that renders the manuscript. |
| **Single Source of Truth** | Single Source of Truth (SSoT) | An architectural design pattern where core logic is stored in a single library (`sarvmd_core`) and shared across all apps. |
| **Workspace (Monorepo)** | Monorepo (مونو-ریپو) | A repository structure containing multiple independent packages or apps (`sarvmd_core`, `sarvmd_ui`, `sarvmd_cli`). |
| **Zero-Dependency Core** | Zero-Dependency | Writing the core layout engine relying entirely on pure Dart APIs, ensuring maximum long-term build stability. |
| **State Decoupling** | State Decoupling (دکوپلاژ وضعیت) | Separating configuration data (`ConfigNotifier`) from viewport zoom states (`ViewNotifier`) to prevent redundant rebuilds. |
| **Dual-Notifier System** | الگوی Dual-Notifier | A reactive design pattern managing sheet layout properties and user camera positions independently. |
| **Zero-Rebuild Input** | Zero-Rebuild Input | UI optimization preventing expensive canvas redraws while the user actively types text (such as staff labels). |
| **Stable UID-based Identity** | هویت‌دهی پایدار مبتنی بر UID | Using unique identifiers rather than array indices to identify staves, preventing focus loss during drag-and-drop actions. |
| **Binary IR (B-IR)** | Binary IR (B-IR) | An intermediate binary representation optimized for rapid layout serialization and network/IPC streaming. |
| **Headless Workflow** | Headless workflow / تحت خط فرمان | Running automated batch manuscript compiling from the command-line interface without launching a window. |

---

## ۲. صفحه‌آرایی نت و استانداردهای پارتیتور (Music Engraving & Scoring)

| English Term | معادل فارسی | Definition & Context / تعریف و کاربرد |
| :--- | :--- | :--- |
| **Music Engraving** | صفحه‌آرایی نت / برگه‌آرایی موسیقی | The professional process of preparing high-quality, readable sheet music for publishing (analogous to typography/layout for text). |
| **Engraving Standards** | استانداردهای صفحه‌آرایی نت | Strict rules governing page margins, line weights, and spacing ratios to guarantee professional, legible layout outputs. |
| **MOLA-compliant Preset** | پیش‌فرض منطبق با استاندارد MOLA | Layout parameters designed in accordance with the Music Publishers Association guidelines for blank canvas systems. |
| **Manuscript Paper** | کاغذ دست‌نویس نت / کاغذ موسیقی | Blank staff paper used by composers to write down musical notations by hand. |
| **Staff / Staves** | خط حامل / خطوط حامل | The five horizontal lines upon which musical notes are written (originally derived from French *portée*). |
| **Clef (G, F, C)** | کلید موسیقی (سل، فا، دو) | The symbol placed at the beginning of a staff to determine the pitch of the notes (derived from French *clef*). |
| **SystemLayout** | چیدمان سیستم‌های حامل (سیستم) | A collection of staves played simultaneously by different instruments, grouped vertically (e.g., an orchestral system score). |
| **Orchestral Family** | خانواده سازهای ارکستر | Vertical groupings (Woodwinds, Brass, Percussion, Strings) that dictate the rendering order in a system layout. |
| **Brace / Bracket** | آکولاد / براکت | Vertical grouping brackets used to connect multiple staves in a system layout (derived from French *accolade*). |
| **Score (Partition)** | پارتیتور ارکستر / پارتیتور کامل | The master sheet music containing all instrumental parts of an ensemble aligned vertically (derived from French *partition*). |
| **Staff Spacing / Padding** | فاصله‌گذاری و حاشیه خطوط حامل | The calculated vertical distance between neighboring staves or systems to prevent collisions of musical notations. |

---

## ۳. بوم ترسیم تعاملی و هندسه رابط کاربری (Interactive Canvas & UI Geometry)

| English Term | معادل فنی/فارسی (برنامه‌نویسان) | Definition & Context / تعریف و کاربرد |
| :--- | :--- | :--- |
| **Blank Canvas** | Blank Canvas / بوم ساده | The minimalist, distraction-free environment in `sarvmd_ui` optimized for editing musical configurations. |
| **Actual Size** | Actual Size (ابعاد فیزیکی واقعی) | Rendering the digital paper on screen so that its measured centimeters exactly match those of physical paper. |
| **Display Calibration** | Display Calibration (کالیبراسیون مانیتور) | Programmatic adjustment of screen pixels to match real-world physical metrics by calculating monitor density. |
| **Physical PPI auto-detection** | تشخیص خودکار PPI واقعی | Executing low-level shell utilities across OS terminals to retrieve exact hardware monitor specifications. |
| **Ruler Precision** | Ruler Precision (دقت خط‌کش) | The ruler overlay on the canvas edges showing precise millimeter alignments reacting dynamically to zoom. |
| **Coordinate Drift** | Coordinate Drift (انحراف مختصاتی) | A geometric error where canvas and ruler alignments desynchronize during aggressive zooms or orientation flips. |
| **Transformation Matrix** | Transformation Matrix (ماتریس تبدیل هندسی) | The algebraic matrix calculating translation, zoom, and orientation offsets for vector graphics. |
| **InteractiveViewer** | InteractiveViewer / Viewport | The Flutter rendering component enabling smooth pan (movement) and pinch-zoom gestures across the manuscript page. |
| **CustomPainter** | CustomPainter | Flutter's low-level drawing class used to render custom vector shapes, Bézier lines, and staves with high efficiency. |
| **Bézier Path** | Bézier Path (مسیر بزیه) | Parametric curves defined by anchor points used to draw scalable vector graphics like clef symbols and آکولاد brackets. |
| **Mouse Wings** | Mouse Wings / نشانگر صلیبی تراز | Visual crosshairs following the cursor in real-time to facilitate precise alignment of manuscript staves. |
| **LiveStaffPreview** | LiveStaffPreview | An interactive widget in the config dialog (e.g., 380x140px) showing real-time changes in clefs and line weights. |
| **CAD Targets** | CAD Targets / نشانه‌های تراز هندسی | Precision concentric target circles indicating anchor points for alignment and visual calibration in preview cards. |
| **Effective Width / Height** | Effective Width / Height (ابعاد مفید کاغذ) | The printable workspace dimensions of the sheet page after subtracting top, bottom, left, and right margins. |

---

## ۴. پروانه حقوقی و مشارکت متن‌باز (Licensing & Contributing)

| English Term | معادل فنی/فارسی (برنامه‌نویسان) | Definition & Context / تعریف و کاربرد |
| :--- | :--- | :--- |
| **Business Source License (BUSL)** | لایسنس BUSL-1.1 | A source-available license that grants free non-commercial rights but restricts commercial usage to protect developer sales. |
| **Change Date** | Change Date (تاریخ انتقال لایسنس) | The pre-defined future date (June, 2031) at which the BUSL license automatically transitions to a permissive Apache 2.0 license. |
| **DCO (Developer Certificate of Origin)** | گواهی اصالت توسعه‌دهنده (DCO) | A legal agreement signed by contributors to certify they have the right to submit and license their contributions. |
| **Sign-off (git commit -s)** | Sign-off (امضای دیجیتال کامیت) | Appending `Signed-off-by: Name <email>` to commit messages to legally verify compliance with the DCO. |
| **Non-Commercial Use** | Non-Commercial Use (کاربردهای غیرتجاری) | Copying, studying, or executing software for personal, academic, or testing workflows without fees or restrictions. |
| **Commercial Production Use** | Commercial Production Use (بهره‌برداری تجاری) | Running the software in active corporate production environments, SaaS, or embedding its engines in proprietary products. |
| **Git Flow** | الگوی شاخه‌دهی Git Flow | A branching model for Git centering on persistent master and dev branches, and temporary feature, bugfix, release, and hotfix branches. |
| **Conventional Commits** | کامیت‌های استاندارد (Conventional Commits) | A specification for adding human and machine readable meaning to commit messages (e.g., feat, fix, docs). |
