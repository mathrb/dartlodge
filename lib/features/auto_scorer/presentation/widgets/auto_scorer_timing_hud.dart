import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/features/auto_scorer/domain/diagnostics/pipeline_timings.dart';
import 'package:flutter/material.dart';

/// Debug timing overlay for the lag investigation (#377 §3). Shows the last
/// frame's stage split plus a rolling average and effective FPS, so we can read
/// off whether capture, detect (preprocess + inference), or the tracker
/// dominates. Pure presentation over the supplied samples; rendered only when
/// the diagnostics toggle is on. The phase→text mapping is intentionally terse.
class AutoScorerTimingHud extends StatelessWidget {
  /// Most recent frame's timings.
  final PipelineTimings last;

  /// Rolling window of recent frames (oldest→newest) for the average/FPS.
  final List<PipelineTimings> samples;

  /// Whether the preprocess A/B skip is active (raw bytes to the model).
  final bool skipPreprocess;

  const AutoScorerTimingHud({
    super.key,
    required this.last,
    required this.samples,
    required this.skipPreprocess,
  });

  Duration get _avgTotal {
    if (samples.isEmpty) return Duration.zero;
    final us =
        samples.fold<int>(0, (a, t) => a + t.total.inMicroseconds) ~/
            samples.length;
    return Duration(microseconds: us);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avg = _avgTotal;
    final fps = avg.inMicroseconds == 0
        ? 0.0
        : 1000000 / avg.inMicroseconds;
    String ms(Duration d) => '${d.inMilliseconds}';
    return DecoratedBox(
      decoration: BoxDecoration(
        // High-contrast overlay token pair (dark-on-light themes get a dark
        // chip, light-on-dark a light one) so the debug HUD stays legible over
        // the board without hardcoding raw colours.
        color: scheme.inverseSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: DefaultTextStyle(
          style: TextStyle(
            color: scheme.onInverseSurface,
            fontSize: 11,
            fontFamily: 'monospace',
            height: 1.3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('cap ${ms(last.capture)}  det ${ms(last.detect)}  '
                  'trk ${ms(last.track)}ms'),
              Text('avg ${ms(avg)}ms  ${StatFormatter.fmtDouble(fps)} fps'
                  '  (n=${samples.length})'),
              Text('preprocess: ${skipPreprocess ? 'SKIPPED (A/B)' : 'on'}'),
            ],
          ),
        ),
      ),
    );
  }
}
