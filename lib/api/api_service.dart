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
}