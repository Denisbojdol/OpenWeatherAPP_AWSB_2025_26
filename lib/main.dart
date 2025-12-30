import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() => runApp(const WeatherApp());

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0C6E7D);
    return MaterialApp(
      title: 'Pogoda Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seed,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      themeMode: _themeMode,
      home: WeatherScreen(onToggleTheme: _toggleTheme),
    );
  }
}

enum UnitSystem { metric, imperial }

extension UnitSystemX on UnitSystem {
  String get label {
    switch (this) {
      case UnitSystem.metric:
        return 'Metryczne (\u00B0C, km/h)';
      case UnitSystem.imperial:
        return 'Imperialne (\u00B0F, mph)';
    }
  }

  String get tempSymbol =>
      this == UnitSystem.metric ? '\u00B0C' : '\u00B0F';
  String get windUnit => this == UnitSystem.metric ? 'km/h' : 'mph';
  String get visibilityUnit => this == UnitSystem.metric ? 'km' : 'mi';
  String get apiValue => this == UnitSystem.metric ? 'metric' : 'imperial';

  String formatTemp(double value, {int digits = 1}) {
    return '${value.toStringAsFixed(digits)}$tempSymbol';
  }

  String formatWind(double speed) {
    return '${speed.toStringAsFixed(1)} $windUnit';
  }

  String formatVisibility(int meters) {
    final value =
        this == UnitSystem.metric ? meters / 1000 : meters / 1609.344;
    return '${value.toStringAsFixed(1)} $visibilityUnit';
  }

  double normalizeWindSpeed(double rawSpeed) {
    if (this == UnitSystem.metric) {
      return rawSpeed * 3.6;
    }
    return rawSpeed;
  }
}

enum AppLanguage { pl, en }

