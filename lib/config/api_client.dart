import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoring/config/api.dart';

/// Single authenticated HTTP client for all API calls.
/// Place at: lib/config/api_client.dart
class ApiClient {
  static Future<Map<String, String>> _headers({bool json = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('sanctum_token') ?? '';
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// GET with optional query params.
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/$endpoint')
        .replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers());
    _checkUnauthorized(response);
    return response;
  }

  /// POST with form-encoded body.
  static Future<http.Response> post(
    String endpoint, {
    Map<String, String>? body,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/$endpoint'),
      headers: await _headers(),
      body: body,
    );
    _checkUnauthorized(response);
    return response;
  }

  /// POST with JSON body + optional query params (used by point_services).
  static Future<http.Response> postJson(
    String endpoint, {
    Map<String, String>? params,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/$endpoint')
        .replace(queryParameters: params);
    final response = await http.post(
      uri,
      headers: await _headers(json: true),
      body: jsonEncode(body ?? {}),
    );
    _checkUnauthorized(response);
    return response;
  }

  static void _checkUnauthorized(http.Response response) {
    if (response.statusCode == 401) throw UnauthorizedException();
  }
}

class UnauthorizedException implements Exception {
  @override
  String toString() => 'Sesi berakhir, silakan login ulang.';
}