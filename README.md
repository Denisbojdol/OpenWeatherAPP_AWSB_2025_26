# Dokumentacja techniczna (PL)

## Cel i zakres
Aplikacja mobilna prezentuje aktualna pogode oraz prognoze godzinowa i dzienna
z serwisu OpenWeatherMap. Uzytkownik moze wyszukiwac miasta, pobierac pogode
z lokalizacji GPS, odswiezac dane, przelaczac jednostki i jezyk, a takze
zapisywac ulubione miasta. Projekt jest prosty w modelu SPA, bez zewnetrznego backendu:
logika aplikacji i komunikacja z API odbywaja sie po stronie klienta.

## Architektura i struktura katalogow
Kod jest rozbity na czytelne moduly:
- `lib/main.dart` - punkt startowy, uruchamia `WeatherApp`.
- `lib/app/weather_app.dart` - konfiguracja `MaterialApp`, motywy oraz
  przelacznik jasny/ciemny.
- `lib/screens/weather_screen.dart` - glowny ekran i logika UI
  (wyszukiwanie, lokalizacja, odswiezanie, ulubione, obsluga bledow).
- `lib/services/weather_service.dart` - komunikacja z OpenWeatherMap,
  walidacja polaczenia z internetem i obsluga bledow HTTP.
- `lib/services/weather_cache.dart` - cache ostatnich poprawnych danych
  w `SharedPreferences` (dla trybu offline i szybkiego startu).
- `lib/models/weather_models.dart` - modele domenowe i mapowanie JSON.
- `lib/core/app_strings.dart`, `lib/core/unit_system.dart`,
  `lib/core/weather_visuals.dart` - teksty, jednostki, wizualizacje i ikony.

## Opis katalogow
- `lib/` - glowny kod aplikacji (UI, modele, serwisy, logika).
- `android/`, `ios/`, `macos/`, `windows/`, `linux/`, `web/` - platformowe
  konfiguracje i projekty buildowe.
- `test/` - miejsce na testy jednostkowe i widgetowe.
- `docs/` - dokumentacja projektu (opcjonalnie).
- `build/` - artefakty budowania generowane przez Flutter (nie edytowac).
- `.dart_tool/` - dane narzedziowe Dart/Flutter (generowane).
- `.idea/` - pliki konfiguracyjne IDE.
### Podkatalogi w `lib/`
- `lib/app/` - konfiguracja aplikacji i entry widget.
- `lib/core/` - stale, teksty, jednostki i pomocnicze funkcje.
- `lib/models/` - modele danych i mapowanie JSON.
- `lib/screens/` - ekrany i logika UI.
- `lib/services/` - komunikacja z API i cache.

## Model danych
Warstwa modeli opisuje struktury otrzymywane z API:
- `CurrentWeather` - stan biezacy (temp, wilgotnosc, wiatr, cisnienie,
  widocznosc, wschod/zachod, opis i ikona).
- `ForecastEntry` - wpis prognozy godzinowej.
- `DailyForecast` - wpis prognozy dziennej (min/max, ikona, opady).
- `WeatherBundle` - agregat danych uzywany w UI.

## Przeplyw danych
1. Uzytkownik uruchamia akcje (wyszukiwanie miasta lub przycisk Lokalizacja).
2. `WeatherScreen` wywoluje `_load`, ktory steruje pobraniem danych.
3. `WeatherService` sprawdza polaczenie z internetem i wysyla requesty:
   `/weather` (biezace dane) oraz `/forecast` (prognoza).
4. Odpowiedz JSON jest mapowana na modele, a surowe dane trafiaja do cache.
5. UI odswieza widok i pokazuje czas ostatniej aktualizacji.

## UI i interakcje
Ekran glowny sklada sie z:
- belki wyszukiwania (pole tekstowe + akcje),
- kart stanu biezacego i sekcji metryk,
- list prognoz (godzinowa i dzienna),
- przycisku odswiezania i komunikatow o bledach.
Wyszukiwanie posiada debounce, limit dlugosci i walidacje pustego zapytania.

## Lokalizacja i uprawnienia
Lokalizacja jest pobierana przez `geolocator` z obsluga uprawnien
(`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`). Zastosowano timeout
oraz fallback do `getLastKnownPosition()`, aby uniknac zawieszenia.
Na emulatorze konieczne jest ustawienie lokalizacji w panelu narzedzi.

## Cache i tryb offline
Ostatnie poprawne dane (current + forecast) sa zapisywane w
`SharedPreferences`. Przy starcie aplikacji cache jest odczytywany, co
pozwala pokazac dane nawet bez internetu. Stan aktualizacji jest czytelnie
opisany w UI.

## Obsluga bledow i niezawodnosc
Wprowadzono:
- sprawdzanie polaczenia z internetem przed zapytaniem,
- komunikaty dla timeoutu, braku uprawnien i bledow API,
- ochrone przed nadpisaniem stanu przez opoznione odpowiedzi
  (identyfikator zapytania w `WeatherScreen`).

