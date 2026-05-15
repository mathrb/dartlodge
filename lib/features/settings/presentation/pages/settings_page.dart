import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:dart_lodge/app/app_router.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/persistence/drift/drift_helper.dart';
import 'package:dart_lodge/core/providers/players_providers.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _erasing = false;
  bool _downloading = false;

  Future<void> _downloadDatabase() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _downloading = true);
    try {
      await DriftHelper.instance.downloadDatabase();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _reportBug() async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Report a Bug'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Describe what went wrong…',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send'),
            ),
          ],
        ),
      );

      final message = controller.text.trim();
      if (submitted != true || message.isEmpty) return;

      Sentry.captureFeedback(SentryFeedback(message: message));

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Thanks! Your feedback has been sent.')),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmAndErase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase All Data?'),
        content: const Text(
          'This will permanently delete all players, games, and statistics. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Erase All Data'),
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
    final themeMode =
        ref.watch(settingsProvider).value ?? ThemeMode.system;
    final notifier = ref.read(settingsProvider.notifier);
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
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _SectionHeader(label: 'Theme', cs: cs, tt: tt),
          _ThemeModeSelector(
            value: themeMode,
            onChanged: notifier.setThemeMode,
          ),
          const Divider(height: 1),
          _SectionHeader(label: 'About', cs: cs, tt: tt),
          _InfoRow(
            title: 'Version',
            trailing: ref.watch(appVersionProvider).value ?? '…',
            cs: cs,
            tt: tt,
          ),
          _TapRow(
            title: 'Open Source Licenses',
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'DartLodge',
            ),
          ),
          const Divider(height: 1),
          _SectionHeader(label: 'Feedback', cs: cs, tt: tt),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Report a Bug'),
            subtitle: const Text('Let us know if something went wrong'),
            onTap: _reportBug,
          ),
          const Divider(height: 1),
          _SectionHeader(label: 'Debug', cs: cs, tt: tt),
          ListTile(
            leading: _downloading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            title: const Text('Download Database'),
            subtitle: const Text('Export SQLite file for debugging'),
            enabled: !_downloading,
            onTap: _downloadDatabase,
          ),
          const Divider(height: 1),
          _SectionHeader(label: 'Danger Zone', cs: cs, tt: tt),
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
              'Erase All Data',
              style: TextStyle(color: cs.error),
            ),
            subtitle: const Text('Permanently delete all players and games'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            label: Text('Light'),
            icon: Icon(Icons.light_mode_outlined),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            label: Text('System'),
            icon: Icon(Icons.brightness_auto_outlined),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            label: Text('Dark'),
            icon: Icon(Icons.dark_mode_outlined),
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

class _TapRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _TapRow({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(title), onTap: onTap);
  }
}
