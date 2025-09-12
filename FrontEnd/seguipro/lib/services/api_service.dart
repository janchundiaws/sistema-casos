import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/area.dart';
import '../models/rol.dart';
import '../models/caso.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static const storage = FlutterSecureStorage();
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Token expirado o inválido
            storage.delete(key: 'token');
          }
          handler.next(error);
        },
      ),
    );
  }

  // Autenticación
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      final token = response.data['token'];
      final usuario = response.data['usuario'];
      await storage.write(key: 'token', value: token);
      await storage.write(key: 'usuario', value: usuario.toString());
      return {'token': token, 'usuario': usuario};
    } catch (e) {
      throw Exception('Error en login: $e');
    }
  }

  Future<int> register(
    String password,
    int idArea,
    int idRol,
    String username,
    String nombres,
    String apellidos,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'password': password,
          'id_area': idArea,
          'id_rol': idRol,
          'username': username,
          'nombres': nombres,
          'apellidos': apellidos,
        },
      );

      return response.data['id_usuario'];
    } catch (e) {
      throw Exception('Error en registro: $e');
    }
  }

  // Áreas
  Future<List<Area>> getAreas() async {
    try {
      final response = await _dio.get('/areas');
      return (response.data as List)
          .map((json) => Area.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo áreas: $e');
    }
  }

  // Roles
  Future<List<Rol>> getRoles() async {
    try {
      final response = await _dio.get('/roles');
      return (response.data as List).map((json) => Rol.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error obteniendo roles: $e');
    }
  }

  // Casos
  Future<List<Caso>> getCasos({String? estado, int? idArea}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (estado != null) queryParams['estado'] = estado;
      if (idArea != null) queryParams['id_area'] = idArea;

      final response = await _dio.get('/casos', queryParameters: queryParams);
      return (response.data as List)
          .map((json) => Caso.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo casos: $e');
    }
  }

  Future<Map<String, dynamic>> getCasoDetalle(int idCaso) async {
    try {
      final response = await _dio.get('/casos/$idCaso');
      return response.data;
    } catch (e) {
      throw Exception('Error obteniendo detalle del caso: $e');
    }
  }

  Future<int> crearCaso({
    required String titulo,
    String? descripcion,
    required String tipo,
    String estado = 'Iniciado',
    List<int>? areas,
  }) async {
    try {
      final response = await _dio.post(
        '/casos',
        data: {
          'titulo': titulo,
          'descripcion': descripcion,
          'tipo': tipo,
          'estado': estado,
          'areas': areas,
        },
      );

      return response.data['id_caso'];
    } catch (e) {
      throw Exception('Error creando caso: $e');
    }
  }

  // Seguimientos
  Future<int> crearSeguimiento({
    required int idCaso,
    required String retroalimentacion,
    String estado = 'En proceso',
  }) async {
    try {
      final response = await _dio.post(
        '/seguimientos',
        data: {
          'id_caso': idCaso,
          'retroalimentacion': retroalimentacion,
          'estado': estado,
        },
      );

      return response.data['id_seguimiento'];
    } catch (e) {
      throw Exception('Error creando seguimiento: $e');
    }
  }

  // Adjuntos
  Future<int> subirAdjunto({
    required File file,
    int? idCaso,
    int? idSeguimiento,
  }) async {
    try {
      // Verificar que el archivo existe
      if (!await file.exists()) {
        throw Exception('El archivo no existe');
      }

      // Obtener el nombre del archivo
      final fileName = file.path.split(Platform.pathSeparator).last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        if (idCaso != null) 'id_caso': idCaso,
        if (idSeguimiento != null) 'id_seguimiento': idSeguimiento,
      });

      final response = await _dio.post('/adjuntos/upload', data: formData);

      if (response.statusCode == 200) {
        return response.data['id_adjunto'];
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 413) {
          throw Exception('El archivo es demasiado grande');
        } else if (e.response?.statusCode == 415) {
          throw Exception('Tipo de archivo no soportado');
        } else if (e.response?.statusCode == 400) {
          throw Exception('Datos de archivo inválidos');
        }
      }
      throw Exception('Error subiendo archivo: $e');
    }
  }

  // Adjuntos para web
  Future<int> subirAdjuntoWeb({
    required String fileName,
    required Uint8List bytes,
    int? idCaso,
    int? idSeguimiento,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
        if (idCaso != null) 'id_caso': idCaso,
        if (idSeguimiento != null) 'id_seguimiento': idSeguimiento,
      });

      final response = await _dio.post('/adjuntos/upload', data: formData);

      if (response.statusCode == 200) {
        return response.data['id_adjunto'];
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 413) {
          throw Exception('El archivo es demasiado grande');
        } else if (e.response?.statusCode == 415) {
          throw Exception('Tipo de archivo no soportado');
        } else if (e.response?.statusCode == 400) {
          throw Exception('Datos de archivo inválidos');
        }
      }
      throw Exception('Error subiendo archivo: $e');
    }
  }

  // Utilidades
  Future<void> logout() async {
    await storage.delete(key: 'token');
  }

  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'token');
    return token != null;
  }
}