extension AppLanguageX on AppLanguage {
  String get apiValue => this == AppLanguage.pl ? 'pl' : 'en';
  String get code => this == AppLanguage.pl ? 'PL' : 'EN';
}

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isEnglish => language == AppLanguage.en;

  String get appTitle => isEnglish ? 'Weather Pro' : 'Pogoda Pro';
  String get searchHint =>
      isEnglish ? 'Enter city (e.g. Warsaw)' : 'Wpisz miasto (np. Krakow)';
  String get locationLabel => isEnglish ? 'Location' : 'Lokalizacja';
  String get searchLabel => isEnglish ? 'Search' : 'Szukaj';
  String get favoritesLabel => isEnglish ? 'Favorites' : 'Ulubione';
  String get unitsLabel => isEnglish ? 'Units' : 'Jednostki';
  String get unitMetricLabel => isEnglish
      ? 'Metric (\u00B0C, km/h)'
      : 'Metryczne (\u00B0C, km/h)';
  String get unitImperialLabel => isEnglish
      ? 'Imperial (\u00B0F, mph)'
      : 'Imperialne (\u00B0F, mph)';
  String get languageLabel => isEnglish ? 'Language' : 'Jezyk';
  String get themeLightLabel => isEnglish ? 'Light mode' : 'Tryb jasny';
  String get themeDarkLabel => isEnglish ? 'Dark mode' : 'Tryb ciemny';
  String get detailsTitle => isEnglish ? 'Details' : 'Szczegoly';
  String get hoursTitle => isEnglish ? 'Next hours' : 'Najblizsze godziny';
  String get daysTitle => isEnglish ? 'Next days' : 'Kolejne dni';
  String get refreshData => isEnglish ? 'Refresh data' : 'Odswiez dane';
  String get tryAgain => isEnglish ? 'Try again' : 'Sprobuj ponownie';
  String get emptyState => isEnglish
      ? 'Start by searching for a city or using your location.'
      : 'Zacznij od wyszukania miasta albo uzyj lokalizacji.';
  String get useLocation =>
      isEnglish ? 'Use location' : 'Uzyj lokalizacji';
  String get minLabel => 'Min';
  String get maxLabel => 'Max';
  String get feelsLike => isEnglish ? 'Feels like' : 'Odczuwalna';
  String get humidity => isEnglish ? 'Humidity' : 'Wilgotnosc';
  String get wind => isEnglish ? 'Wind' : 'Wiatr';
  String get pressure => isEnglish ? 'Pressure' : 'Cisnienie';
  String get visibility => isEnglish ? 'Visibility' : 'Widocznosc';
  String get sunrise => isEnglish ? 'Sunrise' : 'Wschod slonca';
  String get sunset => isEnglish ? 'Sunset' : 'Zachod slonca';
  String get precip => isEnglish ? 'Precip' : 'Opady';
  String get noDescription => isEnglish ? 'No description' : 'Brak opisu';
  String get emptyHourly =>
      isEnglish ? 'No hourly data.' : 'Brak danych godzinowych.';
  String get emptyDaily =>
      isEnglish ? 'No daily forecast.' : 'Brak prognozy dziennej.';
  String get favoritesTitle =>
      isEnglish ? 'Favorite cities' : 'Ulubione miasta';
  String get favoritesEmpty =>
      isEnglish ? 'No favorite cities.' : 'Brak ulubionych miast.';
  String get favoritesAddCurrent =>
      isEnglish ? 'Add current' : 'Dodaj biezace';
  String get favoritesAddTyped =>
      isEnglish ? 'Add from field' : 'Dodaj z pola';
  String get favoritesAlready =>
      isEnglish ? 'City already in favorites.' : 'Miasto jest juz na liscie.';
  String get removeLabel => isEnglish ? 'Remove' : 'Usun';
  String get closeLabel => isEnglish ? 'Close' : 'Zamknij';
  String get unitsTitle => isEnglish ? 'Units' : 'Jednostki';
  String get errorProvideCity => isEnglish
      ? 'Enter a city or use location.'
      : 'Podaj miasto lub uzyj lokalizacji.';
  String get errorLocationService => isEnglish
      ? 'Enable location services in system.'
      : 'Wlacz uslugi lokalizacji w systemie.';
  String get errorLocationDenied => isEnglish
      ? 'Location permission denied.'
      : 'Brak uprawnien do lokalizacji.';
  String get errorLocationForever => isEnglish
      ? 'Location permissions are permanently denied. Change them in settings.'
      : 'Uprawnienia sa zablokowane na stale. Zmien je w ustawieniach.';
  String get errorTimeout => isEnglish
      ? 'Request timed out.'
      : 'Przekroczono czas oczekiwania na odpowiedz.';
  String get errorAuth => isEnglish
      ? 'Authorization error. Check API key.'
      : 'Blad autoryzacji. Sprawdz klucz API.';
  String get errorCityNotFound => isEnglish
      ? 'City not found. Try a different name.'
      : 'Nie znaleziono miasta. Sprobuj innej nazwy.';
  String errorFetch(String details) => isEnglish
      ? 'Failed to fetch data. $details'
      : 'Nie udalo sie pobrac danych. $details';
  String updatedAt(String time) =>
      isEnglish ? 'Updated $time' : 'Aktualizacja $time';
  String get apiKeyMissing => isEnglish
      ? 'Missing API key. Run the app with --dart-define=OWM_API_KEY=YOUR_KEY.'
      : 'Brak klucza API. Uruchom aplikacje z --dart-define=OWM_API_KEY=TWOJ_KLUCZ.';
  String formatShortDate(DateTime date) {
    final weekday =
        (isEnglish ? _weekdayShortEn : _weekdayShortPl)[date.weekday - 1];
    final month =
        (isEnglish ? _monthShortEn : _monthShortPl)[date.month - 1];
    return '$weekday, ${date.day} $month';
  }
}
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _svc = WeatherService();
  final TextEditingController _searchController = TextEditingController();
  WeatherBundle? _bundle;
  DateTime? _lastUpdated;
  bool _loading = false;
  String? _error;
  String? _lastQuery;
  bool _lastUsedLocation = true;
  int _requestId = 0;
  final List<String> _favorites = <String>[];
  UnitSystem _unitSystem = UnitSystem.metric;
  AppLanguage _language = AppLanguage.pl;

  AppStrings get _strings => AppStrings(_language);

  @override
  void initState() {
    super.initState();
    _load(useLocation: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _svc.dispose();
    super.dispose();
  }

  Future<void> _load({String? city, bool useLocation = false}) async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      WeatherBundle data;
      if (useLocation) {
        final pos = await _resolveLocation();
        data = await _svc.fetchByLatLon(
          lat: pos.latitude,
          lon: pos.longitude,
          unitSystem: _unitSystem,
          language: _language,
        );
        _lastUsedLocation = true;
        _lastQuery = null;
      } else {
        final query = (city ?? _lastQuery ?? '').trim();
        if (query.isEmpty) {
          throw Exception(_strings.errorProvideCity);
        }
        data = await _svc.fetchByCity(
          query,
          unitSystem: _unitSystem,
          language: _language,
        );
        _lastUsedLocation = false;
        _lastQuery = query;
      }

      if (!mounted || requestId != _requestId) return;
      setState(() {
        _bundle = data;
        _lastUpdated = DateTime.now();
        _loading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = _formatError(error);
        _loading = false;
      });
    }
  }

  Future<Position> _resolveLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(_strings.errorLocationService);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception(_strings.errorLocationDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        _strings.errorLocationForever,
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 12),
    );
  }

  String _formatError(Object error) {
    if (error is StateError) {
      return error.message;
    }
    if (error is TimeoutException) {
      return _strings.errorTimeout;
    }
    final raw = error.toString();
    if (raw.contains('HTTP 401')) {
      return _strings.errorAuth;
    }
    if (raw.contains('city not found')) {
      return _strings.errorCityNotFound;
    }
    return _strings.errorFetch(raw);
  }

  @override
  Widget build(BuildContext context) {
    final data = _bundle;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final strings = _strings;
    final gradient = WeatherVisuals.gradientFor(
      data?.current.main,
      data?.current.time,
      brightness,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _SearchBar(
                  controller: _searchController,
                  onSearch: () => _load(city: _searchController.text),
                  onLocation: () => _load(useLocation: true),
                  onToggleTheme: widget.onToggleTheme,
                  onOpenUnits: _openUnits,
                  onOpenFavorites: _openFavorites,
                  onToggleLanguage: _toggleLanguage,
                  isDark: isDark,
                  strings: strings,
                ),
              ),
              if (_loading)
                const LinearProgressIndicator(minHeight: 3)
              else
                const SizedBox(height: 3),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      _load(city: _lastQuery, useLocation: _lastUsedLocation),
                  child: _buildBody(data),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(WeatherBundle? data) {
    final strings = _strings;
    if (data == null && _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data == null && _error != null) {
      return _ErrorState(
        message: _error!,
        onRetry: () => _load(useLocation: true),
        strings: strings,
      );
    }

    if (data == null) {
      return _EmptyState(
        onSearch: () => _load(city: _searchController.text),
        onLocation: () => _load(useLocation: true),
        strings: strings,
      );
    }

    final hourly = data.nextHours;
    final daily = data.dailyForecast;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (_error != null)
          _InlineError(message: _error!, onRetry: _refresh, strings: strings),
        _CurrentWeatherCard(
          weather: data.current,
          lastUpdated: _lastUpdated,
          unitSystem: _unitSystem,
          strings: strings,
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: strings.detailsTitle),
        const SizedBox(height: 8),
        _MetricsGrid(
          weather: data.current,
          unitSystem: _unitSystem,
          strings: strings,
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: strings.hoursTitle),
        const SizedBox(height: 8),
        _HourlyForecast(
          items: hourly,
          unitSystem: _unitSystem,
          strings: strings,
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: strings.daysTitle),
        const SizedBox(height: 8),
        _DailyForecast(
          items: daily,
          unitSystem: _unitSystem,
          strings: strings,
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: Text(strings.refreshData),
          ),
        ),
      ],
    );
  }

  void _refresh() {
    _load(city: _lastQuery, useLocation: _lastUsedLocation);
  }

  void _toggleLanguage() {
    setState(() {
      _language =
          _language == AppLanguage.pl ? AppLanguage.en : AppLanguage.pl;
    });
    _refresh();
  }

  void _openUnits() {
    final strings = _strings;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;

        void select(UnitSystem value) {
          if (value == _unitSystem) {
            Navigator.pop(context);
            return;
          }
          setState(() {
            _unitSystem = value;
          });
          Navigator.pop(context);
          _refresh();
        }

        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.unitsTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: strings.closeLabel,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                RadioListTile<UnitSystem>(
                  value: UnitSystem.metric,
                  groupValue: _unitSystem,
                  onChanged: (value) => select(value!),
                  title: Text(strings.unitMetricLabel),
                ),
                RadioListTile<UnitSystem>(
                  value: UnitSystem.imperial,
                  groupValue: _unitSystem,
                  onChanged: (value) => select(value!),
                  title: Text(strings.unitImperialLabel),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFavorites() {
    final strings = _strings;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final scheme = Theme.of(context).colorScheme;
            final currentCity = _bundle?.current.city;
            final typedCity = _searchController.text.trim();

            void addCity(String name) {
              final trimmed = name.trim();
              if (trimmed.isEmpty) return;
              final exists = _favorites.any(
                (city) => city.toLowerCase() == trimmed.toLowerCase(),
              );
              if (exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.favoritesAlready)),
                );
                return;
              }
              setState(() {
                _favorites.add(trimmed);
              });
              setModalState(() {});
            }

            void removeCity(String name) {
              setState(() {
                _favorites.removeWhere(
                  (city) => city.toLowerCase() == name.toLowerCase(),
                );
              });
              setModalState(() {});
            }

            Widget buildAddButton(String label, String? city) {
              final enabled = city != null && city.trim().isNotEmpty;
              return FilledButton.tonal(
                onPressed: enabled ? () => addCity(city!) : null,
                child: Text(label),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.75,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: scheme.onSurface.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  strings.favoritesTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                tooltip: strings.closeLabel,
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              buildAddButton(strings.favoritesAddCurrent, currentCity),
                              buildAddButton(strings.favoritesAddTyped, typedCity),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _favorites.isEmpty
                              ? Center(
                                  child: Text(
                                    strings.favoritesEmpty,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: scheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _favorites.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final city = _favorites[index];
                                    return ListTile(
                                      leading:
                                          const Icon(Icons.location_city),
                                      title: Text(city),
                                      trailing: IconButton(
                                        tooltip: strings.removeLabel,
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => removeCity(city),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _load(city: city);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onSearch,
    required this.onLocation,
    required this.onToggleTheme,
    required this.onToggleLanguage,
    required this.onOpenUnits,
    required this.onOpenFavorites,
    required this.isDark,
    required this.strings,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onLocation;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;
  final VoidCallback onOpenUnits;
  final VoidCallback onOpenFavorites;
  final bool isDark;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fillColor = scheme.surface.withOpacity(0.85);
    final iconColor = scheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: strings.searchHint,
              filled: true,
              fillColor: fillColor,
              prefixIcon: Icon(Icons.search, color: iconColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconAction(
                icon: Icons.my_location,
                label: strings.locationLabel,
                onTap: onLocation,
              ),
              _IconAction(
                icon: Icons.search,
                label: strings.searchLabel,
                onTap: onSearch,
              ),
              _IconAction(
                icon: Icons.star_border,
                label: strings.favoritesLabel,
                onTap: onOpenFavorites,
              ),
              _IconAction(
                icon: Icons.straighten,
                label: strings.unitsLabel,
                onTap: onOpenUnits,
              ),
              _LanguageAction(
                code: strings.language.code,
                label: strings.languageLabel,
                onTap: onToggleLanguage,
              ),
              _IconAction(
                icon: isDark ? Icons.light_mode : Icons.dark_mode,
                label:
                    isDark ? strings.themeLightLabel : strings.themeDarkLabel,
                onTap: onToggleTheme,
              ),
            ],
          ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Material(
        color: scheme.surface.withOpacity(0.85),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: scheme.onSurface),
        ),
      ),
    );
  }
}

class _LanguageAction extends StatelessWidget {
  const _LanguageAction({
    required this.code,
    required this.label,
    required this.onTap,
  });

  final String code;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Material(
        color: scheme.surface.withOpacity(0.85),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Text(
                code,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentWeatherCard extends StatelessWidget {
  const _CurrentWeatherCard({
    required this.weather,
    required this.lastUpdated,
    required this.unitSystem,
    required this.strings,
  });

  final CurrentWeather weather;
  final DateTime? lastUpdated;
  final UnitSystem unitSystem;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final formattedDate = strings.formatShortDate(weather.time);
    final updated = lastUpdated != null
        ? DateFormat('HH:mm').format(lastUpdated!)
        : null;

    return Card(
      color: scheme.surface.withOpacity(0.9),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.city,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
                WeatherIcon(
                  iconCode: weather.icon,
                  main: weather.main,
                  size: 64,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              unitSystem.formatTemp(weather.temp),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              weather.description,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _TempPill(
                  label: strings.minLabel,
                  value: weather.min,
                  unitSystem: unitSystem,
                ),
                const SizedBox(width: 8),
                _TempPill(
                  label: strings.maxLabel,
                  value: weather.max,
                  unitSystem: unitSystem,
                ),
                const Spacer(),
                if (updated != null)
                  Text(
                    strings.updatedAt(updated),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurface.withOpacity(0.6)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TempPill extends StatelessWidget {
  const _TempPill({
    required this.label,
    required this.value,
    required this.unitSystem,
  });

  final String label;
  final double value;
  final UnitSystem unitSystem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.onSurface.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label ${unitSystem.formatTemp(value)}',
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: scheme.onSurface),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.weather,
    required this.unitSystem,
    required this.strings,
  });

  final CurrentWeather weather;
  final UnitSystem unitSystem;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surface.withOpacity(0.9),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MetricTile(
              icon: Icons.thermostat,
              label: strings.feelsLike,
              value: unitSystem.formatTemp(weather.feelsLike),
            ),
            _MetricTile(
              icon: Icons.water_drop,
              label: strings.humidity,
              value: '${weather.humidity}%',
            ),
            _MetricTile(
              icon: Icons.air,
              label: strings.wind,
              value: unitSystem.formatWind(weather.windSpeed),
            ),
            _MetricTile(
              icon: Icons.speed,
              label: strings.pressure,
              value: '${weather.pressure} hPa',
            ),
            _MetricTile(
              icon: Icons.remove_red_eye,
              label: strings.visibility,
              value: unitSystem.formatVisibility(weather.visibility),
            ),
            _MetricTile(
              icon: Icons.sunny,
              label: strings.sunrise,
              value: DateFormat('HH:mm').format(weather.sunrise),
            ),
            _MetricTile(
              icon: Icons.nightlight_round,
              label: strings.sunset,
              value: DateFormat('HH:mm').format(weather.sunset),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: scheme.onSurface.withOpacity(0.08),
          child: Icon(icon, size: 18, color: scheme.onSurface),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: scheme.onSurface.withOpacity(0.6)),
              ),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HourlyForecast extends StatelessWidget {
  const _HourlyForecast({
    required this.items,
    required this.unitSystem,
    required this.strings,
  });

  final List<ForecastEntry> items;
  final UnitSystem unitSystem;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptySection(message: strings.emptyHourly);
    }
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _ForecastChip(
            time: DateFormat('HH:mm').format(item.time),
            temp: item.temp,
            pop: item.pop,
            icon: item.icon,
            main: item.main,
            unitSystem: unitSystem,
            strings: strings,
          );
        },
      ),
    );
  }
}

