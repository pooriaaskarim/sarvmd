/// SVG emitter — generates a standalone `.svg` file representing the
/// manuscript layout.
///
/// Coordinates use millimetres; the SVG viewBox is set to the page dimensions
/// in mm so the file is scale-accurate at 1 mm = 1 user unit.

import 'config.dart';
import 'layout.dart';

String _f(double v) => v.toStringAsFixed(3);

/// Emit a complete standalone SVG string for the given config and layout.
String emitSvg(PageConfig config, PageLayout layout) {
  final buf = StringBuffer();
  final w = config.effectiveWidth;
  final h = config.effectiveHeight;

  buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buf.writeln(
    '<svg xmlns="http://www.w3.org/2000/svg"'
    ' viewBox="0 0 ${_f(w)} ${_f(h)}"'
    ' width="${_f(w)}mm" height="${_f(h)}mm">',
  );

  // White page background.
  buf.writeln('  <rect width="${_f(w)}" height="${_f(h)}" fill="white"/>');

  final gap = config.staffConfig.lineGapMm;
  final strokeMm = config.staffConfig.lineThicknessPt * 25.4 / 72.0;
  final leftX = config.margins.left;
  final rightX = w - config.margins.right;

  const clefFontSizeMultiplier = 4.0;

  buf.writeln('  <g stroke="black" stroke-width="${_f(strokeMm)}" fill="none">');

  for (final system in layout.systems) {
    for (var si = 0; si < system.staves.length; si++) {
      final staff = system.staves[si];
      final topY = staff.topY;
      for (var li = 0; li < 5; li++) {
        final y = topY + li * gap;
        buf.writeln(
          '    <line x1="${_f(leftX)}" y1="${_f(y)}"'
          ' x2="${_f(rightX)}" y2="${_f(y)}"/>',
        );
      }
    }

    // Barline connecting all staves in the system (Piano only, matching UI).
    if (config.layoutType == LayoutType.doubleLine) {
      final sysTopY = system.staves.first.topY;
      final sysBottomY =
          system.staves.last.topY + config.staffConfig.staffHeightMm;
      buf.writeln(
        '    <line x1="${_f(leftX)}" y1="${_f(sysTopY)}"'
        ' x2="${_f(leftX)}" y2="${_f(sysBottomY)}"'
        ' stroke-width="${_f(strokeMm * 2.5)}"/>',
      );
    }
  }
  buf.writeln('  </g>');

  for (final system in layout.systems) {
    for (var si = 0; si < system.staves.length; si++) {
      final staff = system.staves[si];
      final clef = (config.layoutType == LayoutType.doubleLine && si == 1)
          ? config.secondaryClef
          : config.primaryClef;

      if (clef == null) continue;

      final anchorY = staff.topY + (5 - clef.anchorLine) * gap;
      final anchorSp = switch (clef.symbol) {
        ClefSymbol.g => 0.876,
        ClefSymbol.c => 2.0,
        ClefSymbol.f => 2.578,
      };

      final microOffset = gap * 0.04;
      final baselineY = anchorY + anchorSp * gap + microOffset;
      final glyphX = leftX + gap * 0.15;

      final (String path, double upem) = switch (clef.symbol) {
        ClefSymbol.g => (_gClefSvg, 1000.0),
        ClefSymbol.c => (_cClefSvg, 1000.0),
        ClefSymbol.f => (_fClefSvg, 1000.0),
      };

      final scale = (gap * clefFontSizeMultiplier) / upem;

      buf.writeln(
        '    <g transform="translate(${_f(glyphX)}, ${_f(baselineY)}) '
        'scale(${_f(scale)}, -${_f(scale)})" fill="black" stroke="none">'
      );
      buf.writeln('      <path d="$path"/>');
      buf.writeln('    </g>');
    }
  }

  buf.writeln('</svg>');
  return buf.toString();
}

