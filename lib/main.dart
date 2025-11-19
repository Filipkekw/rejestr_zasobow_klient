import 'package:flutter/material.dart';
import 'api/api_service.dart';
import 'models/item.dart';
import 'pages/add_item_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rejestr zasobów',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pl', 'PL'),
      ],
      locale: const Locale('pl', 'PL'),
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // ciemnoszary grafit
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(33, 150, 243, 1), // niebieski
          foregroundColor: Colors.white,
          elevation: 1,
        ),
      ),
      home: const ItemsPage(),
    );
  }
}

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final ApiService api = ApiService('http://192.168.2.71:8000'); // ← adres Pi w Twojej sieci
  late Future<List<Item>> _futureItems;
  late WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();

    _futureItems = api.fetchItems();

    _channel = IOWebSocketChannel.connect('ws://192.168.2.71:8000/ws');
    _channel.stream.listen(
      (message) {
        print('🔥 WebSocket otrzymał -> $message');
        if (message.contains('reload')) {
          setState(() {
            _futureItems = api.fetchItems();
          });
        }
      },
      onDone: () => print('⚠️ WebSocket zamknięty'),
      onError: (error) => print('❌ Błąd WebSocket: $error'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rejestr zasobów'), centerTitle: true),
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
                return ListTile(
                  title: Text(item.name),
                  subtitle:
                      Text('${item.category} — ${item.purchaseDate} - ${item.description}'),
                );
              },
            );
          }
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemPage()),
          );
          if (result == true) {
            setState(() {
              _futureItems = api.fetchItems(); // odśwież listę
            });
          }
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}