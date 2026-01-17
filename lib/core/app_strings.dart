enum AppLanguage { pl, en }

extension AppLanguageX on AppLanguage {
  String get apiValue => this == AppLanguage.pl ? 'pl' : 'en';
  String get code => this == AppLanguage.pl ? 'PL' : 'EN';
}

AppLanguage appLanguageFromApiValue(String? value) {
  if (value == AppLanguage.en.apiValue) {
    return AppLanguage.en;
  }
  return AppLanguage.pl;
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
