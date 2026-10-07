import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock_route.dart';

/// Feature routes are supplied in `main.dart` so core never imports features.
final mockRoutesProvider = Provider<List<MockRoute>>((ref) => const []);
