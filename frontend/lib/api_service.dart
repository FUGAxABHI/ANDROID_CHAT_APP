import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/config.dart';
import 'package:logging/logging.dart';

final log = Logger('ApiService');

class ApiService {
  final Future<String?> Function() _getTokenCallback;

  ApiService(this._getTokenCallback);

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getTokenCallback();
    log.info('Using token: $token'); // Added log statement
    return {
      'Content-Type': 'application/json',
      if (token != null) 'x-auth-token': token,
    };
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('${AppConfig.baseUrl}$endpoint'), headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> uploadFile(String endpoint, String filePath) async {
    final headers = await _getHeaders();
    final request = http.MultipartRequest('POST', Uri.parse('${AppConfig.baseUrl}$endpoint'));
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(responseBody);
    } else {
      log.severe('API Error: ${response.statusCode} $responseBody');
      throw Exception('Failed to upload file: $responseBody');
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
      throw Exception('Failed to load data from API: ${response.body}');
    }
  }
}
