import 'package:flutter_test/flutter_test.dart';
import 'package:network_inspector/src/data/models/http_method.dart';
import 'package:network_inspector/src/data/models/network_call.dart';
import 'package:network_inspector/src/presentation/controllers/network_call_filter_controller.dart';

NetworkCall _call({
  required String id,
  HttpMethod method = HttpMethod.get,
  int? statusCode,
  required DateTime startTime,
  DateTime? endTime,
  String path = '/users',
  int requestSize = 0,
  int responseSize = 0,
}) {
  return NetworkCall(
    id: id,
    method: method,
    baseUrl: 'https://api.example.com',
    path: path,
    fullUrl: 'https://api.example.com$path',
    startTime: startTime,
    endTime: endTime,
    statusCode: statusCode,
    requestSizeBytes: requestSize,
    responseSizeBytes: responseSize,
  );
}

void main() {
  final now = DateTime(2026, 1, 1, 12);

  test('search matches across the url/path', () {
    final controller = NetworkCallFilterController();
    final calls = [
      _call(id: '1', path: '/users', startTime: now),
      _call(id: '2', path: '/accounts', startTime: now),
    ];

    controller.setSearchText('accounts');

    expect(controller.apply(calls).map((c) => c.id), ['2']);
  });

  test('method filter uses OR semantics across selected methods', () {
    final controller = NetworkCallFilterController();
    final calls = [
      _call(id: '1', method: HttpMethod.get, startTime: now),
      _call(id: '2', method: HttpMethod.post, startTime: now),
      _call(id: '3', method: HttpMethod.delete, startTime: now),
    ];

    controller
      ..toggleMethod(HttpMethod.get)
      ..toggleMethod(HttpMethod.delete);

    expect(controller.apply(calls).map((c) => c.id).toSet(), {'1', '3'});
  });

  test('newest sort orders by startTime descending (default)', () {
    final controller = NetworkCallFilterController();
    final calls = [
      _call(id: 'old', startTime: now.subtract(const Duration(minutes: 5))),
      _call(id: 'new', startTime: now),
    ];

    expect(controller.apply(calls).map((c) => c.id), ['new', 'old']);
  });

  test('oldest sort orders by startTime ascending', () {
    final controller = NetworkCallFilterController()..setSortMode(SortMode.oldest);
    final calls = [
      _call(id: 'old', startTime: now.subtract(const Duration(minutes: 5))),
      _call(id: 'new', startTime: now),
    ];

    expect(controller.apply(calls).map((c) => c.id), ['old', 'new']);
  });

  test('slowest sort orders by duration descending', () {
    final controller = NetworkCallFilterController()..setSortMode(SortMode.slowest);
    final calls = [
      _call(id: 'fast', startTime: now, endTime: now.add(const Duration(milliseconds: 50))),
      _call(id: 'slow', startTime: now, endTime: now.add(const Duration(milliseconds: 500))),
    ];

    expect(controller.apply(calls).map((c) => c.id), ['slow', 'fast']);
  });

  test('largest sort orders by combined request+response size descending', () {
    final controller = NetworkCallFilterController()..setSortMode(SortMode.largest);
    final calls = [
      _call(id: 'small', startTime: now, requestSize: 10, responseSize: 10),
      _call(id: 'big', startTime: now, requestSize: 1000, responseSize: 2000),
    ];

    expect(controller.apply(calls).map((c) => c.id), ['big', 'small']);
  });

  test('status filters use OR semantics against each other', () {
    final controller = NetworkCallFilterController();
    final calls = [
      _call(id: 'ok', startTime: now, statusCode: 200, endTime: now),
      _call(id: 'notfound', startTime: now, statusCode: 404, endTime: now),
      _call(id: 'servererr', startTime: now, statusCode: 500, endTime: now),
    ];

    controller
      ..toggleStatus(StatusFilter.success)
      ..toggleStatus(StatusFilter.range5xx);

    expect(controller.apply(calls).map((c) => c.id).toSet(), {'ok', 'servererr'});
  });

  test('clearFilters resets search, method/status filters and sort mode', () {
    final controller = NetworkCallFilterController()
      ..setSearchText('accounts')
      ..toggleMethod(HttpMethod.post)
      ..toggleStatus(StatusFilter.error)
      ..setSortMode(SortMode.slowest);

    controller.clearFilters();

    expect(controller.searchText, isEmpty);
    expect(controller.methodFilters, isEmpty);
    expect(controller.statusFilters, isEmpty);
    expect(controller.sortMode, SortMode.newest);
    expect(controller.hasActiveFilters, isFalse);
  });
}
