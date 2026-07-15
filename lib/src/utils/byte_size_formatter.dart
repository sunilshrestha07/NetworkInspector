/// Formatting helpers for byte sizes and durations, shared by every card
/// and detail-page widget that displays request/response metadata.
extension ByteSizeFormatter on int {
  /// Formats this many bytes as `B`, `KB` or `MB` with up to 1 decimal
  /// place, e.g. `842 B`, `3.4 KB`, `1.2 MB`.
  String toReadableSize() {
    final bytes = this;
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Formatting helpers for request/response durations.
extension DurationFormatter on Duration {
  /// Formats this duration as `<N> ms` under one second, otherwise
  /// `<N.N> s`.
  String toReadableDuration() {
    if (inMilliseconds < 1000) return '$inMilliseconds ms';
    return '${(inMilliseconds / 1000).toStringAsFixed(2)} s';
  }
}