class _ForecastChip extends StatelessWidget {
  const _ForecastChip({
    required this.time,
    required this.temp,
    required this.pop,
    required this.icon,
    required this.main,
    required this.unitSystem,
    required this.strings,
  });

  final String time;
  final double temp;
  final double pop;
  final String icon;
  final String main;
  final UnitSystem unitSystem;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: scheme.onSurface.withOpacity(0.6)),
          ),
          WeatherIcon(iconCode: icon, main: main, size: 32),
          Text(
            unitSystem.formatTemp(temp, digits: 0),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            '${strings.precip} ${(pop * 100).round()}%',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurface.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

class _DailyForecast extends StatelessWidget {
  const _DailyForecast({
    required this.items,
    required this.unitSystem,
    required this.strings,
  });

  final List<DailyForecast> items;
  final UnitSystem unitSystem;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptySection(message: strings.emptyDaily);
    }
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surface.withOpacity(0.9),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final day = items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                    child: Text(
                      strings.formatShortDate(day.date),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                WeatherIcon(iconCode: day.icon, main: day.main, size: 32),
                const SizedBox(width: 10),
                Text(
                  '${unitSystem.formatTemp(day.max, digits: 0)} / '
                  '${unitSystem.formatTemp(day.min, digits: 0)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(day.pop * 100).round()}%',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: scheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.onRetry,
    required this.strings,
  });

  final String message;
  final VoidCallback onRetry;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surface.withOpacity(0.85),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: Colors.redAccent),
        title: Text(message),
        trailing: TextButton(
          onPressed: onRetry,
          child: Text(strings.tryAgain),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onSearch,
    required this.onLocation,
    required this.strings,
  });

  final VoidCallback onSearch;
  final VoidCallback onLocation;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      children: [
        const Icon(Icons.cloud_outlined, size: 80, color: Colors.white),
        const SizedBox(height: 16),
        Text(
          strings.emptyState,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onSearch,
          icon: const Icon(Icons.search),
          label: Text(strings.searchLabel),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onLocation,
          icon: const Icon(Icons.my_location),
          label: Text(strings.useLocation),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.strings,
  });

  final String message;
  final VoidCallback onRetry;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      children: [
        const Icon(Icons.warning_amber, size: 80, color: Colors.white),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(strings.tryAgain),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surface.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: scheme.onSurface.withOpacity(0.6)),
        ),
      ),
    );
  }
}

