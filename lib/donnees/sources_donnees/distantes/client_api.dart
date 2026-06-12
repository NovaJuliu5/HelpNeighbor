import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:help_neighbor/app/dependances.dart';

class ClientApi {
  late Dio _dio;

  ClientApi() {
    // Détection automatique de l'URL de base selon la plateforme
    final String baseUrl;
    if (kIsWeb) {
      baseUrl = 'http://localhost:3000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Sur émulateur Android, 10.0.2.2 correspond à l'hôte local
      baseUrl = 'http://10.0.2.2:3000/api';
    } else {
      // iOS, macOS, Windows, Linux
      baseUrl = 'http://localhost:3000/api';
    }

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Ajout du LogInterceptor pour voir toutes les requêtes et réponses
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getIt<FlutterSecureStorage>().read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Gérer rafraîchissement token (optionnel)
        }
        return handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? query}) async {
    return await _dio.get(path, queryParameters: query);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}