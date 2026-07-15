import 'package:flutter/widgets.dart';

import '../data/repositories/in_memory_network_call_repository.dart';
import '../data/repositories/network_call_repository.dart';
import '../notification/network_inspector_notification_service.dart';

/// Process-wide configuration set once by `NetworkInspector.initialize()`.
///
/// Everything else in the package (the interceptor, the store, the
/// screens) reads from this singleton rather than being threaded through
/// constructor parameters, so `NetworkInspectorInterceptor()` can be
/// instantiated with a bare no-arg constructor as the public API promises.
class NetworkInspectorConfig {
  NetworkInspectorConfig._({
    required this.navigatorKey,
    required this.maxLogs,
    required this.repository,
    required this.enableNotification,
    this.notificationService,
  });

  static NetworkInspectorConfig? _instance;

  /// Whether `NetworkInspector.initialize()` has run yet.
  static bool get isInitialized => _instance != null;

  /// The active configuration. Throws if [isInitialized] is false — callers
  /// that must tolerate an uninitialized package (e.g. the interceptor,
  /// which may be wired into a Dio client before `initialize()` runs later
  /// in app bootstrap) should check [isInitialized] first instead of
  /// catching this.
  static NetworkInspectorConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError(
        'NetworkInspector.initialize() must be called before this operation.',
      );
    }
    return config;
  }

  static void init({
    required GlobalKey<NavigatorState> navigatorKey,
    required int maxLogs,
    required bool enableNotification,
    NetworkInspectorNotificationService? notificationService,
  }) {
    _instance = NetworkInspectorConfig._(
      navigatorKey: navigatorKey,
      maxLogs: maxLogs,
      repository: InMemoryNetworkCallRepository.instance(maxLogs: maxLogs),
      enableNotification: enableNotification,
      notificationService: notificationService,
    );
  }

  /// Resets the singleton so tests get a clean, isolated configuration.
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
    // ignore: invalid_use_of_visible_for_testing_member
    InMemoryNetworkCallRepository.resetForTesting();
  }

  final GlobalKey<NavigatorState> navigatorKey;
  final int maxLogs;
  final NetworkCallRepository repository;
  final bool enableNotification;
  final NetworkInspectorNotificationService? notificationService;
}
