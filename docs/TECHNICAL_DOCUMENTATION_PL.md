# Dokumentacja techniczna (PL)

## Cel aplikacji
Aplikacja mobilna prezentuje aktualna pogode oraz prognoze godzinowa i dzienna
dla wybranego miasta lub dla lokalizacji GPS. Uzytkownik moze wyszukiwac miasta,
odswiezac dane, przelaczac jednostki i jezyk, a takze zapisywac ulubione miasta.

## Architektura i struktura katalogow
Projekt jest podzielony na proste warstwy funkcjonalne:
- `lib/main.dart` - punkt startowy, uruchamia `WeatherApp`.
- `lib/app/weather_app.dart` - konfiguracja `MaterialApp`, motywy i przelacznik
  jasny/ciemny.
- `lib/screens/weather_screen.dart` - glowny ekran i logika UI (wyszukiwanie,
  lokalizacja, odswiezanie, ulubione).
- `lib/services/weather_service.dart` - komunikacja z OpenWeatherMap i obsluga
  bledow sieciowych.
- `lib/services/weather_cache.dart` - cache ostatnich poprawnych danych w
  `SharedPreferences`.
- `lib/models/weather_models.dart` - modele danych i mapowanie JSON.
- `lib/core/app_strings.dart`, `lib/core/unit_system.dart`,
  `lib/core/weather_visuals.dart` - teksty, jednostki, wizualizacje i ikony.

## Przeplyw danych
1. Uzytkownik uruchamia akcje (wyszukiwanie miasta lub przycisk Lokalizacja).
2. `WeatherScreen` wywoluje `_load`, a ten z kolei `WeatherService`.
3. `WeatherService` sprawdza polaczenie z internetem i pobiera dane z API.
4. Odpowiedz JSON jest mapowana na modele i zapisywana w cache.
5. UI odswieza widok oraz pokazuje czas ostatniej aktualizacji.

## Kluczowe funkcje i mechanizmy
- Lokalizacja GPS: korzysta z `geolocator`, z obsluga uprawnien i timeoutu.
- Wyszukiwanie miasta: walidacja zapytania, debounce i unikanie duplikatow.
- Jednostki i jezyk: przelaczanie metryczne/imperialne oraz PL/EN.
- Cache/offline: ostatnie poprawne dane sa przywracane po starcie aplikacji.
- Obsluga bledow: komunikaty dla braku internetu, timeoutu i bledow API.
- Ulubione: lokalna lista miast z szybkim wyborem.

## Konfiguracja i zaleznosci
Najwazniejsze paczki: `http`, `geolocator`, `intl`, `shared_preferences`,
`connectivity_plus`. Klucz API jest przekazywany przez
`--dart-define=OWM_API_KEY=...`. W Androidzie wymagane sa uprawnienia
`INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`.

## Uwagi o niezawodnosci
Zastosowano cache odpowiedzi oraz identyfikator zapytania w `WeatherScreen`,
aby nie nadpisywac stanu danymi z opoznionych odpowiedzi.
