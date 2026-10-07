import 'user.dart';

class LoginResponse {
  const LoginResponse({required this.accessToken, required this.user});

  factory LoginResponse.fromJson(Map<String, Object?> json) => LoginResponse(
    accessToken: json['accessToken']! as String,
    user: User.fromJson(json['user']! as Map<String, Object?>),
  );

  final String accessToken;
  final User user;
}
