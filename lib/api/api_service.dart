import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';

class ApiService {
  final String baseUrl;
  ApiService(this.baseUrl);

  Future<List<Item>> fetchItems() async {
    final response = await http.get(Uri.parse('$baseUrl/items'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Item.fromJson(e)).toList();
    } else {
      throw Exception('Błąd HTTP: ${response.statusCode}');
    }
  }

  Future<void> ping() async {
    final response = await http.get(Uri.parse('$baseUrl/ping'));
    if (response.statusCode != 200) {
      throw Exception('Ping nieudany');
    }
  }
  Future<void> addItem({
    required String name,
    required String category,
    required String purchaseDate,
    required String serialNumber,
    required String description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/items'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": name,
        "category": category,
        "purchase_date": purchaseDate,
        "serial_number": serialNumber,
        "description": description,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Nie udało się dodać elementu: ${response.statusCode}');
    }
  }
}