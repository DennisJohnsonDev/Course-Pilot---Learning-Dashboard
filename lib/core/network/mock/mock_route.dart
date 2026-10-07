import 'package:dio/dio.dart';

class MockResponse {
  const MockResponse(this.statusCode, [this.data]);

  final int statusCode;
  final Object? data;

  bool get isSuccessful => statusCode >= 200 && statusCode < 300;
}

class MockRequest {
  const MockRequest(this.options, this.pathParameters);

  final RequestOptions options;
  final Map<String, String> pathParameters;
}

/// [pathPattern] supports named segments, e.g. `/courses/:id`.
class MockRoute {
  const MockRoute({
    required this.method,
    required this.pathPattern,
    required this.handler,
  });

  final String method;
  final String pathPattern;
  final MockResponse Function(MockRequest request) handler;

  Map<String, String>? match(String method, String path) {
    if (method.toUpperCase() != this.method.toUpperCase()) return null;

    final patternSegments = _segments(pathPattern);
    final pathSegments = _segments(path);
    if (patternSegments.length != pathSegments.length) return null;

    final parameters = <String, String>{};
    for (var i = 0; i < patternSegments.length; i++) {
      final expected = patternSegments[i];
      final actual = pathSegments[i];
      if (expected.startsWith(':')) {
        parameters[expected.substring(1)] = Uri.decodeComponent(actual);
      } else if (expected != actual) {
        return null;
      }
    }
    return parameters;
  }

  static List<String> _segments(String path) =>
      Uri.parse(path).pathSegments.where((s) => s.isNotEmpty).toList();
}
