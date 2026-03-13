import 'package:flutter/material.dart';
import '../../../../core/utils/constants.dart';

class PracticeInputButtonsWidget extends StatelessWidget {
  const PracticeInputButtonsWidget({
    required this.gameType,
    required this.currentTarget,
    required this.onDartThrown,
    required this.enabled,
    this.doublesOnly = false,
    super.key,
  });

  final GameType gameType;
  final int? currentTarget;
  final void Function(String segment) onDartThrown;
  final bool enabled;
  final bool doublesOnly;

  @override
  Widget build(BuildContext context) {
    if (gameType == GameType.aroundTheClock) {
      return _AroundTheClockInputBar(
        n: currentTarget,
        doublesOnly: doublesOnly,
        enabled: enabled,
        onDartThrown: onDartThrown,
      );
    }

    // Generic 3-button row for other practice types
    final colorScheme = Theme.of(context).colorScheme;
    final n = currentTarget;
    final isBobs27 = gameType == GameType.bobs27;

    final buttons = [
      _ButtonSpec(
        label: n != null ? 'S-$n' : 'S',
        segment: n != null ? '$n' : 'S',
        dimmed: isBobs27,
      ),
      _ButtonSpec(
        label: n != null ? 'D-$n' : 'D',
        segment: n != null ? 'D$n' : 'D',
        dimmed: false,
      ),
      _ButtonSpec(
        label: n != null ? 'T-$n' : 'T',
        segment: n != null ? 'T$n' : 'T',
        dimmed: isBobs27,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: enabled ? () => onDartThrown(buttons[i].segment) : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  buttons[i].label,
                  style: buttons[i].dimmed
                      ? TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4))
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AroundTheClockInputBar extends StatelessWidget {
  const _AroundTheClockInputBar({
    required this.n,
    required this.doublesOnly,
    required this.enabled,
    required this.onDartThrown,
  });

  final int? n;
  final bool doublesOnly;
  final bool enabled;
  final void Function(String segment) onDartThrown;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final num = n ?? 1;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _AtcInputCell(
                label: 'S-$num',
                bgColor: colorScheme.surface,
                fgColor: colorScheme.onSurface,
                dotCount: 0,
                dimForeground: doublesOnly,
                enabled: enabled,
                onTap: () => onDartThrown('$num'),
              ),
            ),
            VerticalDivider(width: 1, color: colorScheme.outline),
            Expanded(
              child: _AtcInputCell(
                label: 'D-$num',
                bgColor: colorScheme.primaryContainer,
                fgColor: colorScheme.onPrimaryContainer,
                dotCount: 2,
                dimForeground: false,
                enabled: enabled,
                onTap: () => onDartThrown('D$num'),
              ),
            ),
            VerticalDivider(width: 1, color: colorScheme.outline),
            Expanded(
              child: _AtcInputCell(
                label: 'T-$num',
                bgColor: colorScheme.primary,
                fgColor: colorScheme.onPrimary,
                dotCount: 3,
                dimForeground: doublesOnly,
                enabled: enabled,
                onTap: () => onDartThrown('T$num'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtcInputCell extends StatelessWidget {
  const _AtcInputCell({
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.dotCount,
    required this.dimForeground,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final Color bgColor;
  final Color fgColor;
  final int dotCount;
  final bool dimForeground;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: dimForeground ? 0.38 : 1.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: fgColor,
                          height: 1.0,
                        ),
                      ),
                      if (dotCount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < dotCount; i++) ...[
                              if (i > 0) const SizedBox(width: 4),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: fgColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonSpec {
  const _ButtonSpec({
    required this.label,
    required this.segment,
    required this.dimmed,
  });

  final String label;
  final String segment;
  final bool dimmed;
}
