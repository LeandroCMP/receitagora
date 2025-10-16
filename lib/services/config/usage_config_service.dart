import 'dart:async';

import 'usage_config.dart';

abstract class UsageConfigService {
  Future<void> ensureInitialized();
  Future<void> get ready;

  UsageConfig get current;
  Stream<UsageConfig> get stream;
}
