import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/item.dart';
import '../pages/add_item_page.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final ApiService api = ApiService('http://192.168.2.71:8000');
  late Future<List<Item>> _futureItems;
  late WebSocketChannel _channel;
  bool _selectionMode = false;
  Set<int> _selectedIds = {}; // ID zaznaczonych rekordów

  @override
  void initState() {
    super.initState();
    _futureItems = api.fetchItems();

    _channel = IOWebSocketChannel.connect('ws://192.168.2.71:8000/ws');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text('Wybrane elementy: ${_selectedIds.length}')
            : const Text('Rejestr zasobów'),
        centerTitle: true,
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Anuluj',
                onPressed: () {
                  setState(() {
                    _selectionMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Usuń wybrane',
              onPressed: _selectedIds.isEmpty ? null : _confirmDelete,
            )
          else
            null,
        ].whereType<Widget>().toList(),
      ),
      body: FutureBuilder<List<Item>>(
        future: _futureItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          } else {
            final items = snapshot.data!;
            if (items.isEmpty) {
              return const Center(child: Text('Brak danych'));
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
                  child: Card(
                    color: isSelected
                        ? const Color(0xFF2E3A59)
                        : const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Checkbox po lewej w trybie zaznaczenia
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Colors.blueAccent,
        overlayOpacity: 0.3,
        spacing: 10,
        spaceBetweenChildren: 8,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            backgroundColor: Colors.green,
            labelBackgroundColor: const Color(0xFF1E1E1E),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddItemPage()),
              );
              if (result == true) {
                setState(() => _futureItems = api.fetchItems());
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.delete),
            backgroundColor: Colors.redAccent,
            labelBackgroundColor: const Color(0xFF1E1E1E),
            onTap: () {
              setState(() => _selectionMode = true);
            },
          ),
        ],
      ),
    );
  }
}