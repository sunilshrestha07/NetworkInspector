import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/network_inspector_config.dart';
import '../../data/models/network_call.dart';
import '../../data/repositories/network_call_repository.dart';

/// Bridges [NetworkCallRepository] (a plain Dart singleton) to Flutter's
/// widget layer as a [ChangeNotifier].
///
/// The interceptor can append/replace calls many times within a single
/// microtask (e.g. a burst of parallel requests all completing together);
/// this store coalesces those into a single [notifyListeners] call per
/// microtask instead of rebuilding the list once per capture, which is
/// what keeps the list screen smooth past 1000+ requests.
class NetworkCallStore extends ChangeNotifier {
  NetworkCallStore(this._repository) {
    _repository.revision.addListener(_onRevisionChanged);
  }

  /// Convenience constructor reading the repository from the active
  /// [NetworkInspectorConfig].
  factory NetworkCallStore.fromConfig() =>
      NetworkCallStore(NetworkInspectorConfig.instance.repository);

  final NetworkCallRepository _repository;
  bool _notifyScheduled = false;

  /// All captured calls, oldest first. Filtering/sorting for display is the
  /// job of [NetworkCallFilterController], not this store.
  List<NetworkCall> get calls => _repository.all;

  void togglePinned(NetworkCall call) {
    _repository.update(call.copyWith(pinned: !call.pinned));
  }

  void delete(String id) => _repository.remove(id);

  void clearAll() => _repository.clear();

  void _onRevisionChanged() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _repository.revision.removeListener(_onRevisionChanged);
    super.dispose();
  }
}
