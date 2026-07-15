import 'dart:convert';

import '../data/models/network_call.dart';
import '../data/models/request_body_kind.dart';

/// Builds a complete, copy-pasteable `curl` command from a captured
/// [NetworkCall] — method, headers, cookies, authorization, query params
/// (already part of [NetworkCall.fullUrl]) and body, for every
/// [RequestBodyKind].
class CurlGenerator {
  const CurlGenerator._();

  static String generate(NetworkCall call) {
    final parts = <String>['curl -X ${call.method.label}', "'${call.fullUrl}'"];

    final headers = Map<String, String>.from(call.requestHeaders);

    final hasAuthHeader = headers.keys.any(
      (key) => key.toLowerCase() == 'authorization',
    );
    if (!hasAuthHeader && call.authorizationHeader != null) {
      headers['Authorization'] = call.authorizationHeader!;
    }

    final hasCookieHeader = headers.keys.any(
      (key) => key.toLowerCase() == 'cookie',
    );
    if (!hasCookieHeader && call.requestCookies.isNotEmpty) {
      headers['Cookie'] = call.requestCookies.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');
    }

    for (final entry in headers.entries) {
      parts.add("-H '${entry.key}: ${_escapeSingleQuotes(entry.value)}'");
    }

    parts.addAll(_bodyArguments(call));

    return parts.join(' \\\n  ');
  }

  static List<String> _bodyArguments(NetworkCall call) {
    final body = call.requestBody;
    if (body == null) return const [];

    switch (call.requestBodyKind) {
      case RequestBodyKind.none:
        return const [];

      case RequestBodyKind.json:
        final encoded = body is String ? body : jsonEncode(body);
        return ["--data-raw '${_escapeSingleQuotes(encoded)}'"];

      case RequestBodyKind.text:
        return ["--data-raw '${_escapeSingleQuotes(body.toString())}'"];

      case RequestBodyKind.formUrlEncoded:
        if (body is Map) {
          return body.entries
              .map(
                (entry) =>
                    "--data-urlencode '${entry.key}=${_escapeSingleQuotes('${entry.value}')}'",
              )
              .toList();
        }
        return ["--data-raw '${_escapeSingleQuotes(body.toString())}'"];

      case RequestBodyKind.multipart:
        if (body is Map) {
          return body.entries.map((entry) {
            final value = entry.value;
            if (value is Map && value.containsKey('filename')) {
              final filename = value['filename'];
              final contentType = value['contentType'] ?? 'application/octet-stream';
              return "-F '${entry.key}=@$filename;type=$contentType'";
            }
            return "-F '${entry.key}=${_escapeSingleQuotes('$value')}'";
          }).toList();
        }
        return const [
          '# multipart body captured without field metadata, omitted',
        ];

      case RequestBodyKind.binary:
        final byteLength = body is List<int> ? body.length : null;
        final note = byteLength != null
            ? '$byteLength bytes'
            : 'binary payload';
        return ["# --data-binary omitted ($note not inlined)"];
    }
  }

  static String _escapeSingleQuotes(String value) =>
      value.replaceAll("'", r"'\''");
}
