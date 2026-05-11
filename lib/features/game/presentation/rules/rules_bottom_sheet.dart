import 'package:flutter/material.dart';
import 'package:dart_lodge/core/utils/app_text_styles.dart';

import 'game_rules.dart';
import 'rules_registry.dart';

Future<void> showRules(BuildContext context, String slug) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => RulesBottomSheet(slug: slug),
  );
}

class RulesBottomSheet extends StatelessWidget {
  const RulesBottomSheet({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final rules = rulesFor(slug);
    final cs = Theme.of(context).colorScheme;

    if (rules == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Text(
          'Rules unavailable.',
          style: AppTextStyles.bodyLarge.copyWith(color: cs.onSurface),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rules.title,
              style: AppTextStyles.headlineLarge.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              rules.tagline,
              style: AppTextStyles.bodyMedium.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            for (final section in rules.sections) ...[
              _SectionBlock(section: section),
              const SizedBox(height: 20),
            ],
            if (rules.relatedVariants.isNotEmpty) _VariantsBlock(
              variants: rules.relatedVariants,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section});

  final RulesSection section;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.heading,
          style: AppTextStyles.labelMedium.copyWith(
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 8),
        if (section.body.isNotEmpty)
          Text(
            section.body,
            style: AppTextStyles.bodyLarge.copyWith(color: cs.onSurface),
          ),
        if (section.body.isNotEmpty && section.bullets.isNotEmpty)
          const SizedBox(height: 8),
        for (final bullet in section.bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 9, right: 10),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    bullet,
                    style: AppTextStyles.bodyLarge.copyWith(color: cs.onSurface),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _VariantsBlock extends StatelessWidget {
  const _VariantsBlock({required this.variants});

  final List<RulesVariant> variants;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Related variants',
            style: AppTextStyles.labelMedium.copyWith(color: cs.primary),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < variants.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Text(
              variants[i].name,
              style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 2),
            Text(
              variants[i].summary,
              style: AppTextStyles.bodyMedium.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
