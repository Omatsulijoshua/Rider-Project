import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rider_driver/services/shared_pref.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:3000/api';
  static const Duration timeout = Duration(seconds: 30);

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal();

  /// Get authorization header with JWT token
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (requireAuth) {
      final token = await SharedpreferenceHelper().getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// POST request with JSON body
  Future<dynamic> post(
    String endpoint, {
    required dynamic body,
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('POST request failed: $e');
    }
  }

  /// GET request
  Future<dynamic> get(String endpoint, {bool requireAuth = true}) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response = await http.get(url, headers: headers).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET request failed: $e');
    }
  }

  /// PATCH request
  Future<dynamic> patch(
    String endpoint, {
    required dynamic body,
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response = await http
          .patch(url, headers: headers, body: jsonEncode(body))
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('PATCH request failed: $e');
    }
  }

  /// DELETE request
  Future<dynamic> delete(String endpoint, {bool requireAuth = true}) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response = await http
          .delete(url, headers: headers)
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('DELETE request failed: $e');
    }
  }

  /// Multipart file upload
  Future<dynamic> upload(
    String endpoint, {
    required String filePath,
    String fieldName = 'file',
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', url);

      final headers = await _getHeaders(requireAuth: requireAuth);
      headers.remove('Content-Type'); // Let http handle it for multipart
      request.headers.addAll(headers);

      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  /// Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      try {
        final error = jsonDecode(response.body);
        throw Exception(
          error['message'] ?? 'Unauthorized - Invalid credentials/token',
        );
      } catch (e) {
        // If the throw was caught, re-throw it. Otherwise fallback to generic text.
        if (e is Exception && e.toString().contains('Unauthorized') ||
            e.toString().contains('Invalid'))
          rethrow;
        throw Exception('Unauthorized - Invalid credentials/token');
      }
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden - Access denied');
    } else if (response.statusCode == 404) {
      throw Exception('Not found');
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Request failed');
      } catch (e) {
        throw Exception('Request failed with status ${response.statusCode}');
      }
    }
  }
}
