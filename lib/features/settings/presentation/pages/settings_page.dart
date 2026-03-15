import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_darts/app/app_router.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(settingsProvider).value ?? ThemeMode.system;
    final notifier = ref.read(settingsProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(GameRoutes.home)),
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _SectionHeader(label: 'Theme', cs: cs, tt: tt),
          _ToggleRow(
            title: 'Dark Mode',
            value: themeMode == ThemeMode.dark,
            cs: cs,
            onChanged: (on) =>
                notifier.setThemeMode(on ? ThemeMode.dark : ThemeMode.light),
          ),
          _OptionRow(
            title: 'Use system default',
            selected: themeMode == ThemeMode.system,
            cs: cs,
            onTap: () => notifier.setThemeMode(ThemeMode.system),
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
              applicationName: 'Darts',
            ),
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

class _ToggleRow extends StatelessWidget {
  final String title;
  final bool value;
  final ColorScheme cs;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.value,
    required this.cs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      activeTrackColor: cs.primary,
      inactiveTrackColor: cs.outlineVariant,
      onChanged: onChanged,
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String title;
  final bool selected;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _OptionRow({
    required this.title,
    required this.selected,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: selected
          ? Icon(Icons.check, color: cs.primary)
          : null,
      onTap: onTap,
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
