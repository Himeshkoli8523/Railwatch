import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'app_title': 'CCTV Train Monitoring',
      'login': 'Login',
      'otp_fallback': 'Use OTP fallback',
      'dashboard': 'Dashboard',
      'videos': 'Videos',
      'alerts': 'Alerts',
      'profile': 'Profile',
      'settings': 'Settings',
      'offline': 'Offline mode',
      'retry': 'Retry',
      'load_cached': 'Load cached data',
      'empty': 'No data available',
      'slow_backend': 'Backend is slow',
      'notification_center': 'Notification Center',
    },
  };

  String t(String key) =>
      _localizedValues[locale.languageCode]?[key] ??
      _localizedValues['en']![key] ??
      key;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
