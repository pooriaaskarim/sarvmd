/// Pre-configured staff profiles for common manuscript layouts.
///
/// A [StaffProfile] bundles a [LayoutType] with a predefined [ClefConfig] pair,
/// providing fast, one-tap configuration for the most common musical setups.

import 'config.dart';

/// An immutable, named preset that bundles a layout type and clef configuration.
class StaffProfile {
  const StaffProfile({
    required this.id,
    required this.label,
    required this.layoutType,
    this.primaryClef,
    this.secondaryClef,
    this.description,
  });

  /// Unique identifier for this profile.
  final String id;

  /// Human-readable name shown in the UI.
  final String label;

  /// The layout type this profile uses.
  final LayoutType layoutType;

  /// The clef on the single staff, or the upper (treble) staff of a grand staff.
  final ClefConfig? primaryClef;

  /// The clef on the lower (bass) staff. Only relevant for [LayoutType.doubleLine].
  final ClefConfig? secondaryClef;

  /// Short description of this profile's intended use.
  final String? description;

  /// Apply this profile to an existing [PageConfig], preserving all spacing
  /// and margin settings while overriding layout and clefs.
  PageConfig applyTo(PageConfig config) => PageConfig(
        pageSize: config.pageSize,
        layoutType: layoutType,
        staffConfig: config.staffConfig,
        margins: config.margins,
        primaryClef: primaryClef,
        secondaryClef: secondaryClef,
      );
}

/// Built-in staff profiles for common manuscript layouts.
abstract final class StaffProfiles {
  /// Piano / keyboard grand staff (treble + bass).
  static const piano = StaffProfile(
    id: 'piano',
    label: 'Piano',
    layoutType: LayoutType.doubleLine,
    primaryClef: ClefConfig(symbol: ClefSymbol.g, anchorLine: 2),
    secondaryClef: ClefConfig(symbol: ClefSymbol.f, anchorLine: 4),
    description: 'Grand staff for piano or keyboard.',
  );

  /// Standard treble clef (violin, flute, soprano, etc.).
  static const treble = StaffProfile(
    id: 'treble',
    label: 'Treble',
    layoutType: LayoutType.singleLine,
    primaryClef: ClefConfig(symbol: ClefSymbol.g, anchorLine: 2),
    description: 'Standard G clef — violin, flute, soprano.',
  );

  /// Standard bass clef (cello, bass guitar, tuba, etc.).
  static const bass = StaffProfile(
    id: 'bass',
    label: 'Bass',
    layoutType: LayoutType.singleLine,
    primaryClef: ClefConfig(symbol: ClefSymbol.f, anchorLine: 4),
    description: 'Standard F clef — cello, bass guitar, tuba.',
  );

  /// Alto clef (viola).
  static const alto = StaffProfile(
    id: 'alto',
    label: 'Alto',
    layoutType: LayoutType.singleLine,
    primaryClef: ClefConfig(symbol: ClefSymbol.c, anchorLine: 3),
    description: 'C clef on middle line — viola.',
  );

  /// Blank staff with no clef.
  static const blank = StaffProfile(
    id: 'blank',
    label: 'Blank',
    layoutType: LayoutType.singleLine,
    description: 'Anonymous 5-line staff, no clef.',
  );

  /// All built-in profiles in display order.
  static const all = [piano, treble, bass, alto, blank];
}
