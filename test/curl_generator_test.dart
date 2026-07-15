import 'package:flutter_test/flutter_test.dart';
import 'package:network_inspector/src/data/models/http_method.dart';
import 'package:network_inspector/src/data/models/network_call.dart';
import 'package:network_inspector/src/data/models/request_body_kind.dart';
import 'package:network_inspector/src/utils/curl_generator.dart';

NetworkCall _call({
  required RequestBodyKind kind,
  Object? body,
  Map<String, String> headers = const {},
  Map<String, String> cookies = const {},
  String? auth,
  HttpMethod method = HttpMethod.post,
}) {
  return NetworkCall(
    id: '1',
    method: method,
    baseUrl: 'https://api.example.com',
    path: '/users',
    fullUrl: 'https://api.example.com/users?active=true',
    startTime: DateTime(2026, 1, 1),
    requestHeaders: headers,
    requestCookies: cookies,
    authorizationHeader: auth,
    requestBody: body,
    requestBodyKind: kind,
  );
}

void main() {
  test('GET request with no body has no --data flag', () {
    final curl = CurlGenerator.generate(_call(kind: RequestBodyKind.none, method: HttpMethod.get));

    expect(curl, contains('curl -X GET'));
    expect(curl, contains("'https://api.example.com/users?active=true'"));
    expect(curl, isNot(contains('--data')));
  });

  test('JSON body is serialized with --data-raw', () {
    final curl = CurlGenerator.generate(
      _call(kind: RequestBodyKind.json, body: {'name': 'Ada'}),
    );

    expect(curl, contains('-X POST'));
    expect(curl, contains('--data-raw'));
    expect(curl, contains('{"name":"Ada"}'));
  });

  test('form-urlencoded body produces one --data-urlencode per field', () {
    final curl = CurlGenerator.generate(
      _call(kind: RequestBodyKind.formUrlEncoded, body: {'a': '1', 'b': '2'}),
    );

    expect(curl, contains("--data-urlencode 'a=1'"));
    expect(curl, contains("--data-urlencode 'b=2'"));
  });

  test('multipart body produces -F for fields and files', () {
    final curl = CurlGenerator.generate(
      _call(
        kind: RequestBodyKind.multipart,
        body: {
          'field': 'value',
          'file': {'filename': 'a.png', 'contentType': 'image/png'},
        },
      ),
    );

    expect(curl, contains("-F 'field=value'"));
    expect(curl, contains("-F 'file=@a.png;type=image/png'"));
  });

  test('binary body is noted but not inlined', () {
    final curl = CurlGenerator.generate(
      _call(kind: RequestBodyKind.binary, body: List<int>.filled(10, 1)),
    );

    expect(curl, contains('--data-binary omitted'));
    expect(curl, contains('10 bytes'));
  });

  test('headers, authorization, cookies and query params are all included', () {
    final curl = CurlGenerator.generate(
      _call(
        kind: RequestBodyKind.none,
        method: HttpMethod.delete,
        headers: {'X-Custom': 'yes'},
        cookies: {'session': 'abc123'},
        auth: 'Bearer token123',
      ),
    );

    expect(curl, contains('curl -X DELETE'));
    expect(curl, contains("-H 'X-Custom: yes'"));
    expect(curl, contains("-H 'Authorization: Bearer token123'"));
    expect(curl, contains("-H 'Cookie: session=abc123'"));
    expect(curl, contains('active=true'));
  });

  test('single quotes in values are shell-escaped', () {
    final curl = CurlGenerator.generate(
      _call(kind: RequestBodyKind.text, body: "it's a test"),
    );

    expect(curl, contains(r"it'\''s a test"));
  });
}
