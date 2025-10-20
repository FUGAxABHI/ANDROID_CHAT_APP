import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/config.dart';
import 'package:logging/logging.dart';
import 'dart:typed_data';

final log = Logger('ApiService');

class ApiService with ChangeNotifier {
  final Future<String?> Function() _getTokenCallback;
  bool _isLoading = false;

  ApiService(this._getTokenCallback);

  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    Future.microtask(() => notifyListeners());
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getTokenCallback();
    log.info('Using token: $token'); // Added log statement
    return {
      'Content-Type': 'application/json',
      if (token != null) 'x-auth-token': token,
    };
  }

  Future<dynamic> get(String endpoint) async {
    _setLoading(true);
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}$endpoint'), headers: headers);
      return _handleResponse(response);
    } catch (e) {
      log.severe('Error in GET request to $endpoint: $e');
      throw Exception('Failed to connect to the server. Please check your internet connection.');
    } finally {
      _setLoading(false);
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      log.severe('Error in POST request to $endpoint: $e');
      throw Exception('Failed to connect to the server. Please check your internet connection.');
    } finally {
      _setLoading(false);
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      log.severe('Error in PUT request to $endpoint: $e');
      throw Exception('Failed to connect to the server. Please check your internet connection.');
    } finally {
      _setLoading(false);
    }
  }

  Future<dynamic> uploadFile(String endpoint, Uint8List fileBytes, String filename) async {
    _setLoading(true);
    try {
      final headers = await _getHeaders();
      final request = http.MultipartRequest('POST', Uri.parse('${AppConfig.baseUrl}$endpoint'));
      request.headers.addAll(headers);
      request.files.add(http.MultipartFile.fromBytes(
        'profilePicture', // Field name for the file
        fileBytes,
        filename: filename,
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody);
      } else {
        log.severe('API Error: ${response.statusCode} $responseBody');
        throw Exception('Failed to upload file: $responseBody');
      }
    } catch (e) {
      log.severe('Error in file upload to $endpoint: $e');
      throw Exception('Failed to connect to the server. Please check your internet connection.');
    } finally {
      _setLoading(false);
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null; // No content
    } else {
      log.severe('API Error: ${response.statusCode} ${response.body}');
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'An unknown error occurred.');
    }
  }
}
