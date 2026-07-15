import 'package:flutter/foundation.dart';

import '../../data/models/http_method.dart';
import '../../data/models/network_call.dart';

/// Quick status-class filter chips, applied with OR semantics against each
/// other and AND semantics against the method filter and search text.
enum StatusFilter {
  success,
  error,
  range2xx,
  range3xx,
  range4xx,
  range5xx;

  String get label {
    switch (this) {
      case StatusFilter.success:
        return 'Success';
      case StatusFilter.error:
        return 'Error';
      case StatusFilter.range2xx:
        return '2xx';
      case StatusFilter.range3xx:
        return '3xx';
      case StatusFilter.range4xx:
        return '4xx';
      case StatusFilter.range5xx:
        return '5xx';
    }
  }
}

/// Single-select ordering applied after filtering.
enum SortMode {
  newest,
  oldest,
  fastest,
  slowest,
  largest;

  String get label {
    switch (this) {
      case SortMode.newest:
        return 'Newest';
      case SortMode.oldest:
        return 'Oldest';
      case SortMode.fastest:
        return 'Fastest';
      case SortMode.slowest:
        return 'Slowest';
      case SortMode.largest:
        return 'Largest';
    }
  }
}

/// Holds the list screen's search text, method/status chip selections and
/// sort mode, and applies them to a list of calls.
///
/// This is pure/stateless with respect to the calls themselves — it never
/// holds a reference to [NetworkCallStore]'s data, only the *criteria* — so
/// [apply] can safely be called on every rebuild without caching bugs.
class NetworkCallFilterController extends ChangeNotifier {
  String _searchText = '';
  final Set<HttpMethod> _methodFilters = <HttpMethod>{};
  final Set<StatusFilter> _statusFilters = <StatusFilter>{};
  SortMode _sortMode = SortMode.newest;

  String get searchText => _searchText;
  Set<HttpMethod> get methodFilters => Set.unmodifiable(_methodFilters);
  Set<StatusFilter> get statusFilters => Set.unmodifiable(_statusFilters);
  SortMode get sortMode => _sortMode;

  bool get hasActiveFilters =>
      _searchText.isNotEmpty || _methodFilters.isNotEmpty || _statusFilters.isNotEmpty;

  void setSearchText(String value) {
    if (_searchText == value) return;
    _searchText = value;
    notifyListeners();
  }

  void toggleMethod(HttpMethod method) {
    if (!_methodFilters.remove(method)) _methodFilters.add(method);
    notifyListeners();
  }

  void toggleStatus(StatusFilter filter) {
    if (!_statusFilters.remove(filter)) _statusFilters.add(filter);
    notifyListeners();
  }

  void setSortMode(SortMode mode) {
    if (_sortMode == mode) return;
    _sortMode = mode;
    notifyListeners();
  }

  void clearFilters() {
    _searchText = '';
    _methodFilters.clear();
    _statusFilters.clear();
    _sortMode = SortMode.newest;
    notifyListeners();
  }

  /// Returns a new, filtered and sorted list — [calls] itself is untouched.
  List<NetworkCall> apply(List<NetworkCall> calls) {
    Iterable<NetworkCall> result = calls;

    final needle = _searchText.trim().toLowerCase();
    if (needle.isNotEmpty) {
      result = result.where((call) => call.searchHaystack.contains(needle));
    }

    if (_methodFilters.isNotEmpty) {
      result = result.where((call) => _methodFilters.contains(call.method));
    }

    if (_statusFilters.isNotEmpty) {
      result = result.where(
        (call) => _statusFilters.any((filter) => _matches(call, filter)),
      );
    }

    final sorted = result.toList(growable: false).toList();
    sorted.sort(_comparator);
    return sorted;
  }

  bool _matches(NetworkCall call, StatusFilter filter) {
    final code = call.statusCode ?? 0;
    switch (filter) {
      case StatusFilter.success:
        return call.status.isSuccess;
      case StatusFilter.error:
        return call.status.isError;
      case StatusFilter.range2xx:
        return code >= 200 && code < 300;
      case StatusFilter.range3xx:
        return code >= 300 && code < 400;
      case StatusFilter.range4xx:
        return code >= 400 && code < 500;
      case StatusFilter.range5xx:
        return code >= 500 && code < 600;
    }
  }

  int _comparator(NetworkCall a, NetworkCall b) {
    switch (_sortMode) {
      case SortMode.newest:
        return b.startTime.compareTo(a.startTime);
      case SortMode.oldest:
        return a.startTime.compareTo(b.startTime);
      case SortMode.fastest:
        return _durationMs(a).compareTo(_durationMs(b));
      case SortMode.slowest:
        return _durationMs(b).compareTo(_durationMs(a));
      case SortMode.largest:
        return _totalSize(b).compareTo(_totalSize(a));
    }
  }

  int _durationMs(NetworkCall call) => call.duration?.inMilliseconds ?? -1;

  int _totalSize(NetworkCall call) => call.requestSizeBytes + call.responseSizeBytes;
}
