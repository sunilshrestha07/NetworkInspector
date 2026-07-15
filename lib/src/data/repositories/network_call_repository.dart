import 'package:flutter/foundation.dart';

import '../models/network_call.dart';

/// Storage contract for captured [NetworkCall]s.
///
/// Phase 1 ships a single [InMemoryNetworkCallRepository] implementation;
/// this interface exists so an optional persistent-storage backend can be
/// swapped in later without touching the interceptor or presentation layers.
abstract class NetworkCallRepository {
  /// All calls currently held, oldest first.
  List<NetworkCall> get all;

  /// Bumped every time [all] changes (insert, update, delete, clear), so
  /// consumers can rebuild without holding a reference to individual calls.
  ValueListenable<int> get revision;

  /// Inserts a new call, evicting the oldest entry if the store is at
  /// capacity.
  void add(NetworkCall call);

  /// Replaces the call with a matching [NetworkCall.id], if present.
  void update(NetworkCall call);

  /// Removes the call with the given [id], if present.
  void remove(String id);

  /// Removes every stored call.
  void clear();
}
