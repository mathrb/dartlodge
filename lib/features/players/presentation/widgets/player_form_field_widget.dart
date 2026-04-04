import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayerFormFieldWidget extends StatelessWidget {
  const PlayerFormFieldWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    this.errorText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      maxLength: 30,
      inputFormatters: [LengthLimitingTextInputFormatter(30)],
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted(),
      decoration: InputDecoration(
        labelText: 'Name',
        errorText: errorText,
      ),
    );
  }
}
