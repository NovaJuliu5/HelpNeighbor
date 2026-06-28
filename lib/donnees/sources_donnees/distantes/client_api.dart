import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/donnees/sources_donnees/locales/aide_preferences.dart';

class ClientApi {
  late Dio _dio;

  // Routes qui ne nécessitent pas d'authentification
  static const List<String> _routesPubliques = [
    '/auth/connexion',
    '/auth/inscription',
    '/auth/mot-de-passe-oublie',
    '/auth/verification-otp',
    '/auth/renouveler-mot-de-passe',
    '/auth/reinitialiser-mot-de-passe',
  ];

  ClientApi() {
    final String baseUrl;
    if (kIsWeb) {
      baseUrl = 'http://localhost:3000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      baseUrl = 'http://192.168.43.99:3000/api';
    } else {
      baseUrl = 'http://localhost:3000/api';
    }

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final storage = getIt<FlutterSecureStorage>();
        String? token = await storage.read(key: 'token');

        // Si le token est absent, tenter de le récupérer depuis SharedPreferences
        if (token == null) {
          print(' Token absent dans SecureStorage pour ${options.path}');
          final prefs = await SharedPreferences.getInstance();
          token = prefs.getString('auth_token');
          if (token != null) {
            print('Token récupéré depuis SharedPreferences, réécriture dans SecureStorage');
            await storage.write(key: 'token', value: token);
          } else {
            print('Aucun token trouvé ni dans SecureStorage ni dans SharedPreferences');
          }
        }

        // Vérifier si la route nécessite une authentification
        final bool requiertAuth = _requiertAuth(options.path);

        if (token == null && requiertAuth) {
          // Token manquant pour une route protégée → rejeter la requête
          print('Requête non authentifiée pour ${options.path} – token manquant');
          return handler.reject(DioException(
            requestOptions: options,
            error: 'Non authentifié',
            type: DioExceptionType.badResponse,
          ));
        }

        if (token != null) {
          final preview = token.length > 20 ? '${token.substring(0, 20)}...' : token;
          print('Token utilisé pour ${options.path} : $preview');
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          print('Aucun token pour ${options.path} (route publique)');
        }

        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // En cas de 401, on efface le token pour éviter des requêtes ultérieures avec un token invalide
          print('401 sur ${error.requestOptions.path} – suppression du token');
          await AidePreferences.effacerToken();
          // On pourrait aussi déclencher une redirection globale, mais on laisse le caller gérer l'erreur
        }
        return handler.next(error);
      },
    ));
  }

  /// Vérifie si une route nécessite un token d'authentification.
  bool _requiertAuth(String path) {
    // Si le chemin commence par /auth/ mais n'est pas dans la liste publique, on considère qu'il est protégé
    // (par exemple /auth/refresh-token pourrait être protégé, mais on met tout par sécurité)
    // Pour simplifier, on considère que toute route qui n'est pas dans _routesPubliques est protégée.
    for (final publique in _routesPubliques) {
      if (path.startsWith(publique)) {
        return false;
      }
    }
    return true;
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