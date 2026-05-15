import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete player?'),
        content:
            Text('Delete ${widget.currentName}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final ok = await ref
        .read(editPlayerProvider.notifier)
        .deletePlayer(widget.playerId);

    if (!mounted) return;
    if (ok) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(GameRoutes.players);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete a player with game history'),
        ),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Player')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlayerFormFieldWidget(
              controller: _controller,
              focusNode: _focusNode,
              errorText: state.nameError,
              onChanged: (v) =>
                  ref.read(editPlayerProvider.notifier).setName(v),
              onSubmitted: _save,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.isSubmitting ? null : _save,
              child: const Text('Save'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: state.isSubmitting ? null : _confirmDelete,
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                'Delete player',
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
