sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message =
        'You appear to be offline. Check your connection and try again.',
  ]);
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure([
    super.message = 'The request took too long. Please try again.',
  ]);
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

final class ServerFailure extends AppFailure {
  const ServerFailure({
    String message = 'Something went wrong on our end. Please try again later.',
    this.statusCode,
  }) : super(message);

  final int? statusCode;
}

final class CacheFailure extends AppFailure {
  const CacheFailure([super.message = 'Saved data could not be read.']);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([
    super.message = 'Something unexpected happened. Please try again.',
  ]);
}
