// lib/services/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:inscripcion_app/models/estudiante_model.dart'; // 1. Importa el modelo
import '../models/materia.dart';
import '../models/grupo_materia.dart';
import 'package:flutter/material.dart'; // 👈 agrega esto

class ApiService {
  // URL base de tu backend
  final String baseUrl;

  // Para dispositivos móviles usa tu IP local: 'http://192.168.1.100:3000/api'
  // Para producción: 'https://tudominio.com/api'

  // Constructor
  //ApiService({this.baseUrl = 'http://10.0.2.2:8000/api'});
  //ApiService({this.baseUrl = 'http://3.129.13.240:8000/api'});
  //ApiService({this.baseUrl = 'http://172.20.10.6:5000/api'});
  ApiService({this.baseUrl = 'http://192.168.0.184:5000/api'});

  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Método para el login
  Future<Map<String, dynamic>> login(String registro, String password) async {
    try {
      // El endpoint para JWT en Django Rest Framework es diferente
      final response = await post('/estudiantes/login', {
        'registro': registro,
        'password': password,
      });
      return response as Map<String, dynamic>;
    } catch (e) {
      // Re-lanzamos el error para que la UI lo maneje.
      rethrow;
    }
  }

  static Future<List<Materia>> fetchMaterias({int page = 1}) async {
    final url = Uri.parse("http://192.168.0.184:5000/api/materias?page=$page");
    // final url = Uri.parse("http://172.20.10.6:5000/api/materias?page=$page");
    // ⚠️ Usa 10.0.2.2 si estás en emulador Android, o la IP local de tu PC si usas dispositivo físico

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List items = data['items'];
      return items.map((e) => Materia.fromJson(e)).toList();
    } else {
      throw Exception("Error al cargar materias: ${response.statusCode}");
    }
  }

  Future<List<GrupoMateria>> fetchGruposPorMateria(String codigoMateria) async {
    final url = Uri.parse('$baseUrl/materias/$codigoMateria/grupos');
    final response = await http.get(url, headers: _defaultHeaders);

    // 👀 Log del JSON crudo
    debugPrint("🔥 JSON recibido: ${response.body}", wrapWidth: 1024);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List gruposJson = data['grupos'];
      return gruposJson.map((e) => GrupoMateria.fromJson(e)).toList();
    } else {
      throw Exception("Error al cargar grupos: ${response.statusCode}");
    }
  }

  // GET Request
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: _defaultHeaders)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      // Lanza una nueva excepción procesada solo para errores de red/timeout.
      throw _handleNetworkError(e);
    }
  }

  // POST Request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _defaultHeaders,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      // Lanza una nueva excepción procesada solo para errores de red/timeout.
      throw _handleNetworkError(e);
    }
  }

  // PUT Request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: _defaultHeaders,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      // Lanza una nueva excepción procesada solo para errores de red/timeout.
      throw _handleNetworkError(e);
    }
  }

  // PATCH Request
  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl$endpoint'),
            headers: _defaultHeaders,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      // Lanza una nueva excepción procesada solo para errores de red/timeout.
      throw _handleNetworkError(e);
    }
  }

  // DELETE Request
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl$endpoint'), headers: _defaultHeaders)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      // Lanza una nueva excepción procesada solo para errores de red/timeout.
      throw _handleNetworkError(e);
    }
  }

  // Manejar respuesta HTTP
  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 202:
        if (response.body.isEmpty) {
          return {'success': true};
        }
        return jsonDecode(response.body);
      case 400:
        throw ApiException('Petición incorrecta: ${response.body}');
      case 401:
        throw ApiException('No autorizado: Token inválido o expirado');
      case 403:
        throw ApiException('Prohibido: No tienes permisos');
      case 404:
        throw ApiException('No encontrado: El recurso no existe');
      case 500:
        throw ApiException('Error interno del servidor');
      default:
        throw ApiException(
          'Error HTTP ${response.statusCode}: ${response.body}',
        );
    }
  }

  // Manejar errores
  Never _handleNetworkError(dynamic error) {
    if (error is SocketException) {
      throw ApiException(
        'Sin conexión a internet. Por favor, revisa tu conexión.',
      );
    } else if (error is TimeoutException) {
      throw ApiException('El servidor tardó demasiado en responder.');
    } else {
      // Para cualquier otro tipo de error no esperado.
      throw ApiException('Ocurrió un error inesperado: ${error.toString()}');
    }
  }
}

// Clase de excepción personalizada para la API
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
