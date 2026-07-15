import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network_inspector_config.dart';
import '../data/models/http_method.dart';
import '../data/models/network_call.dart';
import '../data/models/request_body_kind.dart';

/// A [Interceptor] that captures every request, response and error passing
/// through the [Dio] instance it's attached to, and records it with
/// [NetworkInspectorConfig.instance]'s repository.
///
/// Add it like any other Dio interceptor:
/// ```dart
/// dio.interceptors.add(NetworkInspectorInterceptor());
/// ```
///
/// Every callback is guarded by [kDebugMode] first, so in a release build
/// this interceptor does nothing but immediately call `handler.next(...)` —
/// no capturing, no allocation of a [NetworkCall], no repository access.
/// It also tolerates being added before `NetworkInspector.initialize()` has
/// run (a legitimate ordering in apps that build their Dio client during
/// dependency-injection setup, before the rest of app bootstrap): if the
/// package isn't initialized yet when a request fires, it's simply not
/// captured rather than throwing.
class NetworkInspectorInterceptor extends Interceptor {
  NetworkInspectorInterceptor();

  static const String _extraIdKey = '_network_inspector_call_id';

  int _sequence = 0;

  /// Calls in flight, keyed by the id stashed on their [RequestOptions].
  /// Looked up again in `onResponse`/`onError` to produce the completed
  /// [NetworkCall] via [NetworkCall.copyWith] without re-deriving the
  /// request-side fields.
  final Map<String, NetworkCall> _inFlight = <String, NetworkCall>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kDebugMode || !NetworkInspectorConfig.isInitialized) {
      return handler.next(options);
    }

    final id = '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';
    options.extra[_extraIdKey] = id;

    final call = _buildPendingCall(id, options);
    _inFlight[id] = call;

    NetworkInspectorConfig.instance.repository.add(call);
    _refreshNotification();

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!kDebugMode || !NetworkInspectorConfig.isInitialized) {
      return handler.next(response);
    }

    final id = response.requestOptions.extra[_extraIdKey] as String?;
    final pending = id == null ? null : _inFlight.remove(id);
    if (pending != null) {
      final responseBody = response.data;
      final responseHeaders = _flattenHeaders(response.headers.map);
      final completed = pending.copyWith(
        endTime: DateTime.now(),
        statusCode: response.statusCode,
        responseHeaders: responseHeaders,
        responseCookies: _extractCookiesFromHeaders(responseHeaders),
        responseBody: responseBody,
        responseBodyProvided: true,
        responseSizeBytes: _estimateSize(responseBody),
      );
      NetworkInspectorConfig.instance.repository.update(completed);
      _refreshNotification();
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!kDebugMode || !NetworkInspectorConfig.isInitialized) {
      return handler.next(err);
    }

    final id = err.requestOptions.extra[_extraIdKey] as String?;
    final pending = id == null ? null : _inFlight.remove(id);
    if (pending != null) {
      final response = err.response;
      final isTimeout = err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.sendTimeout ||
          err.type == DioExceptionType.receiveTimeout;
      final isCancelled = err.type == DioExceptionType.cancel;
      final responseHeaders =
          response == null ? const <String, String>{} : _flattenHeaders(response.headers.map);

      final completed = pending.copyWith(
        endTime: DateTime.now(),
        statusCode: response?.statusCode,
        responseHeaders: responseHeaders,
        responseCookies: _extractCookiesFromHeaders(responseHeaders),
        responseBody: response?.data,
        responseBodyProvided: response != null,
        responseSizeBytes: response == null ? 0 : _estimateSize(response.data),
        error: err.message ?? err.error?.toString() ?? err.type.name,
        errorProvided: true,
        stackTrace: err.stackTrace,
        isTimeout: isTimeout,
        isCancelled: isCancelled,
      );
      NetworkInspectorConfig.instance.repository.update(completed);
      _refreshNotification();
    }

    handler.next(err);
  }

  NetworkCall _buildPendingCall(String id, RequestOptions options) {
    final headers = _flattenHeaders(options.headers);
    final authorizationHeader = headers.entries
        .firstWhere(
          (entry) => entry.key.toLowerCase() == 'authorization',
          orElse: () => const MapEntry('', ''),
        )
        .value;
    final contentType = headers.entries
        .firstWhere(
          (entry) => entry.key.toLowerCase() == 'content-type',
          orElse: () => const MapEntry('', ''),
        )
        .value;

    final bodyKind = RequestBodyKind.classify(
      contentType: contentType.isEmpty ? options.contentType : contentType,
      data: options.data,
    );

    return NetworkCall(
      id: id,
      method: HttpMethod.parse(options.method),
      baseUrl: options.baseUrl,
      path: options.path,
      fullUrl: options.uri.toString(),
      startTime: DateTime.now(),
      pathParams: _extractPathParams(options),
      queryParams: options.queryParameters,
      requestHeaders: headers,
      requestCookies: _extractCookiesFromHeaders(headers),
      authorizationHeader: authorizationHeader.isEmpty ? null : authorizationHeader,
      requestBody: _describeRequestBody(options.data),
      requestBodyKind: bodyKind,
      requestSizeBytes: _estimateSize(options.data),
    );
  }

  /// Dio resolves `{placeholders}` in the path before building
  /// [RequestOptions], so there's no raw path-parameter map to recover by
  /// default. Callers that substitute path parameters manually (e.g.
  /// generated Retrofit clients) can still surface them here by stashing
  /// `options.extra['pathParams']`.
  Map<String, String> _extractPathParams(RequestOptions options) {
    final raw = options.extra['pathParams'];
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', '$value'));
    }
    return const {};
  }

  /// Converts a request/response `FormData` payload into a plain, display-
  /// and cURL-friendly map without consuming any file's byte stream (which
  /// would break the real upload, since [MultipartFile] streams are
  /// single-use).
  Object? _describeRequestBody(Object? data) {
    if (data is! FormData) return data;

    final map = <String, Object?>{};
    for (final field in data.fields) {
      map[field.key] = field.value;
    }
    for (final file in data.files) {
      map[file.key] = {
        'filename': file.value.filename,
        'contentType': file.value.contentType?.mimeType,
        'lengthBytes': file.value.length,
      };
    }
    return map;
  }

  Map<String, String> _flattenHeaders(Map<String, dynamic> headers) {
    final result = <String, String>{};
    headers.forEach((key, value) {
      if (value is List) {
        result[key] = value.join('; ');
      } else {
        result[key] = '$value';
      }
    });
    return result;
  }

  Map<String, String> _extractCookiesFromHeaders(Map<String, String> headers) {
    final cookieHeaderEntry = headers.entries.firstWhere(
      (entry) =>
          entry.key.toLowerCase() == 'cookie' ||
          entry.key.toLowerCase() == 'set-cookie',
      orElse: () => const MapEntry('', ''),
    );
    if (cookieHeaderEntry.value.isEmpty) return const {};

    final cookies = <String, String>{};
    for (final part in cookieHeaderEntry.value.split(RegExp(r';\s*|,\s*(?=[^;]+=)'))) {
      final separatorIndex = part.indexOf('=');
      if (separatorIndex <= 0) continue;
      final name = part.substring(0, separatorIndex).trim();
      final value = part.substring(separatorIndex + 1).trim();
      if (name.isNotEmpty) cookies[name] = value;
    }
    return cookies;
  }

  int _estimateSize(Object? data) {
    if (data == null) return 0;
    if (data is FormData) return data.length;
    if (data is List<int>) return data.length;
    if (data is String) return utf8.encode(data).length;
    try {
      return utf8.encode(jsonEncode(data)).length;
    } catch (_) {
      return utf8.encode(data.toString()).length;
    }
  }

  void _refreshNotification() {
    final config = NetworkInspectorConfig.instance;
    if (!config.enableNotification) return;
    final service = config.notificationService;
    if (service == null) return;
    // Fire-and-forget: showing/updating the notification is a side effect
    // that must never block or fail the actual network call.
    unawaited(service.show(config.repository.all.length));
  }
}
