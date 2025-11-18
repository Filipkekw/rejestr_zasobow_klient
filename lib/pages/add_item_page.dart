import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // do formatowania daty
import '../api/api_service.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();

  // Kontrolery pól tekstowych
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Kategorie
  final List<String> _categories = [
    'Narzędzia',
    'IT',
    'Oprogramowanie',
    'Wyposażenie biurowe',
    'Transport',
    'BHP',
    'Meble',
    'Inne'
  ];
  String? _selectedCategory;

  // Data zakupu
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj przedmiot'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Nazwa przedmiotu ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa przedmiotu',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Podaj nazwę' : null,
              ),
              const SizedBox(height: 20),

              // --- Kategoria ---
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Kategoria',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isDense: true,
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Data zakupu ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Data zakupu',
                        border: const OutlineInputBorder(),
                        hintText: dateFormatted,
                      ),
                      controller:
                          TextEditingController(text: dateFormatted), // pokazuje datę
                      onTap: () => _pickDate(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today,
                        color: Colors.blueAccent),
                    onPressed: () => _pickDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Numer seryjny ---
              TextFormField(
                controller: _serialController,
                decoration: const InputDecoration(
                  labelText: 'Numer seryjny',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // --- Opis ---
              TextFormField(
                controller: _descriptionController,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Opis przedmiotu',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // --- Przycisk ZAPISZ ---
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final api = ApiService('http://192.168.2.71:8000'); // ← adres Twojego RPi
                      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

                      try {
                        await api.addItem(
                          name: _nameController.text.trim(),
                          category: _selectedCategory ?? 'Inne',
                          purchaseDate: dateStr,
                          serialNumber: _serialController.text.trim(),
                          description: _descriptionController.text.trim(),
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Dodano nowy przedmiot')),
                          );
                          Navigator.pop(context, true); // wraca na główny ekran
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('❌ Błąd zapisu: $e')),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('ZAPISZ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}