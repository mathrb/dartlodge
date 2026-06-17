import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../providers/players_provider.dart';
import '../state/player_form_state.dart';
import '../widgets/player_form_field_widget.dart';

class CreatePlayerPage extends ConsumerStatefulWidget {
  const CreatePlayerPage({super.key});

  @override
  ConsumerState<CreatePlayerPage> createState() => _CreatePlayerPageState();
}

class _CreatePlayerPageState extends ConsumerState<CreatePlayerPage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    ref.invalidate(createPlayerProvider);
    super.dispose();
  }

  void _submit() {
    ref.read(createPlayerProvider.notifier).submit();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PlayerFormState>(createPlayerProvider, (prev, next) {
      final wasSubmitting = prev?.isSubmitting ?? false;
      if (wasSubmitting && !next.isSubmitting && next.nameError == null) {
        context.pop();
      }
    });

    final state = ref.watch(createPlayerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.playersNewPlayer)),
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
                  ref.read(createPlayerProvider.notifier).setName(v),
              onSubmitted: _submit,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.isSubmitting ? null : _submit,
              child: Text(l10n.playersCreatePlayer),
            ),
          ],
        ),
      ),
    );
  }
}