const String _gClefSvg = "M314 801Q300 854 291.0 906.0Q282 958 282 1012Q282 1059 288.5 1100.5Q295 1142 307 1177Q320 1217 341.0 1252.5Q362 1288 385.5 1311.0Q409 1334 427 1334Q451 1334 493 1249Q514 1206 524.0 1156.0Q534 1106 534 1049Q534 978 515.0 907.5Q496 837 459.5 775.0Q423 713 372 666L407 498Q422 500 432.0 501.0Q442 502 447 502Q508 502 556.0 467.5Q604 433 632.5 377.0Q661 321 661 254Q661 177 621.5 115.5Q582 54 503 25Q508 8 532 -117Q538 -147 541.0 -164.5Q544 -182 545.0 -195.0Q546 -208 546 -225Q546 -275 521.5 -314.5Q497 -354 455.5 -376.0Q414 -398 363 -398Q311 -398 271.0 -378.5Q231 -359 208.0 -324.5Q185 -290 185 -245Q185 -197 211.5 -165.0Q238 -133 287 -133Q329 -133 355.5 -163.5Q382 -194 382 -236Q382 -272 357.0 -299.0Q332 -326 292 -326H282Q308 -365 364 -365Q433 -365 472.0 -320.0Q511 -275 511 -205Q511 -188 507.0 -159.5Q503 -131 493 -91Q483 -51 477.5 -25.0Q472 1 470 12Q436 2 390 2Q304 2 222 52Q142 102 96.0 184.0Q50 266 50 361Q50 451 91 530Q132 609 192.5 675.0Q253 741 314 801ZM341 826Q364 838 390.0 870.5Q416 903 440.0 945.0Q464 987 479.0 1029.5Q494 1072 494 1106Q494 1142 483.0 1163.0Q472 1184 445 1184Q421 1184 398.5 1162.0Q376 1140 358.5 1103.5Q341 1067 331.0 1022.0Q321 977 321 930Q321 898 327.5 872.0Q334 846 341 826ZM398 379Q371 373 347.0 353.5Q323 334 308.5 306.5Q294 279 294 248Q294 223 307.0 196.5Q320 170 339 154Q352 142 365 136Q380 129 380 123Q380 120 370 117Q332 126 301.5 151.0Q271 176 253.5 211.5Q236 247 236 287Q236 330 253.5 370.0Q271 410 302.5 442.0Q334 474 374 490L345 641Q229 547 174.5 456.5Q120 366 120 277Q120 212 154.0 156.0Q188 100 247.0 65.5Q306 31 380 31Q400 31 420.5 35.0Q441 39 464 45ZM495 55Q593 97 593 227Q593 270 571.0 305.5Q549 341 512.0 362.0Q475 383 429 383Z";
const String _cClefSvg = "M226 0V1000H263V510Q281 519 301.0 546.0Q321 573 339.0 608.5Q357 644 370.0 679.5Q383 715 386 742Q396 673 427.0 633.5Q458 594 503 594Q548 594 570 631Q593 668 593 775Q593 818 590.5 848.5Q588 879 582 898Q569 942 541.0 960.5Q513 979 470 979Q447 979 434.0 969.5Q421 960 421 951Q421 944 428.0 934.0Q435 924 443 914Q460 894 460 877Q460 853 442.5 833.5Q425 814 392 814Q362 814 342.5 835.5Q323 857 323 887Q323 924 347.5 952.0Q372 980 411.5 996.0Q451 1012 497 1012Q561 1012 612.0 982.0Q663 952 693.5 899.0Q724 846 724 777Q724 734 714.5 698.0Q705 662 685 633Q658 595 616.0 573.5Q574 552 527 552Q505 552 481.5 557.5Q458 563 437 574L390 500L437 426Q460 435 484.0 440.0Q508 445 532 445Q587 445 630.5 414.0Q674 383 699.0 332.0Q724 281 724 219Q724 157 694.0 104.5Q664 52 613.0 21.0Q562 -10 497 -10Q413 -10 368.0 23.5Q323 57 323 115Q323 145 342.5 166.5Q362 188 392 188Q425 188 442.5 168.5Q460 149 460 125Q460 106 443 88Q434 78 427.5 69.0Q421 60 421 52Q421 40 434.0 31.5Q447 23 470 23Q532 23 563.5 68.5Q595 114 595 219Q595 311 574.0 358.5Q553 406 503 406Q457 406 427.0 367.0Q397 328 388 260Q379 309 360.0 355.0Q341 401 316.0 437.0Q291 473 263 492V0ZM50 0V1000H167V0ZM687 809Q710 809 726.0 793.0Q742 777 742 754Q742 731 726.0 715.5Q710 700 687 700Q664 700 648.0 715.5Q632 731 632 754Q632 777 648.0 793.0Q664 809 687 809ZM687 589Q710 589 726.0 573.0Q742 557 742 534Q742 511 726.0 495.5Q710 480 687 480Q664 480 648.0 495.5Q632 511 632 534Q632 557 648.0 573.0Q664 589 687 589Z";
const String _fClefSvg = "M50 123Q216 231 288 301Q336 348 373.0 408.5Q410 469 431.5 536.0Q453 603 453 669Q453 728 435.0 773.5Q417 819 383.0 845.0Q349 871 302 871Q284 871 264.5 867.0Q245 863 224 855Q181 839 158.0 813.5Q135 788 135 765Q135 756 143.0 752.0Q151 748 158 748Q168 748 183 752Q190 754 196.5 755.0Q203 756 210 756Q248 756 272.0 733.5Q296 711 296 674Q296 638 266.0 612.0Q236 586 195 586Q146 586 111.0 617.0Q76 648 76 697Q76 756 109.0 802.0Q142 848 198.5 874.0Q255 900 324 900Q400 900 460.0 867.0Q520 834 555.5 776.5Q591 719 591 646Q591 551 538 464Q511 419 476.5 379.0Q442 339 389.0 297.5Q336 256 256.0 208.0Q176 160 57 101ZM687 809Q710 809 726.0 793.0Q742 777 742 754Q742 731 726.0 715.5Q710 700 687 700Q664 700 648.0 715.5Q632 731 632 754Q632 777 648.0 793.0Q664 809 687 809ZM687 589Q710 589 726.0 573.0Q742 557 742 534Q742 511 726.0 495.5Q710 480 687 480Q664 480 648.0 495.5Q632 511 632 534Q632 557 648.0 573.0Q664 589 687 589Z";
