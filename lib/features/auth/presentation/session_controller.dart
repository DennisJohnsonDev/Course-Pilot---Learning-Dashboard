import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

final sessionControllerProvider = NotifierProvider<SessionController, bool>(
  SessionController.new,
);

/// App-wide signed-in flag. The router listens to it to guard routes.
class SessionController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> restore() async {
    state = await ref.read(authRepositoryProvider).hasSession();
  }

  Future<void> signIn({required String email, required String password}) async {
    await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);
    state = true;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = false;
  }
}
