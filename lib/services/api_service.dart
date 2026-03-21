import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_routes.dart';

class ApiService {
  // ── Helpers internos ──────────────────────────────────────────────────────

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _parse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {'statusCode': response.statusCode, ...data};
    } catch (_) {
      return {
        'statusCode': response.statusCode,
        'success': false,
        'message': 'Error al procesar la respuesta del servidor.',
      };
    }
  }

  static Map<String, dynamic> _connectionError(Object e) => {
    'statusCode': 0,
    'success': false,
    'message': 'Error de conexión. Verifica tu red.',
  };

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('usuario', jsonEncode(data['usuario']));
        await prefs.setString('roles', jsonEncode(data['roles']));
        await prefs.setString('modulos', jsonEncode(data['modulos']));
      }

      return {'statusCode': response.statusCode, ...data};
    } catch (e) {
      return {
        'statusCode': 0,
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      try {
        await http
            .post(
              Uri.parse('$kBaseUrl/auth/logout'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Si falla la petición igual limpiamos localmente
      }
    }

    // Borra sesión pero preserva dark_mode para que persista entre sesiones
    await prefs.remove('token');
    await prefs.remove('usuario');
    await prefs.remove('roles');
    await prefs.remove('modulos');
  }

  // ── GET ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$kBaseUrl$endpoint'), headers: await _headers())
          .timeout(const Duration(seconds: 15));
      return _parse(response);
    } catch (e) {
      return _connectionError(e);
    }
  }

  // ── POST ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl$endpoint'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _parse(response);
    } catch (e) {
      return _connectionError(e);
    }
  }

  // ── PUT ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$kBaseUrl$endpoint'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _parse(response);
    } catch (e) {
      return _connectionError(e);
    }
  }

  // ── PATCH ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$kBaseUrl$endpoint'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _parse(response);
    } catch (e) {
      return _connectionError(e);
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http
          .delete(Uri.parse('$kBaseUrl$endpoint'), headers: await _headers())
          .timeout(const Duration(seconds: 15));
      return _parse(response);
    } catch (e) {
      return _connectionError(e);
    }
  }
}
