import 'package:dio/dio.dart';

import 'app_config.dart';
import 'session_store.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.code = -1, this.statusCode});

  final String message;
  final int code;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({SessionStore? sessionStore, Dio? dio})
      : _sessionStore = sessionStore ?? SessionStore(),
        _dio = dio ?? Dio() {
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipAuth'] == true) {
            handler.next(options);
            return;
          }
          final token = await _sessionStore.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final SessionStore _sessionStore;
  final Dio _dio;

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _dio.get<dynamic>(path);
    return _unwrap(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Options? options,
  }) async {
    final response = await _dio.post<dynamic>(
      path,
      data: data,
      options: options,
    );
    return _unwrap(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path,
    FormData formData, {
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) async {
    final response = await _dio.post<dynamic>(
      path,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );
    return _unwrap(response);
  }

  Map<String, dynamic> _unwrap(Response<dynamic> response) {
    final raw = response.data;
    if (raw == null) {
      throw ApiException('服务器无响应', statusCode: response.statusCode);
    }
    final body = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw as Map);
    final code = body['code'];
    final intCode = code is int
        ? code
        : (code is num ? code.toInt() : (code is String ? int.tryParse(code) : null));
    if (intCode != null && intCode != 0) {
      throw ApiException(
        body['message']?.toString() ?? '请求失败',
        code: intCode,
        statusCode: response.statusCode,
      );
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'value': data};
  }
}
