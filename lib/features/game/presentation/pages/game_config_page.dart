import 'package:flutter/material.dart';
import 'package:my_darts/core/utils/app_spacing.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/features/game/presentation/widgets/config_stepper_widget.dart';

/// A bottom-sheet panel that lets the user adjust game configuration.
/// Uses a copy-on-open (draft) pattern: edits are local until Apply is tapped.
/// Returns the updated [GameConfig] via [Navigator.pop] on Apply, or null on
/// discard (drag handle tap / swipe dismiss).
class GameConfigPanel extends StatefulWidget {
  const GameConfigPanel({
    super.key,
    required this.initialConfig,
  });

  final GameConfig initialConfig;

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

  // ── Actions ───────────────────────────────────────────────────────────────────

  void _apply() => Navigator.pop(context, _draftConfig);
  void _discard() => Navigator.pop(context, null);

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _discard();
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle — tap to discard
              Center(
                child: GestureDetector(
                  onTap: _discard,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                'Game Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ..._buildConfigFields(),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _apply,
                child: Text(
                  'APPLY SETTINGS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
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
      shanghai: _buildShanghaiFields,
      scram: (_) => [],
      halveIt: (_) => [],
      highScore: (_) => [],
      blindCricket: (_) => [],
      blindGolf: (_) => [],
      blindKiller: (_) => [],
      blindShanghai: (_) => [],
      chaseTheDragon: (_) => [],
      catch40: (_) => [],
      bobs27: (_) => [],
      checkoutPractice: (_) => [],
    );
  }

  List<Widget> _buildShanghaiFields(ShanghaiGameConfig c) {
    return [
      _FieldColumn(
        label: 'Rounds',
        child: _StyledDropdown<int>(
          value: c.totalRounds,
          items: const [7, 10, 15, 20],
          labelBuilder: (v) => '$v',
          onChanged: (v) {
            if (v == null) return;
            setState(() => _draftConfig = c.copyWith(totalRounds: v));
          },
        ),
      ),
    ];
  }

  List<Widget> _buildX01Fields(X01GameConfig c) {
    return [
      _FieldColumn(
        label: 'Starting Score',
        child: _StyledDropdown<int>(
          value: c.startingScore,
          items: const [101, 170, 201, 301, 401, 501, 701, 1001],
          labelBuilder: (v) => '$v',
          onChanged: (v) {
            if (v == null) return;
            setState(() => _draftConfig = c.copyWith(startingScore: v));
          },
        ),
      ),
      const SizedBox(height: AppSpacing.space4),
      _FieldColumn(
        label: 'In Strategy',
        child: _StyledDropdown<String>(
          value: c.inStrategy,
          items: const ['straight', 'double', 'master'],
          labelBuilder: _strategyLabel,
          onChanged: (v) {
            if (v == null) return;
            setState(() => _draftConfig = c.copyWith(inStrategy: v));
          },
        ),
      ),
      const SizedBox(height: AppSpacing.space4),
      _FieldColumn(
        label: 'Out Strategy',
        child: _StyledDropdown<String>(
          value: c.outStrategy,
          items: const ['straight', 'double', 'master'],
          labelBuilder: _strategyLabel,
          onChanged: (v) {
            if (v == null) return;
            setState(() => _draftConfig = c.copyWith(outStrategy: v));
          },
        ),
      ),
      const SizedBox(height: AppSpacing.space4),
      _FieldColumn(
        label: 'Legs to Win',
        child: ConfigStepperWidget(
          value: c.legsToWin,
          min: 1,
          max: 9,
          onDecrement: () =>
              setState(() => _draftConfig = c.copyWith(legsToWin: c.legsToWin - 1)),
          onIncrement: () =>
              setState(() => _draftConfig = c.copyWith(legsToWin: c.legsToWin + 1)),
        ),
      ),
    ];
  }

  List<Widget> _buildCricketFields(CricketGameConfig c) {
    return [
      _FieldColumn(
        label: 'Variant',
        child: _StyledDropdown<String>(
          value: c.variant,
          items: const ['standard', 'cut-throat'],
          labelBuilder: (v) => v == 'cut-throat' ? 'Cut-throat' : 'Standard',
          onChanged: (v) {
            if (v == null) return;
            setState(() => _draftConfig = c.copyWith(variant: v));
          },
        ),
      ),
      const SizedBox(height: AppSpacing.space4),
      _FieldColumn(
        label: 'Points to Win',
        child: ConfigStepperWidget(
          value: c.pointsToWin,
          min: 1,
          max: 9,
          onDecrement: () => setState(
              () => _draftConfig = c.copyWith(pointsToWin: c.pointsToWin - 1)),
          onIncrement: () => setState(
              () => _draftConfig = c.copyWith(pointsToWin: c.pointsToWin + 1)),
        ),
      ),
    ];
  }

  static String _strategyLabel(String strategy) => switch (strategy) {
        'straight' => 'Any',
        'double' => 'Double',
        'master' => 'Master',
        _ => strategy,
      };
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _FieldColumn extends StatelessWidget {
  const _FieldColumn({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.expand_more),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(labelBuilder(item)),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
