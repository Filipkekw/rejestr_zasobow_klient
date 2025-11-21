import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/item.dart';
import '../pages/add_item_page.dart';
import 'sort_page.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'item_preview_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final ApiService api = ApiService('http://192.168.2.136:8000'); // <- IP twojego RPi z :8000
  late Future<List<Item>> _futureItems;
  late WebSocketChannel _channel;

  bool _selectionMode = false;
  bool _editMode = false;
  Set<int> _selectedIds = {}; // ID zaznaczonych rekordów
  String _sortOrder = 'none';
  List<String> _filterCategories = [];
  bool _searchMode = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureItems = api.fetchItems();

    _channel = IOWebSocketChannel.connect('ws://192.168.2.136:8000/ws'); // <- IP twojego RPi z :8000
    _channel.stream.listen(
      (message) {
        if (message.contains('reload')) {
          setState(() {
            _futureItems = api.fetchItems();
          });
        }
      },
      onError: (error) => print('❌ Błąd WebSocket: $error'),
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  // -------------------- USUWANIE --------------------
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdzenie'),
        content: Text(
            'Czy na pewno chcesz usunąć ${_selectedIds.length} element(y)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (var id in _selectedIds) {
        await api.deleteItem(id);
      }
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
        _futureItems = api.fetchItems();
      });
    }
  }

  // -------------------- EDYCJA --------------------
  Future<void> _openEditPage(Item item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddItemPage(editItem: item)),
    );

    setState(() {
      _editMode = false;
      if (result == true) {
        _futureItems = api.fetchItems();
      }
    });
  }
  // -------------------- SORTOWANIE --------------------
  Future<void> _openSortPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SortPage(
          sortOrder: _sortOrder,
          selectedCategories: _filterCategories,
        ),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        _sortOrder = result['sortOrder'] as String;
        _filterCategories =
            List<String>.from(result['categories'] as List<String>);
      });
    }
  }

  Future<void> _refreshConnectionAndList() async {
    try {
      // zamknij stare połączenie, jeśli istnieje
      await _channel.sink.close();
    } catch (_) {}

    // spróbuj ponownie utworzyć połączenie WebSocket
    try {
      _channel = IOWebSocketChannel.connect('ws://192.168.2.136:8000/ws'); // <- IP twojego RPi z :8000/ws
      _channel.stream.listen(
        (message) {
          if (message.contains('reload')) {
            setState(() {
              _futureItems = api.fetchItems();
            });
          }
        },
        onError: (error) {
          print('❌ Błąd WebSocket po odświeżeniu: $error');
        },
      );

      // odśwież listę
      setState(() {
        _futureItems = api.fetchItems();
      });

      // pokaż komunikat sukcesu
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Połączenie odświeżone, lista zaktualizowana'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('❌ Błąd odświeżania: $e'),
          ),
        );
      }
    }
  }
  
  // -------------------- BUDOWA STRONY --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searchMode
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Szukaj...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              )
            : _selectionMode
                ? Text('Wybrane elementy: ${_selectedIds.length}')
                : _editMode
                    ? const Text('Wybierz element do edycji')
                    : const Text('Rejestr zasobów'),
        centerTitle: true,
        leading: (_selectionMode || _editMode || _searchMode)
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Anuluj tryb',
                onPressed: () {
                  setState(() {
                    if (_searchMode) {
                      _searchMode = false;
                      _searchController.clear();
                    }
                    _selectionMode = false;
                    _editMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Odśwież połączenie i listę',
                onPressed: _refreshConnectionAndList,
              ),
        actions: [
          if (!_selectionMode && !_editMode && !_searchMode)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Sortuj i filtruj',
                  onPressed: _openSortPage,
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Szukaj',
                  onPressed: () {
                    setState(() => _searchMode = true);
                  },
                ),
              ],
            ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Usuń wybrane',
              onPressed: _selectedIds.isEmpty ? null : _confirmDelete,
            ),
        ],
      ),
      body: FutureBuilder<List<Item>>(
        future: _futureItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          } else {
            List<Item> items = snapshot.data!;

            // --- dynamiczne wyszukiwanie ---
            if (_searchController.text.isNotEmpty) {
              final query = _searchController.text.toLowerCase();
              items = items.where((item) {
                return item.name.toLowerCase().contains(query) ||
                    item.serialNumber.toLowerCase().contains(query) ||
                    item.description.toLowerCase().contains(query);
              }).toList();
            }

            // (pozostały kod sortowania, filtrów itp.)

            // ---- filtr kategorii ----
            if (_filterCategories.isNotEmpty) {
              items = items
                  .where((item) => _filterCategories.contains(item.category))
                  .toList();
            }

            // ---- sortowanie daty ----
            if (_sortOrder == 'desc') {
              items.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate)); // nowsze na górze
            } else if (_sortOrder == 'asc') {
              items.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate)); // starsze na górze
            } else if (_sortOrder == 'none') {
                items.sort((a, b) => a.id.compareTo(b.id));
            }

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final isSelected = _selectedIds.contains(item.id);

                return GestureDetector(
                  onLongPress: () {
                    setState(() {
                      _selectionMode = true;
                      _selectedIds.add(item.id);
                    });
                  },
                  onDoubleTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemPreviewPage(item: item),
                      ),
                    );
                  },
                  onTap: _selectionMode
                      ? () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(item.id);
                            } else {
                              _selectedIds.add(item.id);
                            }
                          });
                        }
                      : _editMode
                          ? () {
                              _openEditPage(item);
                            }
                          : null,
                  child: Card(
                    color: isSelected
                        ? const Color(0xFF2E3A59)
                        : const Color(0xFF1E1E1E),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectionMode)
                            Checkbox(
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedIds.add(item.id);
                                  } else {
                                    _selectedIds.remove(item.id);
                                  }
                                });
                              },
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nazwa
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Kategoria + data
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.category,
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      item.purchaseDate,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Numer seryjny
                                if (item.serialNumber.isNotEmpty)
                                  Text(
                                    'SN: ${item.serialNumber}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                const SizedBox(height: 4),

                                // Opis
                                if (item.description.isNotEmpty)
                                  Text(
                                    item.description.length > 100
                                        ? '${item.description.substring(0, 100)}...'
                                        : item.description,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: SizedBox(
          height: 60,
          child: BottomAppBar(
            color: Colors.blueAccent.withOpacity(0.9),
            elevation: 3,
            child: Row(
              children: [
                // 🗑 Usuń
                Expanded(
                  child: InkResponse(
                    radius: 0,
                    onTap: () {
                      setState(() {
                        _selectionMode = true;
                        _editMode = false;
                      });
                    },
                    child: const SizedBox(
                      height: 60, // <- pełna wysokość obszaru dotykowego
                      child: Center(
                        child: Icon(Icons.delete, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),

                // ➕ Dodaj
                Expanded(
                  child: InkResponse(
                    radius: 0,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddItemPage()),
                      );
                      if (result == true) {
                        setState(() => _futureItems = api.fetchItems());
                      }
                      setState(() {
                        _selectionMode = false;
                        _editMode = false;
                      });
                    },
                    child: const SizedBox(
                      height: 60,
                      child: Center(
                        child: Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),

                // ✏️ Edytuj
                Expanded(
                  child: InkResponse(
                    radius: 0,
                    onTap: () {
                      setState(() {
                        _editMode = true;
                        _selectionMode = false;
                      });
                    },
                    child: const SizedBox(
                      height: 60,
                      child: Center(
                        child: Icon(Icons.edit, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}