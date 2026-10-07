abstract final class AppConfig {
  static const String apiBaseUrl = 'https://api.coursepilot.app/v1';

  // No real backend exists; requests are answered by MockApiInterceptor.
  static const bool useMockApi = true;
  static const Duration mockLatency = Duration(milliseconds: 700);

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
