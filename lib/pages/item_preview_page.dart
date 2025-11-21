import 'package:flutter/material.dart';
import '../models/item.dart';
import '../api/api_service.dart';
import '../pages/add_item_page.dart';

class ItemPreviewPage extends StatefulWidget {
  final Item item;
  const ItemPreviewPage({super.key, required this.item});

  @override
  State<ItemPreviewPage> createState() => _ItemPreviewPageState();
}

class _ItemPreviewPageState extends State<ItemPreviewPage> {
  final ApiService api = ApiService('http://192.168.2.136:8000'); // Adres IP twojego RPi z :8000

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Potwierdzenie usunięcia'),
        content: const Text('Czy na pewno chcesz usunąć ten przedmiot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm != true) return; // użytkownik anulował

    try {
      // pokaż krótki komunikat "trwa usuwanie"
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 800),
          content: Text('Usuwanie...'),
        ),
      );

      // wykonaj DELETE na API
      await api.deleteItem(widget.item.id);

      // komunikat potwierdzenia
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('🗑️ Usunięto „${widget.item.name}”'),
            duration: const Duration(seconds: 1),
          ),
        );

        // wróć do listy i przekaż wynik, który odświeży główny ekran
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Błąd usuwania: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Nazwa ---
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // --- Kategoria + data ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.category,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Data zakupu: ${item.purchaseDate}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 30),

            // --- Numer seryjny ---
            if (item.serialNumber.isNotEmpty)
              Text(
                'Numer seryjny:',
                style: TextStyle(
                  color: Colors.blueAccent.shade100,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (item.serialNumber.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 20),
                child: Text(
                  item.serialNumber,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

            // --- Opis ---
            const Text(
              'Opis:',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.description.isNotEmpty
                  ? item.description
                  : 'Brak opisu dla tego przedmiotu.',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),

            const Spacer(),

            // --- Dwa przyciski: edytuj i usuń ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddItemPage(editItem: item),
                      ),
                    );
                    if (result == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('✏️ Przedmiot został zaktualizowany')),
                      );
                      Navigator.pop(context, true); // wraca na główną z odświeżeniem
                    }
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text('Edytuj'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 35, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text('Usuń'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 35, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}