// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../../../l10n/app_localizations.dart';
import '../../../../../logic/config/config_cubit.dart';

/// Ensemble profile quick-picker dropdown rendered in the left zone of the top bar.
///
/// Selecting a profile calls [ConfigCubit.applyProfile] which replaces the current
/// system layout with the preset's stave configuration.
class EnsembleProfilePicker extends StatelessWidget {
  final core.StaffProfile? activeProfile;

  const EnsembleProfilePicker({super.key, required this.activeProfile});

  String _getProfileTitle(AppLocalizations l10n, core.StaffProfile profile) {
    return switch (profile.id) {
      'piano' => l10n.profilePianoTitle,
      'treble' => l10n.profileTrebleTitle,
      'bass' => l10n.profileBassTitle,
      'alto' => l10n.profileAltoTitle,
      'tenor' => l10n.profileTenorTitle,
      'stringQuartet' => l10n.profileStringQuartetTitle,
      'choirSATB' => l10n.profileChoirSATBTitle,
      'leadSheet' => l10n.profileLeadSheetTitle,
      'guitarTab' => l10n.profileGuitarTabTitle,
      'guitarGrand' => l10n.profileGuitarGrandTitle,
      'bassTab' => l10n.profileBassTabTitle,
      'banjoTab' => l10n.profileBanjoTabTitle,
      'drumSet' => l10n.profileDrumKitTitle,
      'percussion1' => l10n.profilePercussion1Title,
      'percussion3' => l10n.profilePercussion3Title,
      'blank' => l10n.profileBlankTitle,
      _ => profile.label,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final currentLabel = activeProfile != null
        ? _getProfileTitle(l10n, activeProfile!)
        : l10n.categoryEnsemble;

    return PopupMenuButton<core.StaffProfile>(
      tooltip: l10n.tooltipEnsemblePicker,
      offset: const Offset(0, 38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      color: cs.surfaceContainerHigh,
      onSelected: (profile) {
        context.read<ConfigCubit>().applyProfile(profile);
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<core.StaffProfile>(
            enabled: false,
            child: Text(
              l10n.headerEnsembleProfiles,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.grey,
              ),
            ),
          ),
          ...core.StaffProfiles.all.map((p) {
            final isSelected = activeProfile?.id == p.id;
            return PopupMenuItem<core.StaffProfile>(
              value: p,
              child: Row(
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    size: 16.0,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      _getProfileTitle(l10n, p),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? cs.primary : cs.onSurface,
                      ),
                    ),
                  ),
                  if (isSelected) Icon(Icons.check_rounded, size: 16.0, color: cs.primary),
                ],
              ),
            );
          }),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.5),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue_music_rounded, size: 14.0, color: cs.primary),
            const SizedBox(width: 5.0),
            Text(
              currentLabel,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 3.0),
            Icon(Icons.arrow_drop_down_rounded, size: 16.0, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
