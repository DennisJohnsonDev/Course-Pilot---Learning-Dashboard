import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock_route.dart';

/// Each feature registers its mock endpoints here.
final mockRoutesProvider = Provider<List<MockRoute>>((ref) => const []);
