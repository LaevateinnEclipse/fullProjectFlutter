import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

/// Токен доступа, который подставляется в заголовок `Authorization`.
typedef TokenProvider = String? Function();

/// Создаёт настроенный клиент Dio.
Dio buildDio(
    {TokenProvider? tokenProvider,
    Future<bool> Function()? refreshTokens,
    Future<void> Function()? onSessionExpired}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: Duration(seconds: connectTimeoutSeconds),
      receiveTimeout: Duration(seconds: receiveTimeoutSeconds),
      headers: {'Content-Type': 'application/json'},
      // Коды 4xx разбираем сами, а не как необработанное исключение Dio.
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API] → ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        if (kDebugMode) {
          debugPrint('[API] ← $status ${response.requestOptions.uri}');
        }
        if (status >= 400) {
          // `throw` из интерсептора Dio завернёт в DioException с типом
          // unknown и спрячет ValidationException. Отклоняем ответ сами.
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        final request = error.requestOptions;
        final isAuth = request.path.startsWith('/auth/');
        if (error.response?.statusCode == 401 &&
            !isAuth &&
            refreshTokens != null) {
          if (request.extra['authRetried'] == true) {
            await onSessionExpired?.call();
          } else {
            final current = tokenProvider?.call();
            final alreadyRefreshed = current != null &&
                request.headers['Authorization'] != 'Bearer $current';
            if (alreadyRefreshed || await refreshTokens()) {
              request.extra['authRetried'] = true;
              request.headers['Authorization'] =
                  'Bearer ${tokenProvider?.call()}';
              try {
                final response = await dio.fetch<dynamic>(request);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                return handler.next(retryError);
              }
            }
          }
        }
        if (kDebugMode) {
          debugPrint(
            '[API] ${error.requestOptions.method} ${error.requestOptions.uri} → ${error.response?.statusCode ?? 'нет ответа'}: ${error.type}',
          );
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
}

/// Повторяет операцию чтения при сетевом сбое.
///
/// Не больше [maxAttempts] попыток, пауза растёт. Создание и изменение
/// не повторяются: иначе на сервере появятся дубликаты.
Future<T> withRetry<T>(
  Future<T> Function() action, {
  int maxAttempts = maxReadRetries,
  Duration baseDelay = const Duration(milliseconds: retryBaseDelayMs),
}) async {
  var attempt = 0;
  while (true) {
    attempt++;
    try {
      return await action();
    } on NetworkException {
      if (attempt >= maxAttempts) rethrow;
      if (kDebugMode) {
        debugPrint('[API] повтор $attempt из $maxAttempts после сетевого сбоя');
      }
      await Future<void>.delayed(baseDelay * (1 << (attempt - 1)));
    }
  }
}
