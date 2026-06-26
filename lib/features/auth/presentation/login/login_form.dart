import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import 'login_validator.dart';
import 'login_button.dart';

class LoginForm extends StatefulWidget {
  final Function(String email, String password) onSubmit;
  final bool isLoading;
  final String? errorMessage;

  const LoginForm({
    super.key,
    required this.onSubmit,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      widget.onSubmit(_emailController.text.trim(), _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.errorMessage != null) ...[
            Semantics(
              liveRegion: true,
              label: 'Pesan Kesalahan: ${widget.errorMessage}',
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x33FF4C51)
                      : const Color(0x11FF4C51),
                  border: Border.all(color: const Color(0x66FF4C51)),
                  borderRadius: AppRadius.smBorder,
                ),
                child: Text(
                  widget.errorMessage!,
                  style: TextStyle(
                    color: isDark ? Colors.red.shade300 : AppColors.danger,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            AppSpacing.vLg,
          ],
          Semantics(
            label: 'Input Email',
            textField: true,
            child: TextFormField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_passwordFocusNode);
              },
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: AppRadius.mdBorder),
              ),
              validator: LoginValidator.validateEmail,
              enabled: !widget.isLoading,
            ),
          ),
          AppSpacing.vLg,
          Semantics(
            label: 'Input Password',
            textField: true,
            child: TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscureText,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: Semantics(
                  label: _obscureText
                      ? 'Tampilkan kata sandi'
                      : 'Sembunyikan kata sandi',
                  button: true,
                  child: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                border: OutlineInputBorder(borderRadius: AppRadius.mdBorder),
              ),
              validator: LoginValidator.validatePassword,
              enabled: !widget.isLoading,
            ),
          ),
          AppSpacing.vXl,
          LoginButton(onPressed: _submit, isLoading: widget.isLoading),
        ],
      ),
    );
  }
}
