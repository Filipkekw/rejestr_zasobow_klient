import 'package:flutter/material.dart';

class SortPage extends StatefulWidget {
  final String sortOrder; // 'asc', 'desc' lub 'none'
  final List<String> selectedCategories;
  const SortPage({
    super.key,
    required this.sortOrder,
    required this.selectedCategories,
  });

  @override
  State<SortPage> createState() => _SortPageState();
}

class _SortPageState extends State<SortPage> {
  late String _sortOrder;
  late List<String> _selectedCategories;

  final List<String> _categories = [
    'Narzędzia',
    'IT',
    'Oprogramowanie',
    'Wyposażenie biurowe',
    'Transport',
    'BHP',
    'Meble',
    'Inne',
  ];

  @override
  void initState() {
    super.initState();
    _sortOrder = widget.sortOrder;
    _selectedCategories = List.from(widget.selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sortowanie i filtrowanie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sortuj po dacie:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            RadioListTile<String>(
              title: const Text('Od najnowszych do najstarszych'),
              value: 'desc',
              groupValue: _sortOrder,
              onChanged: (v) => setState(() => _sortOrder = v!),
            ),
            RadioListTile<String>(
              title: const Text('Od najstarszych do najnowszych'),
              value: 'asc',
              groupValue: _sortOrder,
              onChanged: (v) => setState(() => _sortOrder = v!),
            ),
            RadioListTile<String>(
              title: const Text('Bez sortowania'),
              value: 'none',
              groupValue: _sortOrder,
              onChanged: (v) => setState(() => _sortOrder = v!),
            ),
            const Divider(height: 30),
            const Text('Filtruj po kategoriach:',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategories.contains(cat);
                  return CheckboxListTile(
                    title: Text(cat),
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedCategories.add(cat);
                        } else {
                          _selectedCategories.remove(cat);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Zastosuj'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context, {
                    'sortOrder': _sortOrder,
                    'categories': _selectedCategories,
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}