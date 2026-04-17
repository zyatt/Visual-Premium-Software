import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _client = http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<dynamic> get(String url) async {
    try {
      final response = await _client
          .get(Uri.parse(url), headers: _headers)
          .timeout(AppConstants.requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: $e');
    }
  }

  Future<dynamic> post(String url, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .post(Uri.parse(url), headers: _headers, body: jsonEncode(body))
          .timeout(AppConstants.requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: $e');
    }
  }

  Future<dynamic> put(String url, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .put(Uri.parse(url), headers: _headers, body: jsonEncode(body))
          .timeout(AppConstants.requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: $e');
    }
  }

  Future<dynamic> patch(String url, [Map<String, dynamic>? body]) async {
    try {
      final response = await _client
          .patch(
            Uri.parse(url),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConstants.requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: $e');
    }
  }

  Future<void> delete(String url) async {
    try {
      final response = await _client
          .delete(Uri.parse(url), headers: _headers)
          .timeout(AppConstants.requestTimeout);
      if (response.statusCode != 204 && response.statusCode != 200) {
        _handleResponse(response);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    String message = 'Erro ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      message = body['message'] ?? body['error'] ?? message;
    } catch (_) {}
    throw ApiException(message, statusCode: response.statusCode);
  }
}