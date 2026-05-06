import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prediction_model.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'https://bug-detection-3zj1.onrender.com';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> verifyUser() async {
    final headers = await _authHeaders();
    final response = await http.post(Uri.parse('$baseUrl/auth/verify'), headers: headers);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getMe() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/auth/me'), headers: headers);
    return jsonDecode(response.body);
  }

  static Future<List<Prediction>> fetchPredictions({int limit = 50}) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/predictions?limit=$limit'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Prediction.fromJson(e)).toList();
    }
    throw Exception('Failed to load predictions');
  }

  static Future<Map<String, dynamic>> setupWebhook({
    required String repo,
    required String githubToken,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/setup-webhook'),
      headers: headers,
      body: jsonEncode({'repo': repo, 'github_token': githubToken}),
    );
    return jsonDecode(response.body);
  }
}
