# Rejestr Zasobów – klient Flutter

Aplikacja mobilna łącząca się z serwerem FastAPI uruchomionym na Raspberry Pi przez sieć Wi‑Fi.  
Pozwala na przeglądanie zasobów z bazy SQLite zainstalowanej na RPi.

## Funkcje
- pobiera listę pozycji z bazy na Raspberry Pi,
- wyświetla nazwę, kategorię i datę zakupu i opis,
- dodaje element do listy 


## Wymagania
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code z pluginem Flutter
- Telefon z Androidem lub emulator
- Działający serwer FastAPI na Raspberry Pi (plik `wifi_server.py`)
    - Instrukcje konfiguracji serwera zawarte w pliku README.md na github.com/Filipkekw/Rejestr_zasobow_RPi-4

---

## Konfiguracja połączenia z RPi

W pliku `lib/api/api_service.dart` zmień adres IP na adres Twojego Raspberry Pi, np.:

```dart
final ApiService api = ApiService('http://192.168.2.10:8000');
```

Adres IP twojego Raspberry Pi sprawdzisz poleceniem:
```bash
hostname -I;
```
Upewnij się, że telefon i RPi są w tej samej sieci Wi-Fi.

## Instalacja 
W terminalu projektu wpisz:
```bash
flutter pub get;
```
## Uruchamianie na telefonie
1. Podłącz telefon z Androidem do komputera przez kabel USB.
2. Włącz Opcje programisty i Debugowanie USB
3. Sprawdź połączenie w terminalu:
```bash
flutter devices
```
4. Uruchom aplikacje:
```bash
flutter run
```

## Budowanie i instalacja APK
Aby utworzyć plik APK do ręcznej instalacji wpisz w terminalu:
```bash
flutter build apk --release
```
Utworzony plik skopiuj na telefon i zainstaluj.