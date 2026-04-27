import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/brand.dart';
import 'auth_service.dart';

class BrandService {
  BrandService._();

  static Future<String?> _getToken() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    return authService.accessToken;
  }

  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<Brand> createBrand(Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.createBrandUrl),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return Brand.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create brand: ${response.statusCode} - ${response.body}');
  }

  static Future<List<Brand>> getBrands({int page = 1, int limit = 50}) async {
    final token = await _getToken();
    final uri = Uri.parse(ApiConfig.getBrandsUrl).replace(queryParameters: {
      'page': '$page',
      'limit': '$limit',
    });
    final response = await http.get(uri, headers: _headers(token));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data = body['data'] ?? [];
      return data.map((e) => Brand.fromJson(e)).toList();
    }
    throw Exception('Failed to load brands: ${response.statusCode} - ${response.body}');
  }

  static Future<Brand> getBrandById(String id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.brandByIdUrl(id)),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return Brand.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load brand: ${response.statusCode} - ${response.body}');
  }

  static Future<Brand> updateBrand(String id, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse(ApiConfig.brandByIdUrl(id)),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return Brand.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update brand: ${response.statusCode} - ${response.body}');
  }

  static Future<void> deleteBrand(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse(ApiConfig.brandByIdUrl(id)),
      headers: _headers(token),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete brand: ${response.statusCode} - ${response.body}');
    }
  }
}
