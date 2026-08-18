import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../config/api_config.dart';
import '../utils/api_error_handler.dart';

class ApiService {
  final storage = const FlutterSecureStorage();
  
  Future<Map<String, String>> _getHeaders() async {
    final token = await storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  Future<http.Response> get(String endpoint, {List<String>? fields, List<String>? include, bool useCache = true}) async {
    final url = _buildUrl(endpoint, fields, include);
    debugPrint('API GET Request: $url');

    return ApiErrorHandler.handle(() async {
      try {
        final headers = await _getHeaders();
        debugPrint('API Headers: $headers');

        final response = await http.get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 15));

        debugPrint('API Response Status: ${response.statusCode}');
        final processed = _processResponse(response);

        // Cache successful response for offline use
        if (useCache && processed.statusCode == 200) {
          _cacheResponse(url, processed.body);
        }

        return processed;
      } catch (e) {
        // If offline and cache exists, return cached data instead of throwing
        if (useCache && (e is NetworkException || e is RequestTimeoutException)) {
          final cachedBody = await _getCachedResponse(url);
          if (cachedBody != null) {
            return http.Response(cachedBody, 200, headers: {'x-from-cache': 'true'});
          }
        }
        rethrow;
      }
    });
  }

  String _buildUrl(String endpoint, List<String>? fields, List<String>? include) {
    String url = '${ApiConfig.baseUrl}$endpoint';
    final params = <String>[];
    if (fields != null && fields.isNotEmpty) {
      params.add('fields=${fields.join(',')}');
    }
    if (include != null && include.isNotEmpty) {
      for (var relation in include) {
        params.add('with=$relation');
      }
    }
    if (params.isNotEmpty) {
      url += (url.contains('?') ? '&' : '?') + params.join('&');
    }
    return url;
  }

  Future<void> _cacheResponse(String key, String body) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_$key', body);
    await prefs.setString('cache_time_$key', DateTime.now().toIso8601String());
  }

  Future<String?> _getCachedResponse(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cache_$key');
  }
  
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    debugPrint('API POST Request: $url');
    debugPrint('API Body: ${jsonEncode(body)}');

    return ApiErrorHandler.handle(() async {
      final headers = await _getHeaders();
      debugPrint('API Headers: $headers');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      debugPrint('API Response Status: ${response.statusCode}');
      return _processResponse(response);
    });
  }
  
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    return ApiErrorHandler.handle(() async {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    });
  }
  
  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    return ApiErrorHandler.handle(() async {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    });
  }
  
  Future<http.Response> delete(String endpoint) async {
    return ApiErrorHandler.handle(() async {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers
      ).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    });
  }

  Future<http.Response> multipartPost(String endpoint, Map<String, String> fields, {List<http.MultipartFile> files = const []}) async {
    return ApiErrorHandler.handle(() async {
      final token = await storage.read(key: 'auth_token');
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll(fields);
      request.files.addAll(files);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    });
  }

  http.Response _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else if (response.statusCode == 422) {
      // Return 422 responses so caller can handle validation errors
      return response;
    } else if (response.statusCode == 401) {
      throw AuthException('Your session has expired. Please login again.');
    } else if (response.statusCode == 403) {
      String message = 'Access denied';
      try {
        final body = jsonDecode(response.body);
        message = body['message'] ?? message;
      } catch (_) {}
      throw AppException(message, 'forbidden');
    } else {
      String message = 'Server error';
      try {
        final body = jsonDecode(response.body);
        message = body['message'] ?? message;
      } catch (_) {}
      throw ServerException(message, response.statusCode);
    }
  }
  
  Future<void> setAuthToken(String token) async {
    await storage.write(key: 'auth_token', value: token);
  }
  
  Future<String?> getAuthToken() async {
    return await storage.read(key: 'auth_token');
  }
  
  Future<void> clearAuthToken() async {
    await storage.delete(key: 'auth_token');
  }
  
  Future<bool> isAuthenticated() async {
    final token = await storage.read(key: 'auth_token');
    return token != null;
  }
}
