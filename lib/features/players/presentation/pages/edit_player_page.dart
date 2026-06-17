import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../app/app_router.dart';
import '../providers/players_provider.dart';
import '../state/player_form_state.dart';
import '../widgets/player_form_field_widget.dart';

class EditPlayerPage extends ConsumerStatefulWidget {
  final String playerId;
  final String currentName;

  const EditPlayerPage({
    super.key,
    required this.playerId,
    required this.currentName,
  });

  @override
  ConsumerState<EditPlayerPage> createState() => _EditPlayerPageState();
}

class _EditPlayerPageState extends ConsumerState<EditPlayerPage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(editPlayerProvider.notifier)
          .setName(widget.currentName);
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    ref.invalidate(editPlayerProvider);
    super.dispose();
  }

  void _save() {
    ref.read(editPlayerProvider.notifier).submit(widget.playerId);
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.playersDeleteTitle),
        content: Text(l10n.playersDeleteConfirm(widget.currentName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final result = await ref
        .read(editPlayerProvider.notifier)
        .deletePlayer(widget.playerId);

    if (!mounted) return;
    switch (result) {
      case DeletePlayerSuccess():
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(GameRoutes.players);
        }
      case DeletePlayerHasGameHistory():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.playersCannotDeleteWithHistory)),
        );
      case DeletePlayerUnexpectedError():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.playersDeleteFailed)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PlayerFormState>(editPlayerProvider, (prev, next) {
      final wasSubmitting = prev?.isSubmitting ?? false;
      if (wasSubmitting && !next.isSubmitting && next.nameError == null) {
        context.pop();
      }
    });

    final state = ref.watch(editPlayerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.playersEditPlayer)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlayerFormFieldWidget(
              controller: _controller,
              focusNode: _focusNode,
              error: state.nameError,
              onChanged: (v) =>
                  ref.read(editPlayerProvider.notifier).setName(v),
              onSubmitted: _save,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.isSubmitting ? null : _save,
              child: Text(l10n.commonSave),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: state.isSubmitting ? null : _confirmDelete,
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                l10n.playersDeleteButton,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
