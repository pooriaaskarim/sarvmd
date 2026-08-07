// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_version.dart';
import '../../../logic/services/changelog_service.dart';

/// Shows the standard SarvMD About & Version Information dialog.
Future<void> showSarvAboutDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const AboutSarvDialog(),
  );
}

/// A standard, familiar desktop About dialog featuring app branding, version metadata,
/// copyright attributions, expandable changelog history, and standard license page integration.
class AboutSarvDialog extends StatefulWidget {
  const AboutSarvDialog({super.key});

  @override
  State<AboutSarvDialog> createState() => _AboutSarvDialogState();
}

class _AboutSarvDialogState extends State<AboutSarvDialog> {
  late final Future<List<ReleaseEntry>> _changelogFuture;
  bool _showChangelog = false;

  @override
  void initState() {
    super.initState();
    _changelogFuture = ChangelogService.loadChangelog();
  }

  void _copyBuildInfo(BuildContext context, String version, String date) {
    final info = AppVersion.getFormattedBuildInfo(version, date);
    Clipboard.setData(ClipboardData(text: info));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Build info copied to clipboard'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _openLicenses(BuildContext context, String version) {
    showLicensePage(
      context: context,
      applicationName: AppVersion.name,
      applicationVersion: 'v$version',
      applicationLegalese: '${AppVersion.copyright}\n${AppVersion.license}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: cs.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: FutureBuilder<List<ReleaseEntry>>(
          future: _changelogFuture,
          builder: (context, snapshot) {
            final entries = snapshot.data ?? [];
            final version = entries.isNotEmpty
                ? entries.first.version
                : AppVersion.fallbackVersion;
            final date = entries.isNotEmpty ? entries.first.date : '';

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Brand Visual
                  SvgPicture.asset(
                    'assets/handwriting/Sarv Handwriting.svg',
                    height: 44,
                    colorFilter: ColorFilter.mode(
                      cs.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // App Title & Tagline
                  Text(
                    AppVersion.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    AppVersion.tagline,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'IranNastaliq',
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Version Tag
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Version $version${date.isNotEmpty ? " ($date)" : ""}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Concise Description
                  Text(
                    AppVersion.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Copyright & License Notice
                  Text(
                    '${AppVersion.copyright}\n${AppVersion.license}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Expandable Changelog Trigger
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showChangelog = !_showChangelog;
                      });
                    },
                    icon: Icon(
                      _showChangelog
                          ? Icons.keyboard_arrow_up
                          : Icons.history_outlined,
                      size: 16,
                    ),
                    label: Text(
                      _showChangelog ? 'Hide Changelog' : 'View Release Notes',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),

                  // Inline Scrollable Changelog View
                  if (_showChangelog) ...[
                    const SizedBox(height: 8),
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          shrinkWrap: true,
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final release = entries[index];
                            return _CompactReleaseTile(release: release);
                          },
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Standard Action Buttons Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openLicenses(context, version),
                            icon: const Icon(Icons.gavel_outlined, size: 14),
                            label: const Text('Licenses',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () =>
                                _copyBuildInfo(context, version, date),
                            icon: const Icon(Icons.copy_outlined, size: 16),
                            tooltip: 'Copy Info',
                            style: IconButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Close',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CompactReleaseTile extends StatelessWidget {
  const _CompactReleaseTile({required this.release});

  final ReleaseEntry release;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'v${release.version}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              if (release.date.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  release.date,
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          ...release.changes.map(
            (change) => Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                '• [${change.category}] ${change.text}',
                style: TextStyle(
                  fontSize: 10.5,
                  color: cs.onSurface,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
