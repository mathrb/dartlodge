import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:dart_lodge/app/app_router.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/providers/players_providers.dart';
import 'package:dart_lodge/core/sound/sound_settings_provider.dart';
import 'package:dart_lodge/core/utils/app_spacing.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../providers/crash_reporting_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/language_selector.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _erasing = false;

  Future<void> _setCrashReporting(bool enabled) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(crashReportingEnabledProvider.notifier).setEnabled(enabled);
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsCrashReportingRestartNote)),
      );
    }
  }

  Future<void> _reportBug() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.settingsReportBug),
          content: TextField(
            controller: controller,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.settingsReportBugHint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.commonSend),
            ),
          ],
        ),
      );

      final message = controller.text.trim();
      if (submitted != true || message.isEmpty) return;

      Sentry.captureFeedback(SentryFeedback(message: message));

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsReportBugThanks)),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmAndErase(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsEraseAllDataTitle),
        content: Text(l10n.settingsEraseAllDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsEraseAllData),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _erasing = true);
    try {
      await ref.read(clearAllDataProvider)();
      ref.invalidate(allPlayersProvider);
      if (mounted) context.go(GameRoutes.home);
    } finally {
      if (mounted) setState(() => _erasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeMode =
        ref.watch(settingsProvider).value ?? ThemeMode.system;
    final notifier = ref.read(settingsProvider.notifier);
    final locale = ref.watch(localeSettingProvider).value; // Locale? — null = system
    final localeNotifier = ref.read(localeSettingProvider.notifier);
    final soundEnabled = ref.watch(soundEnabledProvider).value ?? true;
    // Toggle reflects the persisted preference; sentryActive reflects whether
    // Sentry was actually initialized this session (opt-out takes effect on the
    // next launch). Report-a-Bug gates on the latter so feedback is never lost.
    final crashReportingEnabled =
        ref.watch(crashReportingEnabledProvider).value ?? true;
    final sentryActive = Sentry.isEnabled;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(GameRoutes.home);
            }
          },
        ),
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          _SectionHeader(label: l10n.settingsThemeSection, cs: cs, tt: tt),
          _ThemeModeSelector(
            value: themeMode,
            onChanged: notifier.setThemeMode,
          ),
          const Divider(height: 1),
          _SectionHeader(label: l10n.settingsLanguageLabel, cs: cs, tt: tt),
          LanguageSelector(
            value: locale,
            onChanged: localeNotifier.setLocale,
          ),
          const Divider(height: 1),
          _SectionHeader(label: l10n.settingsSoundSection, cs: cs, tt: tt),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: Text(l10n.settingsSoundEffectsTitle),
            subtitle: Text(l10n.settingsSoundEffectsSubtitle),
            value: soundEnabled,
            onChanged: (v) =>
                ref.read(soundEnabledProvider.notifier).setEnabled(v),
          ),
          const Divider(height: 1),
          _SectionHeader(label: l10n.settingsAutoScoringSection, cs: cs, tt: tt),
          ListTile(
            leading: const Icon(Icons.center_focus_strong),
            title: Text(l10n.settingsAutoScoringTitle),
            subtitle: Text(l10n.settingsAutoScoringSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(GameRoutes.autoScorerSettings),
          ),
          const Divider(height: 1),
          _SectionHeader(label: l10n.settingsAboutSection, cs: cs, tt: tt),
          _InfoRow(
            title: l10n.settingsVersion,
            trailing: ref.watch(appVersionProvider).value ?? '…',
            cs: cs,
            tt: tt,
          ),
          const Divider(height: 1),
          _SectionHeader(label: l10n.settingsFeedbackSection, cs: cs, tt: tt),
          SwitchListTile(
            secondary: const Icon(Icons.analytics_outlined),
            title: Text(l10n.settingsCrashReportingTitle),
            subtitle: Text(l10n.settingsCrashReportingSubtitle),
            value: crashReportingEnabled,
            onChanged: _setCrashReporting,
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(l10n.settingsReportBug),
            subtitle: Text(
              sentryActive
                  ? l10n.settingsReportBugSubtitle
                  : l10n.settingsReportBugDisabled,
            ),
            enabled: sentryActive,
            onTap: sentryActive ? _reportBug : null,
          ),
          const Divider(height: 1),
          _SectionHeader(label: l10n.settingsDangerZoneSection, cs: cs, tt: tt),
          ListTile(
            leading: _erasing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.error,
                    ),
                  )
                : Icon(Icons.delete_forever_outlined, color: cs.error),
            title: Text(
              l10n.settingsEraseAllData,
              style: TextStyle(color: cs.error),
            ),
            subtitle: Text(l10n.settingsEraseAllDataSubtitle),
            enabled: !_erasing,
            onTap: () => _confirmAndErase(context),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  final TextTheme tt;

  const _SectionHeader({
    required this.label,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

/// 3-way Light / System / Dark theme-mode selector.
///
/// Replaces the previous combination of a Switch ("Dark Mode") + a
/// separate "Use system default" tile, which made System mode hard to
/// reach (two unrelated controls competing for the same setting) and
/// left ambiguous state when both rows looked "off".
class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: SegmentedButton<ThemeMode>(
        segments: [
          ButtonSegment(
            value: ThemeMode.light,
            label: Text(l10n.settingsThemeLight),
            icon: const Icon(Icons.light_mode_outlined),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            label: Text(l10n.settingsThemeSystem),
            icon: const Icon(Icons.brightness_auto_outlined),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            label: Text(l10n.settingsThemeDark),
            icon: const Icon(Icons.dark_mode_outlined),
          ),
        ],
        selected: {value},
        onSelectionChanged: (set) => onChanged(set.first),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String trailing;
  final ColorScheme cs;
  final TextTheme tt;

  const _InfoRow({
    required this.title,
    required this.trailing,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        trailing,
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

