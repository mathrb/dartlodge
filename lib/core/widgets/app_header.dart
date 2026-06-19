import 'package:flutter/material.dart';
import 'package:dart_lodge/core/utils/app_spacing.dart';
import 'package:dart_lodge/core/utils/app_text_styles.dart';

/// App-wide top header row: logo (or a page [title]), optional back button,
/// and trailing action slot.
///
/// Rendered inline as the first child of a page body (Scaffold → SafeArea →
/// scrollable/Column → AppHeader). Not a Scaffold.appBar — pages add SafeArea
/// at the body level so the header inherits the scaffold background and
/// horizontal padding from the parent scrollable.
///
/// [title] — when non-null, the header shows this page title (in `onSurface`)
/// instead of the brand logo, so sub-pages like Statistics read as titled
/// destinations consistent with Players/History (#599).
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.showBack = false,
    this.onBack,
    this.trailing,
    this.title,
  });

  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isTitled = title != null;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.space4,
        bottom: AppSpacing.space1,
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back, semanticLabel: 'Back'),
              color: cs.onSurface,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
          Expanded(
            child: Text(
              isTitled ? title! : 'DARTLODGE',
              style: AppTextStyles.headlineMedium.copyWith(
                color: isTitled ? cs.onSurface : cs.primaryFixed,
                letterSpacing: 1.5,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
