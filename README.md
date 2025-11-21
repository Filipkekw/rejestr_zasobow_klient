# Rejestr Zasobów – klient Flutter

Klient mobilny Flutter do obsługi systemu "Rejestr zasobów" uruchomionego na Raspberry Pi.
Łączy się z serwerem FastAPI po HTTP/WebSocket i umożliwia zarządzanie zasobami z telefonu.

## Wymagania
- Flutter SDK 3.x
- Android Studio lub VS Code z pluginem Flutter
- Telefon z Androidem z włączonym debugowaniem USB
- Raspberry Pi z działającym serwerem 'wifi_server.py'

## Konfiguracja

1. Ustaw adres IP serwera RPi w:

'lib/pages/add_item_page.dart':
```dart
final api = ApiService('http://x.x.x.x:8000'); // linia 90
```
'lib/pages/main_page.dart':
```dart
final ApiService api = ApiService('http://x.x.x.x:8000'); // linia 17
_channel = IOWebSocketChannel.connect('ws://x.x.x.x:8000/ws'); // linia 35 i 130
```
'lib/pages/item_preview_page.dart':
```dart
final ApiService api = ApiService('http://x.x.x.x:8000'); // linia 15
```
2. Upewnij się, że serwer na RPi działa:
```bash
python3 wifi_server.py
```
## Uruchamianie
1. Podłącz telefon przez USB i włącz debugowanie USB.
2. Sprawdź urządzenie:
```bash
flutter devices
```
3. Uruchom aplikację:
```bash
flutter run
```
## Funkcje
- Wyświetlanie listy zasobów z bazy RPi.
- Dodawanie, edycja, usuwanie zasobów.
- Sortowanie po dacie oraz filtrowanie po kategoriach.
- Wyszukiwanie po nazwie, numerze seryjnym i opisie.
- Podgląd szczegółów przedmiotu (z poziomu listy).
- Automatyczna synchronizacja zmian z RPi (WebSocket).
