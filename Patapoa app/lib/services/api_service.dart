import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config/api_config.dart';

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
  
  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: headers);
  }
  
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }
  
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return http.put(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }
  
  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return http.patch(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }
  
  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return http.delete(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: headers);
  }
  
  Future<http.Response> multipartPost(String endpoint, Map<String, String> fields, {List<http.MultipartFile> files = const []}) async {
    final token = await storage.read(key: 'auth_token');
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);
    
    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.fields.addAll(fields);
    request.files.addAll(files);
    
    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }
  
  Future<http.StreamedResponse> multipartRequest(String method, String endpoint, Map<String, String> fields, {List<http.MultipartFile> files = const []}) async {
    final token = await storage.read(key: 'auth_token');
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final request = http.MultipartRequest(method, uri);
    
    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.fields.addAll(fields);
    request.files.addAll(files);
    
    return await request.send();
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
