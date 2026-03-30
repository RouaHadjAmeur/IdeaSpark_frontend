import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Test de connectivité aux services IA...\n');

  // Test 1: Backend NestJS
  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/'),
      headers: {'Content-Type': 'application/json'},
    );
    print('✅ Backend NestJS: ${response.statusCode}');
  } catch (e) {
    print('❌ Backend NestJS: $e');
  }

  // Test 2: Prompt Refiner endpoint
  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/prompt-refiner/refine'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': 'test'}),
    );
    print('✅ Prompt Refiner: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('   Body: ${response.body}');
    }
  } catch (e) {
    print('❌ Prompt Refiner: $e');
  }

  // Test 3: Product Generator endpoint
  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/ia-scratch/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'besoin': 'test'}),
    );
    print('✅ Product Generator: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('   Body: ${response.body}');
    }
  } catch (e) {
    print('❌ Product Generator: $e');
  }

  // Test 4: API unifiée directe
  try {
    final response = await http.get(
      Uri.parse('http://localhost:8000/health'),
      headers: {'Content-Type': 'application/json'},
    );
    print('✅ API Unifiée (directe): ${response.statusCode}');
    if (response.statusCode == 200) {
      print('   Body: ${response.body}');
    }
  } catch (e) {
    print('❌ API Unifiée (directe): $e');
  }
}
