# network_inspector

A from-scratch, Chucker-style debug network inspector for Flutter apps using
Dio. Captures every request/response through a Dio interceptor, keeps a
bounded in-memory log, and exposes a Material 3 UI to search, filter and
inspect traffic.

Debug-only by construction: every public entry point checks `kDebugMode`
first and does nothing in a release build.

## Setup

```dart
NetworkInspector.initialize(
  navigatorKey: navigatorKey, // your app's root GlobalKey<NavigatorState>
  appName: 'Chandragiri', // shown in the notification, e.g. "Chandragiri Chucker"
  notificationsPlugin: flutterLocalNotificationsPlugin, // optional
);

dio.interceptors.add(NetworkInspectorInterceptor());
```

Route notification taps to the inspector:

```dart
onDidReceiveNotificationResponse: (response) {
  if (NetworkInspector.isRelevantPayload(response.payload)) {
    NetworkInspector.open();
  }
},
```

## Scope

This is Phase 1: capture, in-memory storage, search/filter list, tabbed
detail page (Overview/Request/Response), cURL generation, and the
long-press action sheet (copy/share/retry/pin/delete).

Deferred to a later phase: statistics screen, waterfall timeline, HAR/CSV/
ZIP export, JWT decoding, XML/HTML/image/binary response viewers, response
diffing, endpoint grouping, optional persistent storage, JSON syntax
highlighting with search/line numbers, Edit-and-Resend, Favorite, and
Export-from-bottom-sheet.
