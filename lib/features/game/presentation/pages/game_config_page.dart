import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dart_lodge/core/utils/app_colors.dart';
import 'package:dart_lodge/core/utils/app_spacing.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/presentation/widgets/config_stepper_widget.dart';

/// A bottom-sheet panel that lets the user adjust game configuration.
/// Uses a copy-on-open (draft) pattern: edits are local until Apply is tapped.
/// Returns the updated [GameConfig] via [Navigator.pop] on Apply, or null on
/// discard (swipe dismiss / barrier tap).
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

  /// Remembered custom starting score for X01 (persists while sheet is open).
  late int _customScore;
  late TextEditingController _customScoreController;

  static bool _isCustomScore(int s) => s != 301 && s != 501 && s != 701;

  @override
  void initState() {
    super.initState();
    _draftConfig = widget.initialConfig;
    final x01Score = widget.initialConfig.maybeMap(
      x01: (c) => c.startingScore,
      orElse: () => null,
    );
    _customScore =
        (x01Score != null && _isCustomScore(x01Score)) ? x01Score : 1001;
    _customScoreController =
        TextEditingController(text: '$_customScore');
  }

  @override
  void dispose() {
    _customScoreController.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────────

  void _apply() => Navigator.pop(context, _draftConfig);

  bool get _hasChanges => _draftConfig != widget.initialConfig;

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  ),
                ),
              ),
            ),
            Text(
              'GAME CONFIG',
              style: tt.headlineMedium?.copyWith(
                color: cs.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._buildConfigFields(),
                    const SizedBox(height: AppSpacing.space6),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            FilledButton(
              onPressed: _hasChanges ? _apply : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: cs.primaryFixed,
                foregroundColor: AppColors.onPrimaryFixed,
                disabledBackgroundColor: cs.surfaceContainerLow,
                disabledForegroundColor:
                    cs.onSurfaceVariant.withValues(alpha: AppTheme.opacityDisabled),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusXLarge),
                ),
              ),
              child: const Text('APPLY'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildConfigFields() {
    return _draftConfig.map(
      x01: _buildX01Fields,
      cricket: _buildCricketFields,
      aroundTheClock: _buildAroundTheClockFields,
      shanghai: _buildShanghaiFields,
      catch40: (_) => [],
      bobs27: (_) => [],
      checkoutPractice: _buildCheckoutPracticeFields,
      countUp: _buildCountUpFields,
    );
  }

  List<Widget> _buildX01Fields(X01GameConfig c) {
    return [
      _FieldSection(
        label: 'TYPE',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SegmentedOptionGroup<int>(
              values: const [301, 501, 701, -1],
              labels: const ['301', '501', '701', 'SET'],
              selected: _isCustomScore(c.startingScore) ? -1 : c.startingScore,
              onSelected: (v) {
                if (v == -1) {
                  // Restore the last custom score and sync the text field.
                  _customScoreController.text = '$_customScore';
                  setState(
                    () => _draftConfig =
                        c.copyWith(startingScore: _customScore),
                  );
                } else {
                  setState(
                    () => _draftConfig = c.copyWith(startingScore: v),
                  );
                }
              },
            ),
            if (_isCustomScore(c.startingScore)) ...[
              const SizedBox(height: AppSpacing.space2),
              _CustomScoreField(
                controller: _customScoreController,
                onChanged: (v) {
                  _customScore = v;
                  setState(
                    () => _draftConfig = c.copyWith(startingScore: v),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.space4),
      _FieldSection(
        label: 'IN STRATEGY',
        child: _SegmentedOptionGroup<String>(
          values: const ['straight', 'double', 'master'],
          labels: const ['STRAIGHT', 'DOUBLE', 'MASTER'],
          selected: c.inStrategy,
          onSelected: (v) =>
              setState(() => _draftConfig = c.copyWith(inStrategy: v)),
        ),
      ),
      const SizedBox(height: AppSpacing.space4),
      _FieldSection(
        label: 'OUT STRATEGY',
        child: _SegmentedOptionGroup<String>(
          values: const ['straight', 'double', 'master'],
          labels: const ['STRAIGHT', 'DOUBLE', 'MASTER'],
          selected: c.outStrategy,
          onSelected: (v) =>
              setState(() => _draftConfig = c.copyWith(outStrategy: v)),
        ),
      ),
      const SizedBox(height: AppSpacing.space4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _FieldSection(
              label: 'ROUNDS',
              child: _RoundsDropdown(
                value: c.totalRounds,
                items: const [null, 10, 15, 20, 25, 50],
                onChanged: (v) =>
                    setState(() => _draftConfig = c.copyWith(totalRounds: v)),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: _FieldSection(
              label: 'LEGS TO WIN',
              child: _StepperContainer(
                child: ConfigStepperWidget(
                  value: c.legsToWin,
                  min: 1,
                  max: 9,
                  onDecrement: () => setState(
                    () =>
                        _draftConfig = c.copyWith(legsToWin: c.legsToWin - 1),
                  ),
                  onIncrement: () => setState(
                    () =>
                        _draftConfig = c.copyWith(legsToWin: c.legsToWin + 1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildCricketFields(CricketGameConfig c) {
    return [
      _FieldSection(
        label: 'SCORING',
        child: _SegmentedOptionGroup<String>(
          values: const ['standard', 'cut-throat', 'no-score'],
          labels: const ['STANDARD', 'CUT-THROAT', 'NO SCORE'],
          selected: c.scoring,
          onSelected: (v) =>
              setState(() => _draftConfig = c.copyWith(scoring: v)),
        ),
      ),
      const SizedBox(height: AppSpacing.space4),
      _FieldSection(
        label: 'TARGETS',
        child: _SegmentedOptionGroup<String>(
          values: const ['fixed', 'random', 'crazy'],
          labels: const ['FIXED', 'RANDOM', 'CRAZY'],
          selected: c.targetMode,
          onSelected: (v) =>
              setState(() => _draftConfig = c.copyWith(targetMode: v)),
        ),
      ),
      const SizedBox(height: AppSpacing.space4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _FieldSection(
              label: 'ROUNDS',
              child: _RoundsDropdown(
                value: c.totalRounds,
                items: const [null, 10, 15, 20, 25, 50],
                onChanged: (v) =>
                    setState(() => _draftConfig = c.copyWith(totalRounds: v)),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: _FieldSection(
              label: 'LEGS TO WIN',
              child: _StepperContainer(
                child: ConfigStepperWidget(
                  value: c.legsToWin,
                  min: 1,
                  max: 9,
                  onDecrement: () => setState(
                    () => _draftConfig =
                        c.copyWith(legsToWin: c.legsToWin - 1),
                  ),
                  onIncrement: () => setState(
                    () => _draftConfig =
                        c.copyWith(legsToWin: c.legsToWin + 1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildAroundTheClockFields(AroundTheClockGameConfig c) {
    return [
      _FieldSection(
        label: 'VARIANT',
        child: _SegmentedOptionGroup<String>(
          values: const ['standard', 'reverse', 'doublesOnly'],
          labels: const ['STANDARD', 'REVERSE', 'DOUBLES ONLY'],
          selected: c.variant,
          onSelected: (v) =>
              setState(() => _draftConfig = c.copyWith(variant: v)),
        ),
      ),
    ];
  }

  List<Widget> _buildCheckoutPracticeFields(CheckoutPracticeGameConfig c) {
    return [
      _FieldSection(
        label: 'TARGET SUCCESSES',
        child: _RoundsDropdown(
          value: c.targetSuccesses,
          items: const [null, 1, 2, 3, 5, 10, 20],
          onChanged: (v) {
            setState(() => _draftConfig = c.copyWith(targetSuccesses: v));
          },
        ),
      ),
    ];
  }

  List<Widget> _buildShanghaiFields(ShanghaiGameConfig c) {
    return [
      _FieldSection(
        label: 'ROUNDS',
        child: _RoundsDropdown(
          value: c.totalRounds,
          items: const [10, 15, 20, 25, 50],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _draftConfig = c.copyWith(totalRounds: v));
          },
        ),
      ),
    ];
  }

  List<Widget> _buildCountUpFields(CountUpGameConfig c) {
    return [
      _FieldSection(
        label: 'ROUNDS',
        child: _RoundsDropdown(
          value: c.totalRounds,
          items: GameConfigurationConstants.countUpAllowedRounds,
          onChanged: (v) {
            if (v == null) return;
            setState(() => _draftConfig = c.copyWith(totalRounds: v));
          },
        ),
      ),
    ];
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _FieldSection extends StatelessWidget {
  const _FieldSection({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        child,
      ],
    );
  }
}

class _SegmentedOptionGroup<T> extends StatelessWidget {
  const _SegmentedOptionGroup({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Row(
        children: [
          for (int i = 0; i < values.length; i++)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                child: Material(
                  color: values[i] == selected
                      ? cs.primaryFixed
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelected(values[i]),
                    splashColor: cs.primaryFixed.withValues(alpha: AppTheme.opacityKineticIconBackground),
                    highlightColor: cs.primaryFixed.withValues(alpha: 0.08),
                    child: SizedBox(
                      height: 48,
                      child: Center(
                        child: Text(
                          labels[i],
                          style: tt.labelMedium?.copyWith(
                            color: values[i] == selected
                                ? AppColors.onPrimaryFixed
                                : cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepperContainer extends StatelessWidget {
  const _StepperContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: AppTheme.opacityGhostBorderLight),
        ),
      ),
      child: Center(child: child),
    );
  }
}

class _CustomScoreField extends StatelessWidget {
  const _CustomScoreField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: AppTheme.opacityGhostBorderLight),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: tt.bodyLarge?.copyWith(color: cs.onSurface),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Custom score',
          hintStyle: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          isDense: true,
        ),
        onChanged: (text) {
          final v = int.tryParse(text);
          if (v != null && v > 0) onChanged(v);
        },
      ),
    );
  }
}

class _RoundsDropdown extends StatelessWidget {
  const _RoundsDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final int? value;
  final List<int?> items;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: AppTheme.opacityGhostBorderLight),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.expand_more,
            color: cs.primaryFixed,
            semanticLabel: 'Expand rounds',
          ),
          dropdownColor: cs.surfaceContainerLow,
          style: tt.bodyLarge?.copyWith(color: cs.onSurface),
          items: items
              .map(
                (item) => DropdownMenuItem<int?>(
                  value: item,
                  child: Text(item == null ? '∞' : '$item'),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
