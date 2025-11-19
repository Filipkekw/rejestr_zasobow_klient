import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';

class ApiService {
  final String baseUrl;
  ApiService(this.baseUrl);

  Future<List<Item>> fetchItems() async {
    final response = await http.get(Uri.parse('$baseUrl/items'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Item.fromJson(e)).toList();
    } else {
      throw Exception('Błąd pobierania danych: ${response.statusCode}');
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
        'name': name,
        'category': category,
        'purchase_date': purchaseDate,
        'serial_number': serialNumber,
        'description': description,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Nie udało się dodać elementu');
    }
  }

  Future<void> updateItem(
    int id,
    String name,
    String category,
    String purchaseDate,
    String serialNumber,
    String description,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/items/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'category': category,
        'purchase_date': purchaseDate,
        'serial_number': serialNumber,
        'description': description,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Nie udało się zaktualizować elementu $id');
    }
  }

  Future<void> deleteItem(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/items/$id'));
    if (response.statusCode != 200) {
      throw Exception('Nie udało się usunąć elementu $id');
    }
  }
}