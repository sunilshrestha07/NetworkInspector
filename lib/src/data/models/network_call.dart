import 'http_method.dart';
import 'network_call_status.dart';
import 'request_body_kind.dart';

/// An immutable snapshot of a single Dio request/response (or failure)
/// captured by [NetworkInspectorInterceptor].
///
/// Instances are created once `onRequest` fires (with `status == pending`)
/// and then replaced (via [copyWith]) with a completed instance once
/// `onResponse`/`onError` fires. The repository always stores the latest
/// instance for a given [id].
class NetworkCall {
  NetworkCall({
    required this.id,
    required this.method,
    required this.baseUrl,
    required this.path,
    required this.fullUrl,
    required this.startTime,
    this.pathParams = const {},
    this.queryParams = const {},
    this.requestHeaders = const {},
    this.requestCookies = const {},
    this.authorizationHeader,
    this.requestBody,
    this.requestBodyKind = RequestBodyKind.none,
    this.requestSizeBytes = 0,
    this.endTime,
    this.statusCode,
    this.responseHeaders = const {},
    this.responseCookies = const {},
    this.responseBody,
    this.responseSizeBytes = 0,
    this.error,
    this.stackTrace,
    this.isTimeout = false,
    this.isCancelled = false,
    this.protocolVersion,
    this.pinned = false,
  });

  /// Stable identifier assigned at request time; also used as the notifier
  /// payload key to jump straight to this call's detail page in the future.
  final String id;

  final HttpMethod method;
  final String baseUrl;
  final String path;
  final String fullUrl;

  final Map<String, String> pathParams;
  final Map<String, dynamic> queryParams;

  final Map<String, String> requestHeaders;
  final Map<String, String> requestCookies;
  final String? authorizationHeader;

  final Object? requestBody;
  final RequestBodyKind requestBodyKind;
  final int requestSizeBytes;

  final DateTime startTime;
  final DateTime? endTime;

  final int? statusCode;
  final Map<String, String> responseHeaders;
  final Map<String, String> responseCookies;
  final Object? responseBody;
  final int responseSizeBytes;

  final Object? error;
  final StackTrace? stackTrace;
  final bool isTimeout;
  final bool isCancelled;

  /// Best-effort HTTP protocol/version, when Dio's response metadata
  /// exposes it. Usually null: Dio does not surface real TLS/ALPN
  /// negotiation details, so this is populated only when a server echoes
  /// its protocol via a response header the app recognizes.
  final String? protocolVersion;

  final bool pinned;

  /// Whether a response (or error) has been recorded yet.
  bool get isComplete => endTime != null;

  Duration? get duration => endTime?.difference(startTime);

  NetworkCallStatus get status {
    if (isCancelled) return NetworkCallStatus.cancelled;
    if (!isComplete) return NetworkCallStatus.pending;
    if (error != null && statusCode == null) return NetworkCallStatus.error;
    return NetworkCallStatus.fromStatusCode(statusCode);
  }

  NetworkCall copyWith({
    DateTime? endTime,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Map<String, String>? responseCookies,
    Object? responseBody,
    bool responseBodyProvided = false,
    int? responseSizeBytes,
    Object? error,
    bool errorProvided = false,
    StackTrace? stackTrace,
    bool? isTimeout,
    bool? isCancelled,
    String? protocolVersion,
    bool? pinned,
  }) {
    return NetworkCall(
      id: id,
      method: method,
      baseUrl: baseUrl,
      path: path,
      fullUrl: fullUrl,
      startTime: startTime,
      pathParams: pathParams,
      queryParams: queryParams,
      requestHeaders: requestHeaders,
      requestCookies: requestCookies,
      authorizationHeader: authorizationHeader,
      requestBody: requestBody,
      requestBodyKind: requestBodyKind,
      requestSizeBytes: requestSizeBytes,
      endTime: endTime ?? this.endTime,
      statusCode: statusCode ?? this.statusCode,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseCookies: responseCookies ?? this.responseCookies,
      responseBody: responseBodyProvided ? responseBody : this.responseBody,
      responseSizeBytes: responseSizeBytes ?? this.responseSizeBytes,
      error: errorProvided ? error : this.error,
      stackTrace: stackTrace ?? this.stackTrace,
      isTimeout: isTimeout ?? this.isTimeout,
      isCancelled: isCancelled ?? this.isCancelled,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      pinned: pinned ?? this.pinned,
    );
  }

  /// A blob of text used by the list screen's search box: every field a
  /// user might plausibly search for, lowercased and concatenated once
  /// per call rather than re-derived on every keystroke.
  String get searchHaystack {
    final buffer = StringBuffer()
      ..write(fullUrl)
      ..write(' ')
      ..write(path)
      ..write(' ')
      ..write(method.label)
      ..write(' ')
      ..write(statusCode ?? '')
      ..write(' ')
      ..write(requestHeaders.entries.map((e) => '${e.key}:${e.value}').join(' '))
      ..write(' ')
      ..write(responseHeaders.entries.map((e) => '${e.key}:${e.value}').join(' '))
      ..write(' ')
      ..write(requestBody ?? '')
      ..write(' ')
      ..write(responseBody ?? '');
    return buffer.toString().toLowerCase();
  }
}
