// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_version.dart';
import '../../../logic/services/changelog_service.dart';

/// Shows the dedicated SarvMD About & Version Information dialog.
Future<void> showSarvAboutDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const AboutSarvDialog(),
  );
}

/// A desktop-class modal dialog displaying SarvMD version info, core layout specs,
/// legal license details, and dynamically parsed [CHANGELOG.md] history.
class AboutSarvDialog extends StatefulWidget {
  const AboutSarvDialog({super.key});

  @override
  State<AboutSarvDialog> createState() => _AboutSarvDialogState();
}

class _AboutSarvDialogState extends State<AboutSarvDialog> {
  late final Future<List<ReleaseEntry>> _changelogFuture;

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
            Text('Build information copied to clipboard'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: cs.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: FutureBuilder<List<ReleaseEntry>>(
          future: _changelogFuture,
          builder: (context, snapshot) {
            final entries = snapshot.data ?? [];
            final latestVersion = entries.isNotEmpty
                ? entries.first.version
                : AppVersion.fallbackVersion;
            final latestDate = entries.isNotEmpty ? entries.first.date : '';

            return DefaultTabController(
              length: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Hero Section
                  _buildHeader(context, latestVersion),

                  // Tab Selector
                  TabBar(
                    labelColor: cs.primary,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    indicatorColor: cs.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(icon: Icon(Icons.info_outline, size: 16), text: 'Overview'),
                      Tab(icon: Icon(Icons.gavel_outlined, size: 16), text: 'License & Credits'),
                      Tab(icon: Icon(Icons.history_outlined, size: 16), text: 'Changelog'),
                    ],
                  ),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildOverviewTab(context),
                        _buildLicenseTab(context),
                        _buildChangelogTab(context, snapshot.connectionState, entries),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Bottom Footer Actions
                  _buildFooter(context, latestVersion, latestDate),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String version) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_outlined, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      'v$version',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SvgPicture.asset(
            'assets/handwriting/Sarv Handwriting.svg',
            height: 52,
            colorFilter: ColorFilter.mode(
              cs.onSurface,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppVersion.tagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.primary.withValues(alpha: 0.85),
              fontSize: 17,
              fontFamily: 'IranNastaliq',
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Core Engine Specifications',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: cs.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          const _SpecCard(
            icon: Icons.font_download_outlined,
            title: 'SMuFL Standard',
            subtitle: AppVersion.smuflSpec,
            description:
                'Authentic music notation vectors rendered via standard SMuFL glyph codepoints.',
          ),
          const SizedBox(height: 10),
          const _SpecCard(
            icon: Icons.straighten_outlined,
            title: 'Engraving Rules',
            subtitle: AppVersion.engravingRules,
            description:
                'Optical Gouldian rhythmic spacing algorithms and MOLA-compliant system geometry.',
          ),
          const SizedBox(height: 10),
          const _SpecCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Compiler Backend',
            subtitle: AppVersion.latexBackend,
            description:
                'Generates publication-quality LaTeX files compiled using pdflatex direct graphic operators.',
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InfoTile(
            title: 'Author & Lead Developer',
            value: AppVersion.author,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          const _InfoTile(
            title: 'License',
            value: AppVersion.license,
            icon: Icons.gavel_outlined,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Text(
              'SarvMD is built with Flutter, Dart, logd, and Bravura SMuFL vector assets.\n'
              'Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangelogTab(
    BuildContext context,
    ConnectionState connectionState,
    List<ReleaseEntry> entries,
  ) {
    final cs = Theme.of(context).colorScheme;

    if (connectionState == ConnectionState.waiting && entries.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No changelog information available.',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final release = entries[index];
        return _ReleaseCard(release: release);
      },
    );
  }

  Widget _buildFooter(BuildContext context, String version, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: () => _copyBuildInfo(context, version, date),
            icon: const Icon(Icons.copy_outlined, size: 14),
            label: const Text('Copy Build Info', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({required this.release});

  final ReleaseEntry release;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'v${release.version}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              if (release.date.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  release.date,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ...release.changes.map((c) => _ChangelogItem(change: c)),
        ],
      ),
    );
  }
}

class _ChangelogItem extends StatelessWidget {
  const _ChangelogItem({required this.change});

  final ChangelogChange change;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isAdded = change.category == 'Added';
    final isFixed = change.category == 'Fixed';
    final badgeColor = isAdded
        ? Colors.green
        : (isFixed ? Colors.orange : cs.primary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 0.5),
            ),
            child: Text(
              change.category,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              change.text,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecCard extends StatelessWidget {
  const _SpecCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
