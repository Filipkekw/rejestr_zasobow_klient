class Item {
  final int id;
  final String name;
  final String category;
  final String purchaseDate;
  final String serialNumber;
  final String description;

  Item({
    required this.id,
    required this.name,
    required this.category,
    required this.purchaseDate,
    required this.serialNumber,
    required this.description,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      purchaseDate: json['purchase_date'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      description: json['description'] ?? '',
    );
  }
}