import 'package:shared_preferences/shared_preferences.dart';

class CityService {
  static String selectedCity = '';
  static SharedPreferences? _prefs;
  static const String _storageKey = 'user_city';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    selectedCity = _prefs?.getString(_storageKey) ?? '';
  }

  static Future<void> setCity(String city) async {
    selectedCity = city.trim();
    await _prefs?.setString(_storageKey, selectedCity);
  }

  static bool get hasCity => selectedCity.isNotEmpty;
}