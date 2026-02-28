import 'package:flutter/material.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/features/game/presentation/widgets/config_stepper_widget.dart';

/// A bottom-sheet panel that lets the user adjust game configuration.
/// Uses a copy-on-open (draft) pattern: edits are local until Apply is tapped.
/// Returns the updated [GameConfig] via [Navigator.pop] on both Apply and
/// swipe-dismiss, so the caller always receives the latest draft.
class GameConfigPanel extends StatefulWidget {
  const GameConfigPanel({
    super.key,
    required this.initialConfig,
    required this.players,
  });

  final GameConfig initialConfig;

  /// Selected players available as starting-player options.
  /// Each record carries both the display name and the player ID.
  final List<({String id, String name})> players;

  @override
  State<GameConfigPanel> createState() => _GameConfigPanelState();
}

class _GameConfigPanelState extends State<GameConfigPanel> {
  late GameConfig _draftConfig;

  @override
  void initState() {
    super.initState();
    _draftConfig = widget.initialConfig;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Returns the current startingPlayerId regardless of config subtype.
  String? get _startingPlayerId => _draftConfig.map(
        x01: (c) => c.startingPlayerId,
        cricket: (c) => c.startingPlayerId,
        aroundTheClock: (c) => c.startingPlayerId,
        killer: (c) => c.startingPlayerId,
        baseball: (c) => c.startingPlayerId,
        golf: (c) => c.startingPlayerId,
        shanghai: (c) => c.startingPlayerId,
        scram: (c) => c.startingPlayerId,
        halveIt: (c) => c.startingPlayerId,
        highScore: (c) => c.startingPlayerId,
        blindCricket: (c) => c.startingPlayerId,
        blindGolf: (c) => c.startingPlayerId,
        blindKiller: (c) => c.startingPlayerId,
        blindShanghai: (c) => c.startingPlayerId,
        chaseTheDragon: (c) => c.startingPlayerId,
      );

  void _updateStartingPlayerId(String? id) {
    setState(() {
      _draftConfig = _draftConfig.map(
        x01: (c) => c.copyWith(startingPlayerId: id),
        cricket: (c) => c.copyWith(startingPlayerId: id),
        aroundTheClock: (c) => c.copyWith(startingPlayerId: id),
        killer: (c) => c.copyWith(startingPlayerId: id),
        baseball: (c) => c.copyWith(startingPlayerId: id),
        golf: (c) => c.copyWith(startingPlayerId: id),
        shanghai: (c) => c.copyWith(startingPlayerId: id),
        scram: (c) => c.copyWith(startingPlayerId: id),
        halveIt: (c) => c.copyWith(startingPlayerId: id),
        highScore: (c) => c.copyWith(startingPlayerId: id),
        blindCricket: (c) => c.copyWith(startingPlayerId: id),
        blindGolf: (c) => c.copyWith(startingPlayerId: id),
        blindKiller: (c) => c.copyWith(startingPlayerId: id),
        blindShanghai: (c) => c.copyWith(startingPlayerId: id),
        chaseTheDragon: (c) => c.copyWith(startingPlayerId: id),
      );
    });
  }

  void _close() => Navigator.pop(context, _draftConfig);

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Game Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ..._buildConfigFields(),
              const SizedBox(height: 8),
              _buildStartingPlayerRow(),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _close,
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildConfigFields() {
    return _draftConfig.map(
      x01: _buildX01Fields,
      cricket: _buildCricketFields,
      aroundTheClock: (_) => [],
      killer: (_) => [],
      baseball: (_) => [],
      golf: (_) => [],
      shanghai: (_) => [],
      scram: (_) => [],
      halveIt: (_) => [],
      highScore: (_) => [],
      blindCricket: (_) => [],
      blindGolf: (_) => [],
      blindKiller: (_) => [],
      blindShanghai: (_) => [],
      chaseTheDragon: (_) => [],
    );
  }

  List<Widget> _buildX01Fields(X01GameConfig c) {
    return [
      _LabelRow(label: 'Starting Score', trailing: Text('${c.startingScore}')),
      const Divider(),
      _SectionLabel('In Strategy'),
      ...['straight', 'double', 'master'].map(
        (s) => RadioListTile<String>(
          title: Text(_strategyLabel(s)),
          value: s,
          groupValue: c.inStrategy,
          dense: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) {
            if (v == null) return;
            setState(() => _draftConfig = c.copyWith(inStrategy: v));
          },
        ),
      ),
      const Divider(),
      _SectionLabel('Out Strategy'),
      ...['straight', 'double', 'master'].map(
        (s) => RadioListTile<String>(
          title: Text(_strategyLabel(s)),
          value: s,
          groupValue: c.outStrategy,
          dense: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) {
            if (v == null) return;
            setState(() => _draftConfig = c.copyWith(outStrategy: v));
          },
        ),
      ),
      const Divider(),
      _LabelRow(
        label: 'Legs to Win',
        trailing: ConfigStepperWidget(
          value: c.legsToWin,
          min: 1,
          max: 9,
          onDecrement: () =>
              setState(() => _draftConfig = c.copyWith(legsToWin: c.legsToWin - 1)),
          onIncrement: () =>
              setState(() => _draftConfig = c.copyWith(legsToWin: c.legsToWin + 1)),
        ),
      ),
      const Divider(),
    ];
  }

  List<Widget> _buildCricketFields(CricketGameConfig c) {
    return [
      _LabelRow(
        label: 'Points to Win',
        trailing: ConfigStepperWidget(
          value: c.pointsToWin,
          min: 1,
          max: 9,
          onDecrement: () => setState(
              () => _draftConfig = c.copyWith(pointsToWin: c.pointsToWin - 1)),
          onIncrement: () => setState(
              () => _draftConfig = c.copyWith(pointsToWin: c.pointsToWin + 1)),
        ),
      ),
      const Divider(),
    ];
  }

  Widget _buildStartingPlayerRow() {
    // Dropdown value: null → 'random' sentinel; player ID otherwise.
    // We use a nullable String? groupValue mapped to a String dropdown value.
    const randomKey = '__random__';
    final currentValue = _startingPlayerId ?? randomKey;

    return _LabelRow(
      label: 'Starting Player',
      trailing: DropdownButton<String>(
        value: currentValue,
        underline: const SizedBox.shrink(),
        items: [
          const DropdownMenuItem(value: randomKey, child: Text('Random')),
          ...widget.players.map(
            (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
          ),
        ],
        onChanged: (v) {
          if (v == null) return;
          _updateStartingPlayerId(v == randomKey ? null : v);
        },
      ),
    );
  }

  static String _strategyLabel(String strategy) => switch (strategy) {
        'straight' => 'Straight',
        'double' => 'Double',
        'master' => 'Master',
        _ => strategy,
      };
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          trailing,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
