import 'package:flutter/material.dart';
import '../utils/app_spacing.dart';

/// A shared error widget for `AsyncValue.when()` error branches.
///
/// Without [title]: renders a compact message + TextButton — use inside
/// sections or height-constrained widgets.
///
/// With [title]: renders icon + title + message + ElevatedButton — use at
/// page/scaffold level where the error is the primary content.
class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String? title;

  const ErrorRetryWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (title == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: AppSpacing.space2),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: AppSpacing.space4),
          Text(title!, style: tt.titleLarge),
          const SizedBox(height: AppSpacing.space2),
          Text(message, style: tt.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.space4),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
