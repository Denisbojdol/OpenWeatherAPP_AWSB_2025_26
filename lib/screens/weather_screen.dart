
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/core/app_strings.dart';
import 'package:flutter_application/core/unit_system.dart';
import 'package:flutter_application/core/weather_visuals.dart';
import 'package:flutter_application/models/weather_models.dart';
import 'package:flutter_application/services/weather_cache.dart';
import 'package:flutter_application/services/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

enum _ErrorKind { locationServiceDisabled }

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with WidgetsBindingObserver {
  static const int _maxQueryLength = 60;
  static const int _minQueryLength = 3;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 500);
  static const Duration _locationTimeout = Duration(seconds: 20);

  final WeatherService _svc = WeatherService();
  final TextEditingController _searchController = TextEditingController();
  WeatherBundle? _bundle;
  DateTime? _lastUpdated;
  Position? _lastPosition;
  bool _loading = false;
  String? _error;
  _ErrorKind? _errorKind;
  String? _lastQuery;
  bool _lastUsedLocation = true;
  bool _locationServiceEnabled = true;
  StreamSubscription<ServiceStatus>? _serviceStatusSub;
  Timer? _locationStatusPoll;
  int _requestId = 0;
  final List<String> _favorites = <String>[];
  UnitSystem _unitSystem = UnitSystem.metric;
  AppLanguage _language = AppLanguage.pl;
  Timer? _searchDebounce;

  AppStrings get _strings => AppStrings(_language);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreCache();
    _initLocationServiceStatus();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _serviceStatusSub?.cancel();
    _locationStatusPoll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _svc.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncLocationServiceStatus();
    }
  }

  Future<void> _restoreCache() async {
    final cached = await WeatherCache.load();
    if (!mounted || cached == null) return;
    setState(() {
      _bundle = cached.bundle;
      _lastUpdated = cached.updatedAt;
      _lastQuery = cached.cityQuery;
      _lastUsedLocation = cached.usedLocation;
      _unitSystem = cached.unitSystem;
      _language = cached.language;
    });
  }

  Future<void> _initLocationServiceStatus() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    _updateLocationServiceStatus(enabled);

    _serviceStatusSub?.cancel();
    _serviceStatusSub =
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (!mounted) return;
      _updateLocationServiceStatus(status == ServiceStatus.enabled);
    });

    if (enabled) {
      _load(useLocation: true);
    } else {
      _setLocationDisabledError();
    }
  }

  Future<void> _syncLocationServiceStatus() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    _updateLocationServiceStatus(enabled);
    if (!enabled) {
      _setLocationDisabledError();
    }
  }

  void _updateLocationServiceStatus(bool enabled) {
    setState(() {
      _locationServiceEnabled = enabled;
      if (enabled && _errorKind == _ErrorKind.locationServiceDisabled) {
        _error = null;
        _errorKind = null;
        _loading = false;
      }
    });
    if (enabled) {
      _locationStatusPoll?.cancel();
      _locationStatusPoll = null;
    } else if (_locationStatusPoll == null) {
      _locationStatusPoll = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _syncLocationServiceStatus(),
      );
    }
  }

  void _setLocationDisabledError() {
    setState(() {
      _locationServiceEnabled = false;
      _error = _strings.errorLocationService;
      _errorKind = _ErrorKind.locationServiceDisabled;
      _loading = false;
    });
    if (_locationStatusPoll == null) {
      _locationStatusPoll = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _syncLocationServiceStatus(),
      );
    }
  }

  String _sanitizeQuery(String input) {
    final collapsed = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length > _maxQueryLength) {
      return collapsed.substring(0, _maxQueryLength);
    }
    return collapsed;
  }

  void _runSearch() {
    if (!_locationServiceEnabled) {
      return;
    }
    final query = _sanitizeQuery(_searchController.text);
    _load(city: query);
  }

  void _onSearchChanged(String value) {
    if (!_locationServiceEnabled) {
      return;
    }
    _searchDebounce?.cancel();
    final query = _sanitizeQuery(value);
    if (query.isEmpty || query.length < _minQueryLength) {
      return;
    }
    if (_lastQuery != null &&
        query.toLowerCase() == _lastQuery!.toLowerCase()) {
      return;
    }
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      _load(city: query);
    });
  }

  Future<void> _handleLocationTap() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    _updateLocationServiceStatus(enabled);
    if (!enabled) {
      _setLocationDisabledError();
      _showToast(_strings.errorLocationService);
      return;
    }
    _load(useLocation: true);
  }

  Future<void> _load({String? city, bool useLocation = false}) async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
      _errorKind = null;
    });

    try {
      WeatherBundle data;
      String? resolvedCity;
      if (useLocation) {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (!mounted || requestId != _requestId) return;
        _updateLocationServiceStatus(enabled);
        if (!enabled) {
          _setLocationDisabledError();
          return;
        }
        final pos = await _resolveLocation();
        data = await _svc.fetchByLatLon(
          lat: pos.latitude,
          lon: pos.longitude,
          unitSystem: _unitSystem,
          language: _language,
        );
        resolvedCity = _sanitizeQuery(data.current.city);
      } else {
        final query = _sanitizeQuery(city ?? _lastQuery ?? '');
        if (query.isEmpty) {
          if (!mounted || requestId != _requestId) return;
          setState(() {
            _loading = false;
            _error = null;
            _errorKind = null;
          });
          _showToast(_strings.errorProvideCity);
          return;
        }
        data = await _svc.fetchByCity(
          query,
          unitSystem: _unitSystem,
          language: _language,
        );
        resolvedCity = query;
      }

      if (!mounted || requestId != _requestId) return;
      if (useLocation && resolvedCity != null && resolvedCity.isNotEmpty) {
        _searchController.value = TextEditingValue(
          text: resolvedCity,
          selection: TextSelection.collapsed(offset: resolvedCity.length),
        );
      }
      setState(() {
        _bundle = data;
        _lastUpdated = DateTime.now();
        _loading = false;
        if (useLocation) {
          _lastQuery = null;
          _lastUsedLocation = true;
        } else if (resolvedCity != null && resolvedCity.isNotEmpty) {
          _lastQuery = resolvedCity;
          _lastUsedLocation = false;
        } else {
          _lastQuery = null;
          _lastUsedLocation = false;
        }
        _errorKind = null;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      final errorKind = _errorKindFrom(error);
      setState(() {
        _error = _formatError(error);
        _errorKind = errorKind;
        _loading = false;
      });
    }
  }
  Future<Position> _resolveLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError(_strings.errorLocationService);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw StateError(_strings.errorLocationDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError(_strings.errorLocationForever);
    }

    final cached = _lastPosition ?? await Geolocator.getLastKnownPosition();
    if (cached != null) {
      _lastPosition = cached;
      return cached;
    }

    final forceAndroid =
        defaultTargetPlatform == TargetPlatform.android;
    Future<Position> getPosition({
      required LocationAccuracy accuracy,
    }) {
      return Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: _locationTimeout,
        forceAndroidLocationManager: forceAndroid,
      );
    }

    try {
      final position = await getPosition(accuracy: LocationAccuracy.high);
      _lastPosition = position;
      return position;
    } on TimeoutException {
      final fallback = await Geolocator.getLastKnownPosition();
      if (fallback != null) {
        _lastPosition = fallback;
        return fallback;
      }
      final position = await getPosition(
        accuracy: LocationAccuracy.low,
      );
      _lastPosition = position;
      return position;
    }
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

  _ErrorKind? _errorKindFrom(Object error) {
    if (error is StateError &&
        error.message == _strings.errorLocationService) {
      return _ErrorKind.locationServiceDisabled;
    }
    return null;
  }

  void _showToast(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                  onSearch: _runSearch,
                  onChanged: _onSearchChanged,
                  maxLength: _maxQueryLength,
                  searchEnabled: _locationServiceEnabled,
                  onLocation: _handleLocationTap,
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
                  onRefresh: () {
                    if (_lastUsedLocation && !_locationServiceEnabled) {
                      _showToast(_strings.errorLocationService);
                      _setLocationDisabledError();
                      return Future.value();
                    }
                    return _load(
                      city: _lastQuery,
                      useLocation: _lastUsedLocation,
                    );
                  },
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
      final showRetry = _errorKind != _ErrorKind.locationServiceDisabled;
      return _ErrorState(
        message: _error!,
        onRetry: () => _load(useLocation: true),
        showRetry: showRetry,
        strings: strings,
      );
    }

    if (data == null) {
      return _EmptyState(
        onSearch: _runSearch,
        onLocation: _handleLocationTap,
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
          _InlineError(
            message: _error!,
            onRetry: _refresh,
            showRetry: _errorKind != _ErrorKind.locationServiceDisabled,
            strings: strings,
          ),
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
            onPressed: _lastUsedLocation && !_locationServiceEnabled
                ? null
                : _refresh,
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
                              buildAddButton(
                                strings.favoritesAddCurrent,
                                currentCity,
                              ),
                              buildAddButton(
                                strings.favoritesAddTyped,
                                typedCity,
                              ),
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
    required this.onChanged,
    required this.maxLength,
    required this.searchEnabled,
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
  final ValueChanged<String> onChanged;
  final int maxLength;
  final bool searchEnabled;
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
    final fillColor =
        scheme.surface.withOpacity(searchEnabled ? 0.85 : 0.5);
    final iconColor =
        scheme.onSurface.withOpacity(searchEnabled ? 1 : 0.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          enabled: searchEnabled,
          textInputAction: TextInputAction.search,
          onChanged: searchEnabled ? onChanged : null,
          onSubmitted: searchEnabled ? (_) => onSearch() : null,
          inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
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
              enabled: searchEnabled,
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
              label: isDark
                  ? strings.themeLightLabel
                  : strings.themeDarkLabel,
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
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor =
        enabled ? scheme.onSurface : scheme.onSurface.withOpacity(0.4);
    final backgroundColor =
        scheme.surface.withOpacity(enabled ? 0.85 : 0.5);
    return Tooltip(
      message: label,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: enabled ? onTap : null,
          icon: Icon(icon, color: iconColor),
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withOpacity(0.6),
                        ),
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withOpacity(0.6),
                    ),
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
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(0.6),
                    ),
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.6),
                ),
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withOpacity(0.5),
                ),
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
    this.showRetry = true,
    required this.strings,
  });

  final String message;
  final VoidCallback onRetry;
  final bool showRetry;
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
        trailing: showRetry
            ? TextButton(
                onPressed: onRetry,
                child: Text(strings.tryAgain),
              )
            : null,
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
    this.showRetry = true,
    required this.strings,
  });

  final String message;
  final VoidCallback onRetry;
  final bool showRetry;
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
        if (showRetry)
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withOpacity(0.6),
              ),
        ),
      ),
    );
  }
}
