import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/network_inspector_config.dart';
import 'notification/network_inspector_notification_service.dart';
import 'presentation/screens/network_call_list_screen.dart';

/// Public entry point for the Network Inspector package.
///
/// ```dart
/// NetworkInspector.initialize(navigatorKey: navigatorKey);
/// dio.interceptors.add(NetworkInspectorInterceptor());
/// ```
///
/// Every method here is a no-op outside [kDebugMode] — a release build
/// never allocates a repository, never shows a notification, and never
/// builds the inspector UI.
class NetworkInspector {
  const NetworkInspector._();

  /// Observer from a previous [initialize] call, kept around so it can be
  /// unregistered if [initialize] runs again (e.g. hot restart in tests)
  /// instead of leaking a duplicate observer.
  static _NotificationLifecycleObserver? _lifecycleObserver;

  /// Configures the inspector. Call this once during app bootstrap, before
  /// the first request that should be captured fires.
  ///
  /// - [navigatorKey]: the app's root navigator key, used so the notification
  ///   can open the inspector from whichever screen is currently showing.
  /// - [appName]: the host app's name, shown in the ongoing notification
  ///   title (e.g. "Chandragiri Chucker") so it's identifiable when several
  ///   debug builds are installed at once.
  /// - [maxLogs]: how many requests to retain before the oldest is evicted
  ///   (default 500).
  /// - [notificationsPlugin]: the host app's existing
  ///   `FlutterLocalNotificationsPlugin` instance. If omitted (or
  ///   [enableNotification] is false), no notification is shown, but
  ///   capturing and the in-app screens still work.
  static void initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required String appName,
    int maxLogs = 500,
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    bool enableNotification = true,
  }) {
    if (!kDebugMode) return;

    final notificationService = (enableNotification && notificationsPlugin != null)
        ? NetworkInspectorNotificationService(notificationsPlugin, appName: appName)
        : null;

    NetworkInspectorConfig.init(
      navigatorKey: navigatorKey,
      maxLogs: maxLogs,
      enableNotification: notificationService != null,
      notificationService: notificationService,
    );

    // Show the notification immediately (at "0 requests captured") so it's
    // visibly running from app launch rather than appearing only once the
    // first request completes.
    unawaited(notificationService?.show(NetworkInspectorConfig.instance.repository.all.length));

    if (_lifecycleObserver != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
      _lifecycleObserver = null;
    }
    if (notificationService != null) {
      final observer = _NotificationLifecycleObserver(notificationService);
      WidgetsBinding.instance.addObserver(observer);
      _lifecycleObserver = observer;
    }
  }

  /// Whether [payload] identifies a tap on the inspector's own notification
  /// — check this in the host app's `onDidReceiveNotificationResponse`
  /// handler and call [open] when it returns true.
  static bool isRelevantPayload(String? payload) {
    return kDebugMode && payload == NetworkInspectorNotificationService.payload;
  }

  /// Pushes the inspector's list screen onto the root navigator, from
  /// whichever screen is currently on top — used both by the notification
  /// tap handler and by any in-app "open inspector" affordance the host
  /// app wants to add.
  static void open() {
    if (!kDebugMode || !NetworkInspectorConfig.isInitialized) return;
    NetworkInspectorConfig.instance.navigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => const NetworkCallListScreen()),
    );
  }
}

/// Cancels the ongoing notification once the app is torn down.
///
/// The notification is posted as `ongoing`/`autoCancel: false` so it can't
/// be swiped away by accident while the app is running (see
/// [NetworkInspectorNotificationService]), but nothing else ever calls
/// [NetworkInspectorNotificationService.cancel] — without this observer the
/// notification would be stuck forever once the app is closed or removed
/// from recents, since it isn't tied to a real Android foreground service
/// that the OS would clean up on its own.
class _NotificationLifecycleObserver extends WidgetsBindingObserver {
  _NotificationLifecycleObserver(this._notificationService);

  final NetworkInspectorNotificationService _notificationService;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(_notificationService.cancel());
    }
  }
}
