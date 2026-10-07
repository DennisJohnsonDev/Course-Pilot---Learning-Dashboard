import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.onChanged,
    required this.onSubmitted,
    this.readOnly = false,
    this.errorText,
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final bool readOnly;
  final String? errorText;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: widget.onChanged,
      onSubmitted: (_) => widget.onSubmitted(),
      readOnly: widget.readOnly,
      obscureText: _isObscured,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        hintText: 'Password',
        errorText: widget.errorText,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _isObscured = !_isObscured),
          tooltip: _isObscured ? 'Show password' : 'Hide password',
          icon: Icon(
            _isObscured ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
