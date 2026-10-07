import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/pressable.dart';
import '../data/auth_mock_routes.dart';
import 'login_view_model.dart';
import 'widgets/login_failure_message.dart';
import 'widgets/password_field.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  static const _maxContentWidth = 420.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    final viewModel = ref.read(loginViewModelProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 64),
                  const Entrance(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _AppMark(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Entrance(
                    index: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back',
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Sign in to pick up where you left off.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Entrance(
                    index: 2,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            onChanged: viewModel.updateEmail,
                            readOnly: state.isSubmitting,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              hintText: 'Email',
                              errorText: state.emailError,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PasswordField(
                            onChanged: viewModel.updatePassword,
                            onSubmitted: viewModel.submit,
                            readOnly: state.isSubmitting,
                            errorText: state.passwordError,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: state.failureMessage == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.lg),
                            child: LoginFailureMessage(state.failureMessage!),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Entrance(
                    index: 3,
                    child: Pressable(
                      child: FilledButton(
                        onPressed: viewModel.submit,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: state.isSubmitting
                              ? SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : const Text('Sign In'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Entrance(
                    index: 4,
                    child: Text(
                      'Demo account: ${DemoAccount.email} · ${DemoAccount.password}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppMark extends StatelessWidget {
  const _AppMark();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(CupertinoIcons.book_fill, color: colors.onPrimary, size: 24),
    );
  }
}
