import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_inspector/network_inspector.dart';
import 'package:network_inspector/src/core/network_inspector_config.dart';

class _MockRequestHandler extends Mock implements RequestInterceptorHandler {}

class _MockResponseHandler extends Mock implements ResponseInterceptorHandler {}

class _MockErrorHandler extends Mock implements ErrorInterceptorHandler {}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
    registerFallbackValue(Response<dynamic>(requestOptions: RequestOptions(path: '/')));
    registerFallbackValue(DioException(requestOptions: RequestOptions(path: '/')));
  });

  setUp(() {
    NetworkInspectorConfig.resetForTesting();
    NetworkInspectorConfig.init(
      navigatorKey: GlobalKey<NavigatorState>(),
      maxLogs: 500,
      enableNotification: false,
    );
  });

  test('onRequest captures a pending call, onResponse completes it', () {
    final interceptor = NetworkInspectorInterceptor();
    final requestHandler = _MockRequestHandler();
    when(() => requestHandler.next(any())).thenReturn(null);

    final options = RequestOptions(
      path: '/users',
      method: 'POST',
      baseUrl: 'https://api.example.com',
      headers: {'Authorization': 'Bearer abc', 'content-type': 'application/json'},
      data: {'name': 'Ada'},
    );

    interceptor.onRequest(options, requestHandler);
    verify(() => requestHandler.next(options)).called(1);

    final repository = NetworkInspectorConfig.instance.repository;
    expect(repository.all.length, 1);

    final pending = repository.all.single;
    expect(pending.method.label, 'POST');
    expect(pending.authorizationHeader, 'Bearer abc');
    expect(pending.isComplete, isFalse);
    expect(pending.requestBody, {'name': 'Ada'});

    final response = Response<dynamic>(
      requestOptions: options,
      statusCode: 201,
      data: {'id': 1},
      headers: Headers.fromMap({
        'content-type': ['application/json'],
      }),
    );
    final responseHandler = _MockResponseHandler();
    when(() => responseHandler.next(any())).thenReturn(null);

    interceptor.onResponse(response, responseHandler);
    verify(() => responseHandler.next(response)).called(1);

    final completed = repository.all.single;
    expect(completed.isComplete, isTrue);
    expect(completed.statusCode, 201);
    expect(completed.responseBody, {'id': 1});
    expect(completed.status.isSuccess, isTrue);
  });

  test('onError captures a failed call with timeout details', () {
    final interceptor = NetworkInspectorInterceptor();
    final requestHandler = _MockRequestHandler();
    when(() => requestHandler.next(any())).thenReturn(null);

    final options = RequestOptions(
      path: '/users',
      method: 'GET',
      baseUrl: 'https://api.example.com',
    );
    interceptor.onRequest(options, requestHandler);

    final error = DioException(
      requestOptions: options,
      type: DioExceptionType.connectionTimeout,
      message: 'Connection timed out',
    );
    final errorHandler = _MockErrorHandler();
    when(() => errorHandler.next(any())).thenReturn(null);

    interceptor.onError(error, errorHandler);
    verify(() => errorHandler.next(error)).called(1);

    final completed = NetworkInspectorConfig.instance.repository.all.single;
    expect(completed.isComplete, isTrue);
    expect(completed.isTimeout, isTrue);
    expect(completed.error, 'Connection timed out');
    expect(completed.status.isError, isTrue);
  });

  test('onError captures a cancelled request', () {
    final interceptor = NetworkInspectorInterceptor();
    final requestHandler = _MockRequestHandler();
    when(() => requestHandler.next(any())).thenReturn(null);

    final options = RequestOptions(
      path: '/users',
      method: 'GET',
      baseUrl: 'https://api.example.com',
    );
    interceptor.onRequest(options, requestHandler);

    final error = DioException(
      requestOptions: options,
      type: DioExceptionType.cancel,
    );
    final errorHandler = _MockErrorHandler();
    when(() => errorHandler.next(any())).thenReturn(null);

    interceptor.onError(error, errorHandler);

    final completed = NetworkInspectorConfig.instance.repository.all.single;
    expect(completed.isCancelled, isTrue);
    expect(completed.status.name, 'cancelled');
  });
}
