import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rider/service/shared_pref.dart';

class ApiClient {
  // ✅ USE YOUR CURRENT PC IP (CHANGE when network changes)
  static const String baseUrl = 'http://localhost:3000/api';

  static const Duration timeout = Duration(seconds: 30);

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  ApiClient._internal();

  /// 🔐 Get headers (with optional JWT)
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (requireAuth) {
      final token = await SharedpreferenceHelper().getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// 🚀 POST request
  Future<dynamic> post(
    String endpoint, {
    required dynamic body,
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('POST request failed: $e');
    }
  }

  /// 📥 GET request
  Future<dynamic> get(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response = await http.get(url, headers: headers).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET request failed: $e');
    }
  }

  /// ✏️ PATCH request
  Future<dynamic> patch(
    String endpoint, {
    required dynamic body,
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response = await http
          .patch(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('PATCH request failed: $e');
    }
  }

  /// 🗑 DELETE request
  Future<dynamic> delete(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response =
          await http.delete(url, headers: headers).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('DELETE request failed: $e');
    }
  }

  /// 🧠 Handle all responses
  dynamic _handleResponse(http.Response response) {
    print("========== API DEBUG ==========");
    print("URL STATUS: ${response.statusCode}");
    print("RESPONSE BODY: ${response.body}");
    print("================================");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isEmpty ? {} : jsonDecode(response.body);
    }

    // 🔴 Common errors
    if (response.statusCode == 400) {
      throw Exception('Bad request');
    } else if (response.statusCode == 401) {
      try {
        final error = jsonDecode(response.body);
        throw Exception(
            error['message'] ?? 'Unauthorized - Invalid credentials/token');
      } catch (e) {
        if (e is Exception &&
            (e.toString().contains('Unauthorized') ||
                e.toString().contains('Invalid'))) {
          rethrow;
        }
        throw Exception('Unauthorized - Invalid credentials/token');
      }
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden - Access denied');
    } else if (response.statusCode == 404) {
      throw Exception('Not found (Check endpoint URL)');
    } else if (response.statusCode >= 500) {
      throw Exception('Server error (${response.statusCode})');
    }

    // 🔴 Fallback error
    try {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Request failed');
    } catch (_) {
      throw Exception('Unexpected error (${response.statusCode})');
    }
  }
}
