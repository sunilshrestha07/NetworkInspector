import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_inspector/src/core/network_inspector_config.dart';
import 'package:network_inspector/src/data/models/http_method.dart';
import 'package:network_inspector/src/data/models/network_call.dart';
import 'package:network_inspector/src/presentation/screens/network_call_list_screen.dart';

NetworkCall _call(String id, {HttpMethod method = HttpMethod.get, String path = '/users'}) {
  final now = DateTime.now();
  return NetworkCall(
    id: id,
    method: method,
    baseUrl: 'https://api.example.com',
    path: path,
    fullUrl: 'https://api.example.com$path',
    startTime: now,
    endTime: now.add(const Duration(milliseconds: 120)),
    statusCode: 200,
  );
}

void main() {
  setUp(() {
    NetworkInspectorConfig.resetForTesting();
    NetworkInspectorConfig.init(
      navigatorKey: GlobalKey<NavigatorState>(),
      maxLogs: 500,
      enableNotification: false,
    );
  });

  testWidgets('renders seeded calls and filters them via search', (tester) async {
    final repository = NetworkInspectorConfig.instance.repository;
    repository.add(_call('1', path: '/users'));
    repository.add(_call('2', path: '/accounts', method: HttpMethod.post));

    await tester.pumpWidget(const MaterialApp(home: NetworkCallListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('/users'), findsOneWidget);
    expect(find.text('/accounts'), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), 'accounts');
    await tester.pumpAndSettle();

    expect(find.text('/accounts'), findsOneWidget);
    expect(find.text('/users'), findsNothing);
  });

  testWidgets('shows an empty state when nothing has been captured', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NetworkCallListScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('No requests captured yet'), findsOneWidget);
  });

  testWidgets('method filter chip narrows the visible calls', (tester) async {
    final repository = NetworkInspectorConfig.instance.repository;
    repository.add(_call('1', path: '/users', method: HttpMethod.get));
    repository.add(_call('2', path: '/accounts', method: HttpMethod.post));

    await tester.pumpWidget(const MaterialApp(home: NetworkCallListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'POST'));
    await tester.pumpAndSettle();

    expect(find.text('/accounts'), findsOneWidget);
    expect(find.text('/users'), findsNothing);
  });
}
