import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'app_config.dart';
import 'session_store.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.code = -1, this.statusCode});

  final String message;
  final int code;
  final int? statusCode;

  /// Token 对应用户已不存在、token 失效、设备未绑定等，应清会话并回到绑定页。
  bool get isSessionInvalid {
    if (statusCode == 401) return true;
    if (code == 40402) return true; // 设备未绑定
    if (code == 40310) return true; // 暗号已在其他设备登录
    if (code == 40301 || code == 40101) return true; // 角色不符 / 未认证
    if (statusCode == 403 && code == 403) return true; // DRF 默认权限失败
    final m = message;
    return m.contains('未找到该用户') ||
        m.contains('User not found') ||
        m.contains('token not valid') ||
        m.contains('Token is invalid') ||
        m.contains('Token is expired') ||
        m.contains('认证失败') ||
        m.contains('身份认证信息未提供') ||
        m.contains('不是孩子端');
  }

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

  /// Exposed for absolute-URL uploads (e.g. COS pre-signed PUT).
  Dio get dio => _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _unwrap(response);
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  /// Raw bytes (images / video) — do not unwrap `{code,data}` JSON.
  Future<Uint8List> getBytes(String path) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw ApiException('请求失败($status)', statusCode: status);
      }
      final data = response.data;
      if (data == null || data.isEmpty) {
        throw ApiException('空响应', statusCode: status);
      }
      return Uint8List.fromList(data);
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        options: options,
      );
      return _unwrap(response);
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  Future<Map<String, dynamic>> postMultipart(
    String path,
    FormData formData, {
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) async {
    try {
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
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  ApiException _fromDio(DioException e) {
    final response = e.response;
    if (response != null) {
      try {
        return _unwrap(response) as dynamic;
      } on ApiException catch (err) {
        return err;
      } catch (_) {}
      final raw = response.data;
      if (raw is Map) {
        final msg = raw['message'] ?? raw['detail'];
        if (msg != null && '$msg'.trim().isNotEmpty) {
          final c = raw['code'];
          final code = c is int
              ? c
              : (c is num ? c.toInt() : int.tryParse('$c') ?? response.statusCode ?? -1);
          return ApiException(msg.toString(), code: code, statusCode: response.statusCode);
        }
      }
      return ApiException(
        '请求失败(${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return ApiException(e.message ?? '网络请求失败');
  }

  Map<String, dynamic> _unwrap(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final raw = response.data;
    if (status >= 400) {
      String message = '请求失败($status)';
      int code = status;
      if (raw is Map) {
        final body = Map<String, dynamic>.from(raw);
        final msg = body['message'] ?? body['detail'];
        if (msg != null && '$msg'.trim().isNotEmpty) {
          message = msg.toString();
        }
        final c = body['code'];
        if (c is int) {
          code = c;
        } else if (c is num) {
          code = c.toInt();
        } else if (c is String) {
          code = int.tryParse(c) ?? status;
        }
      }
      throw ApiException(message, code: code, statusCode: status);
    }
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