class WeatherIcon extends StatelessWidget {
  const WeatherIcon({
    super.key,
    required this.iconCode,
    required this.main,
    required this.size,
  });

  final String iconCode;
  final String main;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (iconCode.isEmpty) {
      return Icon(WeatherVisuals.iconFor(main), size: size);
    }
    return Image.network(
      'https://openweathermap.org/img/wn/${iconCode}@2x.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) =>
          Icon(WeatherVisuals.iconFor(main), size: size),
    );
  }
}

class WeatherVisuals {
  static LinearGradient gradientFor(
    String? main,
    DateTime? time,
    Brightness brightness,
  ) {
    final isNight = time != null && (time.hour < 6 || time.hour >= 19);
    List<Color> colors;
    switch (main) {
      case 'Clear':
        colors = isNight
            ? const [Color(0xFF0D1B2A), Color(0xFF1B263B)]
            : const [Color(0xFF3A86FF), Color(0xFF8ECAE6)];
        break;
      case 'Clouds':
        colors = const [Color(0xFF5C677D), Color(0xFFB5C0D0)];
        break;
      case 'Rain':
      case 'Drizzle':
        colors = const [Color(0xFF335C67), Color(0xFF76C1CF)];
        break;
      case 'Thunderstorm':
        colors = const [Color(0xFF22223B), Color(0xFF4A4E69)];
        break;
      case 'Snow':
        colors = const [Color(0xFFE0FBFC), Color(0xFF8ECAE6)];
        break;
      case 'Mist':
      case 'Fog':
      case 'Haze':
      case 'Smoke':
        colors = const [Color(0xFF6C757D), Color(0xFFADB5BD)];
        break;
      default:
        colors = const [Color(0xFF284B63), Color(0xFF3C6E71)];
    }

    if (brightness == Brightness.dark) {
      colors = colors.map((color) => _darken(color, 0.22)).toList();
    }

    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Color _darken(Color color, double amount) {
    final factor = 1 - amount;
    return Color.fromARGB(
      color.alpha,
      (color.red * factor).round(),
      (color.green * factor).round(),
      (color.blue * factor).round(),
    );
  }

  static IconData iconFor(String? main) {
    switch (main) {
      case 'Clear':
        return Icons.wb_sunny;
      case 'Clouds':
        return Icons.cloud;
      case 'Rain':
      case 'Drizzle':
        return Icons.grain;
      case 'Thunderstorm':
        return Icons.flash_on;
      case 'Snow':
        return Icons.ac_unit;
      case 'Mist':
      case 'Fog':
      case 'Haze':
      case 'Smoke':
        return Icons.blur_on;
      default:
        return Icons.cloud_outlined;
    }
  }
}

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  static const String _base = 'https://api.openweathermap.org/data/2.5';
  final http.Client _client;

