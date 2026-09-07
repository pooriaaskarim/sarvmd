// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../../../logic/config/config_cubit.dart';

/// Ensemble profile quick-picker dropdown rendered in the left zone of the top bar.
///
/// Selecting a profile calls [ConfigCubit.applyProfile] which replaces the current
/// system layout with the preset's stave configuration.
class EnsembleProfilePicker extends StatelessWidget {
  final core.StaffProfile? activeProfile;

  const EnsembleProfilePicker({super.key, required this.activeProfile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentLabel = activeProfile?.label ?? 'Ensemble';

    return PopupMenuButton<core.StaffProfile>(
      tooltip: 'Select Ensemble Preset Profile',
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
          const PopupMenuItem<core.StaffProfile>(
            enabled: false,
            child: Text(
              'ENSEMBLE PROFILES',
              style: TextStyle(
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
                      p.label,
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
