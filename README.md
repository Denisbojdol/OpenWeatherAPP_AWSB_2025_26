# Dokumentacja techniczna (PL)

## Cel i zakres
Aplikacja mobilna prezentuje aktualna pogode oraz prognoze godzinowa i dzienna
z serwisu OpenWeatherMap. Uzytkownik moze wyszukiwac miasta, pobierac pogode
z lokalizacji GPS, odswiezac dane, przelaczac jednostki i jezyk, a takze
zapisywac ulubione miasta. Projekt jest prosty, bez zewnetrznego backendu:
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

## Ograniczenia
Aplikacja zalezy od stabilnosci GPS i polaczenia sieciowego.
W przypadku braku lokalizacji (np. emulator bez ustawionej pozycji) mozliwy
jest timeout, co zostanie pokazane w komunikacie bledu.
