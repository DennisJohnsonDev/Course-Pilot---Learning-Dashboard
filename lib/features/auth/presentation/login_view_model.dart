import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import 'login_state.dart';
import 'session_controller.dart';

final loginViewModelProvider =
    NotifierProvider.autoDispose<LoginViewModel, LoginState>(
      LoginViewModel.new,
    );

class LoginViewModel extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  void updateEmail(String email) {
    state = LoginState(
      email: email,
      password: state.password,
      showValidation: state.showValidation,
    );
  }

  void updatePassword(String password) {
    state = LoginState(
      email: state.email,
      password: password,
      showValidation: state.showValidation,
    );
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;

    final validated = LoginState(
      email: state.email,
      password: state.password,
      showValidation: true,
    );
    if (!validated.isValid) {
      state = validated;
      return;
    }

    state = LoginState(
      email: validated.email,
      password: validated.password,
      showValidation: true,
      status: LoginStatus.submitting,
    );

    final failureMessage = await _signIn();
    if (!ref.mounted) return;

    state = LoginState(
      email: state.email,
      password: state.password,
      showValidation: true,
      status: failureMessage == null
          ? LoginStatus.success
          : LoginStatus.failure,
      failureMessage: failureMessage,
    );
  }

  Future<String?> _signIn() async {
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .signIn(email: state.email.trim(), password: state.password);
      return null;
    } on AppFailure catch (failure) {
      return failure.message;
    } catch (error, stackTrace) {
      debugPrint('Unexpected sign-in error: $error\n$stackTrace');
      return const UnknownFailure().message;
    }
  }
}
