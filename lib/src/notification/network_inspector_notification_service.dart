import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Shows and updates the "&lt;app name&gt; Chucker" ongoing notification.
///
/// This is intentionally *not* a native Android foreground service: it
/// reuses the host app's existing [FlutterLocalNotificationsPlugin]
/// instance and shows an "ongoing" (`ongoing: true`, `autoCancel: false`)
/// notification, which the system will not let the user swipe away while
/// the app process is alive. It does not survive the OS killing the app's
/// process the way a true foreground service would — that tradeoff was a
/// deliberate choice to avoid adding a native Android `<service>` and
/// `FOREGROUND_SERVICE` permission for a debug-only tool.
class NetworkInspectorNotificationService {
  NetworkInspectorNotificationService(this._plugin, {String? appName})
      : _appNameOverride = appName;

  final FlutterLocalNotificationsPlugin _plugin;

  /// Host app's name to show in the notification title, e.g. "Chandragiri
  /// Chucker". If not supplied at construction, it's read automatically
  /// from the host app's own package info (the same way the notification's
  /// icon is picked up automatically from the host app, with no explicit
  /// config needed) and cached here.
  String? _appNameOverride;

  Future<String> _resolveAppName() async {
    final override = _appNameOverride;
    if (override != null) return override;
    final info = await PackageInfo.fromPlatform();
    return _appNameOverride = info.appName;
  }

  /// Fixed notification id so every call to [show] updates the same
  /// notification instead of stacking new ones.
  static const int notificationId = 987654321;

  static const String channelId = 'network_inspector_channel';
  static const String channelName = 'Network Inspector';
  static const String channelDescription =
      'Persistent notification showing captured network traffic while debugging.';

  /// Payload attached to the notification, checked by
  /// [NetworkInspector.isRelevantPayload] to route notification taps to the
  /// inspector regardless of which screen the app is currently showing.
  static const String payload = 'network_inspector://open';

  /// Shows (or refreshes) the ongoing notification with the current
  /// captured-request [count].
  Future<void> show(int count) async {
    final appName = await _resolveAppName();
    return _plugin.show(
      notificationId,
      '$appName Chucker',
      '$count request${count == 1 ? '' : 's'} captured',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          showWhen: false,
          playSound: false,
          enableVibration: false,
          importance: Importance.low,
          priority: Priority.low,
          category: AndroidNotificationCategory.service,
        ),
      ),
      payload: payload,
    );
  }

  /// Removes the notification, e.g. if the inspector is explicitly
  /// disabled at runtime.
  Future<void> cancel() => _plugin.cancel(notificationId);
}
