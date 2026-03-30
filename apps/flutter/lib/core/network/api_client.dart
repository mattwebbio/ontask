import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

part 'api_client.g.dart';

/// Thin wrapper around [Dio] that wires up auth and logging interceptors.
///
/// ARCH RULE: [ApiClient] is ALWAYS injected via Riverpod — never instantiated
/// as a singleton. This keeps it testable via [ProviderContainer] overrides.
class ApiClient {
  ApiClient({required String baseUrl}) : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.addAll([
      AuthInterceptor(dio: _dio),
      LoggingInterceptor(),
    ]);
  }

  final Dio _dio;

  /// Exposes the underlying [Dio] instance for use by repositories.
  Dio get dio => _dio;
}

/// Riverpod provider for [ApiClient].
///
/// Every repository must receive this via `ref.watch(apiClientProvider)`.
/// Do NOT call `ApiClient(...)` directly — that breaks test overrides.
@riverpod
ApiClient apiClient(Ref ref) {
  return ApiClient(baseUrl: AppConfig.apiUrl);
}
