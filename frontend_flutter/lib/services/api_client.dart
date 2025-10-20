import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiClient {
  final http.Client _http;

  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  Future<Map<String, dynamic>> getJson(String url) async {
    final res = await _http.get(Uri.parse(url), headers: {
      'Accept': 'application/json',
    });
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Request failed ${res.statusCode}: ${res.body}');
    }
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> health() async {
    return getJson(ApiConfig.health());
  }

  Future<List<dynamic>> parks() async {
    final data = await getJson(ApiConfig.parks());
    return data['data'] ?? data['parks'] ?? [];
  }

  Future<List<dynamic>> routes() async {
    final data = await getJson(ApiConfig.routes());
    return data['data'] ?? data['routes'] ?? [];
  }
}