  Future<WeatherBundle> fetchByCity(
    String city, {
    required UnitSystem unitSystem,
    required AppLanguage language,
  }) async {
    final currentJson = await _getJson(
      '/weather',
      {'q': city},
      unitSystem: unitSystem,
      language: language,
    );
    final current = CurrentWeather.fromJson(
      currentJson,
      unitSystem,
      language,
    );
    final forecastJson = await _getJson(
      '/forecast',
      {
        'lat': current.lat.toString(),
        'lon': current.lon.toString(),
      },
      unitSystem: unitSystem,
      language: language,
    );
    final forecast = ForecastData.fromJson(forecastJson);
    return WeatherBundle(
      current: current,
      hourly: forecast.entries,
      daily: forecast.daily,
    );
  }

  Future<WeatherBundle> fetchByLatLon({
    required double lat,
    required double lon,
    required UnitSystem unitSystem,
    required AppLanguage language,
  }) async {
    final currentJson = await _getJson(
      '/weather',
      {
        'lat': lat.toString(),
        'lon': lon.toString(),
      },
      unitSystem: unitSystem,
      language: language,
    );
    final current = CurrentWeather.fromJson(
      currentJson,
      unitSystem,
      language,
    );
    final forecastJson = await _getJson(
      '/forecast',
      {
        'lat': lat.toString(),
        'lon': lon.toString(),
      },
      unitSystem: unitSystem,
      language: language,
    );
    final forecast = ForecastData.fromJson(forecastJson);
    return WeatherBundle(
      current: current,
      hourly: forecast.entries,
      daily: forecast.daily,
    );
  }

