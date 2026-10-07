enum LoginStatus { idle, submitting, success, failure }

class LoginState {
  const LoginState({
    this.email = '',
    this.password = '',
    this.showValidation = false,
    this.status = LoginStatus.idle,
    this.failureMessage,
  });

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final String email;
  final String password;
  final bool showValidation;
  final LoginStatus status;
  final String? failureMessage;

  bool get isSubmitting => status == LoginStatus.submitting;
  bool get isValid => _emailError == null && _passwordError == null;

  String? get emailError => showValidation ? _emailError : null;
  String? get passwordError => showValidation ? _passwordError : null;

  String? get _emailError {
    final value = email.trim();
    if (value.isEmpty) return 'Enter your email address.';
    if (!_emailPattern.hasMatch(value)) return 'Enter a valid email address.';
    return null;
  }

  String? get _passwordError =>
      password.isEmpty ? 'Enter your password.' : null;
}
