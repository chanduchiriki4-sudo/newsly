import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static final List<String> _recentSearches = [];
  static SharedPreferences? _prefs;
  static const String _storageKey = 'recent_searches';
  static const int _maxItems = 8;

  static List<String> get recentSearches => _recentSearches;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final String? saved = _prefs?.getString(_storageKey);
    if (saved != null && saved.isNotEmpty) {
      try {
        final List decoded = json.decode(saved);
        _recentSearches
          ..clear()
          ..addAll(decoded.map((e) => e.toString()));
      } catch (e) {
        // ignore corrupt data
      }
    }
  }

  static void addSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _recentSearches.removeWhere((s) => s.toLowerCase() == trimmed.toLowerCase());
    _recentSearches.insert(0, trimmed);

    if (_recentSearches.length > _maxItems) {
      _recentSearches.removeRange(_maxItems, _recentSearches.length);
    }
    _saveToDisk();
  }

  static void clearHistory() {
    _recentSearches.clear();
    _saveToDisk();
  }

  static Future<void> _saveToDisk() async {
    if (_prefs == null) return;
    await _prefs!.setString(_storageKey, json.encode(_recentSearches));
  }
}