## Konfiguracja i zaleznosci
Najwazniejsze paczki: `http`, `geolocator`, `intl`, `shared_preferences`,
`connectivity_plus`. Klucz API jest przekazywany przez
`--dart-define=OWM_API_KEY=...`.

## Uruchomienie
Przykladowo:
- `flutter pub get`
- `flutter run --dart-define=OWM_API_KEY=YOUR_KEY`

## Testy
Testy jednostkowe znajduja sie w katalogu `test/` i obejmuja m.in.:
- formatowanie i konwersje jednostek (`unit_system_test.dart`),
- mapowanie JSON do modeli oraz agregacje prognozy (`weather_models_test.dart`).
Aby uruchomic testy, uzyj: `flutter test`.

## Ograniczenia
Aplikacja zalezy od stabilnosci GPS i polaczenia sieciowego.
W przypadku braku lokalizacji (np. emulator bez ustawionej pozycji) mozliwy
jest timeout, co zostanie pokazane w komunikacie bledu.

# Technical Documentation (EN)

## Purpose and scope
The mobile app shows current weather and hourly/daily forecasts from
OpenWeatherMap. The user can search for cities, use GPS location, refresh
data, switch units and language, and store favorite cities. The project is
client-only: all logic and API calls run on the device, with no backend.

## Architecture and folder structure
Code is split into clear modules:
- `lib/main.dart` - entry point, starts `WeatherApp`.
- `lib/app/weather_app.dart` - `MaterialApp` configuration, themes, and
  light/dark toggle.
- `lib/screens/weather_screen.dart` - main screen and UI logic
  (search, location, refresh, favorites, error handling).
- `lib/services/weather_service.dart` - OpenWeatherMap calls, connectivity
  check, and HTTP error handling.
- `lib/services/weather_cache.dart` - cache of last valid data in
  `SharedPreferences`.
- `lib/models/weather_models.dart` - domain models and JSON mapping.
- `lib/core/app_strings.dart`, `lib/core/unit_system.dart`,
  `lib/core/weather_visuals.dart` - strings, units, visuals, and icons.

## Directory overview
- `lib/` - main application code (UI, models, services, logic).
- `android/`, `ios/`, `macos/`, `windows/`, `linux/`, `web/` - platform
  configs and build projects.
- `test/` - unit and widget tests.
- `docs/` - project documentation (optional).
- `build/` - Flutter build artifacts (generated).
- `.dart_tool/` - Dart/Flutter tooling data (generated).
- `.idea/` - IDE config files.
### Subfolders inside `lib/`
- `lib/app/` - app configuration and entry widget.
- `lib/core/` - constants, strings, units, helper logic.
- `lib/models/` - data models and JSON mapping.
- `lib/screens/` - screens and UI logic.
- `lib/services/` - API communication and cache.

## Data model
Models describe API structures:
- `CurrentWeather` - current state (temp, humidity, wind, pressure,
  visibility, sunrise/sunset, description, icon).
- `ForecastEntry` - hourly forecast item.
- `DailyForecast` - daily forecast item (min/max, icon, precipitation).
- `WeatherBundle` - aggregated data used by the UI.

## Data flow
1. User triggers an action (city search or Location button).
2. `WeatherScreen` calls `_load`, which drives the request.
3. `WeatherService` checks connectivity and calls `/weather` and `/forecast`.
4. JSON responses are mapped to models and saved to cache.
5. UI is refreshed and shows last update time.

## UI and interactions
The main screen includes:
- search bar (text field + actions),
- current weather card and metrics section,
- hourly and daily forecast lists,
- refresh button and error messages.
Search uses debounce, length limit, and empty-input validation.

## Location and permissions
Location is obtained via `geolocator` with permission handling
(`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`). A timeout and a fallback
to `getLastKnownPosition()` are used to prevent hangs. On emulator, a manual
location must be set in the tools panel.

## Cache and offline mode
Last valid data (current + forecast) is saved in `SharedPreferences`.
On app start, cached data is restored so the UI can show data even without
internet. The UI displays the last update time.

## Error handling and reliability
The app includes:
- connectivity check before requests,
- messages for timeout, permission issues, and API errors,
- protection against stale responses overriding state
  (request id in `WeatherScreen`).

## Configuration and dependencies
Key packages: `http`, `geolocator`, `intl`, `shared_preferences`,
`connectivity_plus`. API key is passed via
`--dart-define=OWM_API_KEY=...`.

## Run
Example:
- `flutter pub get`
- `flutter run --dart-define=OWM_API_KEY=YOUR_KEY`

## Tests
Unit tests are located in `test/` and cover:
- unit formatting and conversions (`unit_system_test.dart`),
- JSON-to-model mapping and forecast aggregation (`weather_models_test.dart`).
Run tests with: `flutter test`.

## Limitations
The app depends on stable GPS and network connectivity. If location is
unavailable (e.g. emulator without a set position), a timeout can occur and
will be shown in an error message.
