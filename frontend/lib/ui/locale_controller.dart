import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide language. German is the default; the visitor's choice is remembered.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController() : super(defaultLocale);

  static const defaultLocale = Locale('de');
  static const supported = [Locale('de'), Locale('en')];
  static const _prefsKey = 'locale';

  Future<void> load() async {
    try {
      final code = (await SharedPreferences.getInstance()).getString(_prefsKey);
      final match = supported.where((l) => l.languageCode == code);
      if (match.isNotEmpty) value = match.first;
    } catch (_) {
      // Storage can be unavailable (private mode, blocked site data); keep the default.
    }
  }

  Future<void> set(Locale locale) async {
    if (locale == value) return;
    value = locale;
    try {
      await (await SharedPreferences.getInstance()).setString(_prefsKey, locale.languageCode);
    } catch (_) {}
  }
}

final localeController = LocaleController();
