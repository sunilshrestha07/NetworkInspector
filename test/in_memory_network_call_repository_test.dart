import 'package:flutter_test/flutter_test.dart';
import 'package:network_inspector/src/data/models/http_method.dart';
import 'package:network_inspector/src/data/models/network_call.dart';
import 'package:network_inspector/src/data/repositories/in_memory_network_call_repository.dart';

NetworkCall _call(String id) => NetworkCall(
      id: id,
      method: HttpMethod.get,
      baseUrl: 'https://api.example.com',
      path: '/users',
      fullUrl: 'https://api.example.com/users',
      startTime: DateTime(2026, 1, 1),
    );

void main() {
  setUp(InMemoryNetworkCallRepository.resetForTesting);

  test('evicts the oldest entry once maxLogs is exceeded', () {
    final repo = InMemoryNetworkCallRepository.instance(maxLogs: 3);

    repo.add(_call('1'));
    repo.add(_call('2'));
    repo.add(_call('3'));
    repo.add(_call('4'));

    expect(repo.all.map((call) => call.id), ['2', '3', '4']);
    expect(repo.all.length, 3);
  });

  test('clear removes everything', () {
    final repo = InMemoryNetworkCallRepository.instance(maxLogs: 5);
    repo.add(_call('1'));

    repo.clear();

    expect(repo.all, isEmpty);
  });

  test('instance() returns the same singleton across calls', () {
    final first = InMemoryNetworkCallRepository.instance(maxLogs: 10);
    final second = InMemoryNetworkCallRepository.instance(maxLogs: 999);

    expect(identical(first, second), isTrue);
    expect(second.maxLogs, 10, reason: 'maxLogs is fixed at first creation');
  });

  test('update replaces the call with a matching id', () {
    final repo = InMemoryNetworkCallRepository.instance(maxLogs: 5);
    final call = _call('1');
    repo.add(call);

    repo.update(call.copyWith(statusCode: 200, endTime: DateTime(2026, 1, 1, 0, 0, 1)));

    expect(repo.all.single.statusCode, 200);
    expect(repo.all.single.isComplete, isTrue);
  });

  test('update is a no-op when no call matches the id', () {
    final repo = InMemoryNetworkCallRepository.instance(maxLogs: 5);
    repo.add(_call('1'));

    repo.update(_call('does-not-exist').copyWith(statusCode: 500));

    expect(repo.all.single.statusCode, isNull);
  });

  test('remove deletes a call by id', () {
    final repo = InMemoryNetworkCallRepository.instance(maxLogs: 5);
    repo.add(_call('1'));
    repo.add(_call('2'));

    repo.remove('1');

    expect(repo.all.map((call) => call.id), ['2']);
  });

  test('revision is bumped on add, update, remove and clear', () {
    final repo = InMemoryNetworkCallRepository.instance(maxLogs: 5);
    final revisions = <int>[];
    repo.revision.addListener(() => revisions.add(repo.revision.value));

    final call = _call('1');
    repo.add(call);
    repo.update(call.copyWith(statusCode: 200));
    repo.remove('1');
    repo.add(_call('2'));
    repo.clear();

    expect(revisions.length, 5);
    expect(revisions, [1, 2, 3, 4, 5]);
  });
}
