import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/network_call.dart';
import 'network_call_repository.dart';

/// A bounded, in-memory [NetworkCallRepository] backed by a [Queue].
///
/// A [Queue] (rather than a [List]) is used so the hot path — appending a
/// newly-completed call and evicting the oldest one once [maxLogs] is
/// exceeded — is a pair of O(1) operations ([Queue.addLast] /
/// [Queue.removeFirst]) instead of a `List.removeAt(0)`, which is O(n)
/// because every remaining element has to shift down.
///
/// This is a process-wide singleton: exactly one log should exist per app
/// run, shared by the interceptor (writer) and every inspector screen
/// (readers).
class InMemoryNetworkCallRepository implements NetworkCallRepository {
  InMemoryNetworkCallRepository._({required this.maxLogs});

  static InMemoryNetworkCallRepository? _instance;

  /// Returns the process-wide singleton, creating it on first access.
  ///
  /// [maxLogs] only takes effect the first time the singleton is created;
  /// later calls (once the interceptor is already running) reuse the
  /// existing instance so the cap can't silently change mid-session.
  static InMemoryNetworkCallRepository instance({int maxLogs = 500}) {
    return _instance ??= InMemoryNetworkCallRepository._(maxLogs: maxLogs);
  }

  /// Resets the singleton so tests get a clean repository per case.
  @visibleForTesting
  static void resetForTesting() => _instance = null;

  /// The maximum number of calls retained before the oldest is evicted.
  final int maxLogs;

  final Queue<NetworkCall> _calls = Queue<NetworkCall>();
  final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  @override
  ValueListenable<int> get revision => _revision;

  @override
  List<NetworkCall> get all => List.unmodifiable(_calls);

  @override
  void add(NetworkCall call) {
    _calls.addLast(call);
    while (_calls.length > maxLogs) {
      _calls.removeFirst();
    }
    _bump();
  }

  @override
  void update(NetworkCall call) {
    var found = false;
    final rebuilt = _calls.map((existing) {
      if (existing.id == call.id) {
        found = true;
        return call;
      }
      return existing;
    }).toList(growable: false);

    if (!found) return;

    _calls
      ..clear()
      ..addAll(rebuilt);
    _bump();
  }

  @override
  void remove(String id) {
    final before = _calls.length;
    _calls.removeWhere((call) => call.id == id);
    if (_calls.length != before) _bump();
  }

  @override
  void clear() {
    if (_calls.isEmpty) return;
    _calls.clear();
    _bump();
  }

  void _bump() => _revision.value++;
}