  Future<Map<String, dynamic>> _getJson(
    String path,
    Map<String, String> params, {
    required UnitSystem unitSystem,
    required AppLanguage language,
  }) async {
    const apiKey = String.fromEnvironment('OWM_API_KEY');
    if (apiKey.isEmpty) {
      throw StateError(AppStrings(language).apiKeyMissing);
    }

    final uri = Uri.parse('$_base$path').replace(queryParameters: {
      ...params,
      'appid': apiKey,
      'units': unitSystem.apiValue,
      'lang': language.apiValue,
    });

    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      var message = 'HTTP ${res.statusCode}';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['message'] != null) {
          message = '$message: ${body['message']}';
        }
      } catch (_) {
        message = '$message: ${res.body}';
      }
      throw Exception(message);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  void dispose() {
    _client.close();
  }
}

class WeatherBundle {
  WeatherBundle({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  final CurrentWeather current;
  final List<ForecastEntry> hourly;
  final List<DailyForecast> daily;

  List<ForecastEntry> get nextHours {
    final now = DateTime.now();
    final upcoming = hourly
        .where((entry) => entry.time.isAfter(now.subtract(const Duration(hours: 1))))
        .toList();
    return upcoming.take(10).toList();
  }

  List<DailyForecast> get dailyForecast {
    final today = DateTime.now();
    return daily
        .where((day) => day.date.isAfter(DateTime(today.year, today.month, today.day - 1)))
        .take(6)
        .toList();
  }
}

class CurrentWeather {
  CurrentWeather({
    required this.city,
    required this.temp,
    required this.feelsLike,
    required this.min,
    required this.max,
    required this.humidity,
    required this.pressure,
    required this.visibility,
    required this.windSpeed,
    required this.sunrise,
    required this.sunset,
    required this.time,
    required this.description,
    required this.main,
    required this.icon,
    required this.lat,
    required this.lon,
  });

  final String city;
  final double temp;
  final double feelsLike;
  final double min;
  final double max;
  final int humidity;
  final int pressure;
  final int visibility;
  final double windSpeed;
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime time;
  final String description;
  final String main;
  final String icon;
  final double lat;
  final double lon;

  factory CurrentWeather.fromJson(
    Map<String, dynamic> json,
    UnitSystem unitSystem,
    AppLanguage language,
  ) {
    final weather =
        (json['weather'] as List<dynamic>? ?? const []).firstOrNull()
            as Map<String, dynamic>? ?? const {};
    final mainData = json['main'] as Map<String, dynamic>? ?? const {};
    final windData = json['wind'] as Map<String, dynamic>? ?? const {};
    final sysData = json['sys'] as Map<String, dynamic>? ?? const {};
    final coord = json['coord'] as Map<String, dynamic>? ?? const {};

    return CurrentWeather(
      city: json['name'] as String? ?? '-',
      temp: _toDouble(mainData['temp']),
      feelsLike: _toDouble(mainData['feels_like']),
      min: _toDouble(mainData['temp_min']),
      max: _toDouble(mainData['temp_max']),
      humidity: _toInt(mainData['humidity']),
      pressure: _toInt(mainData['pressure']),
      visibility: _toInt(json['visibility']),
      windSpeed:
          unitSystem.normalizeWindSpeed(_toDouble(windData['speed'])),
      sunrise: _fromSeconds(sysData['sunrise']),
      sunset: _fromSeconds(sysData['sunset']),
      time: _fromSeconds(json['dt']),
      description: (weather['description'] as String?)?.trim().isNotEmpty == true
          ? weather['description'] as String
          : AppStrings(language).noDescription,
      main: weather['main'] as String? ?? 'Clouds',
      icon: weather['icon'] as String? ?? '',
      lat: _toDouble(coord['lat']),
      lon: _toDouble(coord['lon']),
    );
  }
}

class ForecastEntry {
  ForecastEntry({
    required this.time,
    required this.temp,
    required this.main,
    required this.icon,
    required this.pop,
  });

  final DateTime time;
  final double temp;
  final String main;
  final String icon;
  final double pop;

  factory ForecastEntry.fromJson(Map<String, dynamic> json) {
    final weather =
        (json['weather'] as List<dynamic>? ?? const []).firstOrNull()
            as Map<String, dynamic>? ?? const {};
    final mainData = json['main'] as Map<String, dynamic>? ?? const {};
    return ForecastEntry(
      time: _fromSeconds(json['dt']),
      temp: _toDouble(mainData['temp']),
      main: weather['main'] as String? ?? 'Clouds',
      icon: weather['icon'] as String? ?? '',
      pop: _toDouble(json['pop']),
    );
  }
}

class DailyForecast {
  DailyForecast({
    required this.date,
    required this.min,
    required this.max,
    required this.main,
    required this.icon,
    required this.pop,
  });

  final DateTime date;
  final double min;
  final double max;
  final String main;
  final String icon;
  final double pop;
}

class ForecastData {
  ForecastData({required this.entries, required this.daily});

  final List<ForecastEntry> entries;
  final List<DailyForecast> daily;

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    final list = json['list'] as List<dynamic>? ?? const [];
    final entries = list
        .map((e) => ForecastEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final daily = _buildDaily(entries);
    return ForecastData(entries: entries, daily: daily);
  }

  static List<DailyForecast> _buildDaily(List<ForecastEntry> entries) {
    final map = <DateTime, _DailyAccumulator>{};
    for (final entry in entries) {
      final day = DateTime(entry.time.year, entry.time.month, entry.time.day);
      final accumulator = map.putIfAbsent(
        day,
        () => _DailyAccumulator(entry),
      );
      accumulator.add(entry);
    }

    final daily = map.entries
        .map((entry) => entry.value.toDaily(entry.key))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return daily;
  }
}

class _DailyAccumulator {
  _DailyAccumulator(ForecastEntry entry)
      : min = entry.temp,
        max = entry.temp,
        pop = entry.pop,
        representative = entry;

  double min;
  double max;
  double pop;
  ForecastEntry representative;

  void add(ForecastEntry entry) {
    min = math.min(min, entry.temp);
    max = math.max(max, entry.temp);
    pop = math.max(pop, entry.pop);
    final target = DateTime(
      entry.time.year,
      entry.time.month,
      entry.time.day,
      12,
    );
    if ((entry.time.difference(target).abs()) <
        (representative.time.difference(target).abs())) {
      representative = entry;
    }
  }

  DailyForecast toDaily(DateTime day) {
    return DailyForecast(
      date: day,
      min: min,
      max: max,
      main: representative.main,
      icon: representative.icon,
      pop: pop,
    );
  }
}

const List<String> _weekdayShortPl = [
  'Pon',
  'Wt',
  'Sr',
  'Czw',
  'Pia',
  'Sob',
  'Ndz',
];
const List<String> _monthShortPl = [
  'Sty',
  'Lut',
  'Mar',
  'Kwi',
  'Maj',
  'Cze',
  'Lip',
  'Sie',
  'Wrz',
  'Paz',
  'Lis',
  'Gru',
];
const List<String> _weekdayShortEn = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
const List<String> _monthShortEn = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return 0;
}

int _toInt(Object? value) {
  if (value is num) return value.toInt();
  return 0;
}

DateTime _fromSeconds(Object? value) {
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true)
        .toLocal();
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000, isUtc: true)
        .toLocal();
  }
  return DateTime.now();
}

extension on List<dynamic> {
  dynamic firstOrNull() => isEmpty ? null : first;
}
