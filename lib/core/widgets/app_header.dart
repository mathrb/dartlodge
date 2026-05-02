import 'package:flutter/material.dart';
import 'package:dart_lodge/core/utils/app_text_styles.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';

/// App-wide top header row: logo, optional back button, and trailing action slot.
///
/// Use [boardMode] = true for game boards: renders a 64px black bar with white
/// icons suitable for use as [Scaffold.appBar]. The widget implements
/// [PreferredSizeWidget] in both modes.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.showBack = false,
    this.onBack,
    this.trailing,
    this.boardMode = false,
  });

  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// When true, renders the game-board style: 64 px black bar, white text/icons,
  /// kinetic splash, bottom border. Suitable for [Scaffold.appBar].
  /// When false (default), renders the standard content-area header.
  final bool boardMode;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return boardMode ? _buildBoardBar(context) : _buildContentHeader(context);
  }

  Widget _buildBoardBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Container(
        height: kToolbarHeight,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            if (showBack)
              InkWell(
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                splashColor: AppTheme.kineticSplashColor,
                highlightColor: AppTheme.kineticSplashColor,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    semanticLabel: 'Back',
                  ),
                ),
              ),
            if (showBack) const SizedBox(width: 16),
            Expanded(
              child: Text(
                'DARTLODGE',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: cs.primaryFixed,
                  letterSpacing: 4,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }



  Widget _buildContentHeader(BuildContext context) {
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
