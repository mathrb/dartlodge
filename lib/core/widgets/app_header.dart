import 'package:flutter/material.dart';
import 'package:dart_lodge/core/utils/app_text_styles.dart';

/// App-wide top header row: logo, optional back button, and trailing action slot.
///
/// Rendered inline as the first child of a page body (Scaffold → SafeArea →
/// scrollable/Column → AppHeader). Not a Scaffold.appBar — pages add SafeArea
/// at the body level so the header inherits the scaffold background and
/// horizontal padding from the parent scrollable.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.showBack = false,
    this.onBack,
    this.trailing,
  });

  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
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
              'DARTLODGE',
              style: AppTextStyles.headlineMedium.copyWith(
                color: cs.primaryFixed,
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
