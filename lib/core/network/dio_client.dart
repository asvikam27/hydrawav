import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import 'auth_interceptor.dart';

final loggerProvider = Provider<Logger>((ref) => Logger(
      printer: PrettyPrinter(methodCount: 0, printTime: true),
    ));

/// ================= DJANGO DIO =================
/// Used for auth, sensors, orgs
final djangoDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiEndpoints.djangoBaseUrl,
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  /// 🔥 AUTH INTERCEPTOR (VERY IMPORTANT)
  dio.interceptors.add(ref.read(authInterceptorProvider));

  /// 🔥 DEBUG LOGGER
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    requestHeader: true,
    responseHeader: false,
    error: true,
    logPrint: (obj) => ref.read(loggerProvider).d(obj),
  ));

  /// 🔥 FALLBACK TOKEN (TEMP FIX - REMOVE LATER)
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 👇 If auth interceptor fails, fallback here
        if (!options.headers.containsKey('Authorization')) {
          const token = "PASTE_YOUR_TOKEN_HERE"; // 🔥 TEMP ONLY
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
    ),
  );

  return dio;
});

/// ================= NODE DIO =================
final nodeDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiEndpoints.nodeBaseUrl,
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(ref.read(authInterceptorProvider));

  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    requestHeader: true,
    error: true,
    logPrint: (obj) => ref.read(loggerProvider).d(obj),
  ));

  return dio;
});

/// ================= DEVICE CONTROL =================
final deviceDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiEndpoints.deviceControlUrl,
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(ref.read(authInterceptorProvider));

  return dio;
});