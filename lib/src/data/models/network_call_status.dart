/// The lifecycle/result state of a captured [NetworkCall].
enum NetworkCallStatus {
  /// Request sent, response not yet received.
  pending,

  /// 2xx response.
  success,

  /// 3xx response.
  redirect,

  /// 4xx response.
  clientError,

  /// 5xx response.
  serverError,

  /// Transport-level failure (no status code): DNS, connect, timeout, etc.
  error,

  /// The request was cancelled via a [CancelToken] before completing.
  cancelled;

  /// Derives a status from an HTTP status code.
  factory NetworkCallStatus.fromStatusCode(int? statusCode) {
    if (statusCode == null) return NetworkCallStatus.pending;
    if (statusCode >= 200 && statusCode < 300) return NetworkCallStatus.success;
    if (statusCode >= 300 && statusCode < 400) return NetworkCallStatus.redirect;
    if (statusCode >= 400 && statusCode < 500) return NetworkCallStatus.clientError;
    if (statusCode >= 500 && statusCode < 600) return NetworkCallStatus.serverError;
    return NetworkCallStatus.error;
  }

  /// Whether this status represents a "successful" completion (2xx).
  bool get isSuccess => this == NetworkCallStatus.success;

  /// Whether this status represents any kind of failure (4xx/5xx/transport error).
  bool get isError => this == NetworkCallStatus.clientError ||
      this == NetworkCallStatus.serverError ||
      this == NetworkCallStatus.error;
}
