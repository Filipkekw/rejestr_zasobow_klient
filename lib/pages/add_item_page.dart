import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/item.dart'; // model z id, name, category, purchaseDate itp.

class AddItemPage extends StatefulWidget {
  final Item? editItem; // null -> dodawanie, nie-null -> edycja
  const AddItemPage({super.key, this.editItem});

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

    // jeśli to edycja → wypełnij formularz istniejącymi danymi
    if (widget.editItem != null) {
      final e = widget.editItem!;
      _nameController.text = e.name;
      _serialController.text = e.serialNumber;
      _descriptionController.text = e.description;
      _selectedCategory = e.category;
      _selectedDate = DateTime.tryParse(e.purchaseDate) ?? DateTime.now();
    }
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
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final isEditing = widget.editItem != null;
    final api = ApiService('http://192.168.2.136:8000'); // IP twojego RPi

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edytuj przedmiot' : 'Dodaj przedmiot'),
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
                          TextEditingController(text: dateFormatted),
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

              // --- Przycisk ZAPIS/ZAKTUALIZUJ ---
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final dateStr =
                          DateFormat('yyyy-MM-dd').format(_selectedDate);

                      try {
                        if (isEditing) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Zapisywanie zmian...')),
                          );
                          api
                              .updateItem(
                                widget.editItem!.id,
                                _nameController.text.trim(),
                                _selectedCategory ?? 'Inne',
                                dateStr,
                                _serialController.text.trim(),
                                _descriptionController.text.trim(),
                              )
                              .then((_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✏️ Zaktualizowano przedmiot')),
                              );
                              Navigator.pop(context, true); // wróć na główną
                            }
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Zapisywanie zmian...')),
                          );
                          api
                              .addItem(
                                name: _nameController.text.trim(),
                                category: _selectedCategory ?? 'Inne',
                                purchaseDate: dateStr,
                                serialNumber: _serialController.text.trim(),
                                description: _descriptionController.text.trim(),
                              )
                              .then((_) {
                            if (context.mounted) {
                              Navigator.pop(context, true);
                            }
                          });
                        }

                        if (context.mounted) {
                          Navigator.pop(context, true);
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
                  label: Text(isEditing ? 'ZAKTUALIZUJ' : 'ZAPISZ'),
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