import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static final List<Map<String, dynamic>> _history = [];
  static SharedPreferences? _prefs;
  static const String _storageKey = 'reading_history';
  static const int _maxItems = 50;

  static List<Map<String, dynamic>> get history => _history;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final String? saved = _prefs?.getString(_storageKey);

    if (saved != null && saved.isNotEmpty) {
      try {
        final List decoded = json.decode(saved);
        _history
          ..clear()
          ..addAll(decoded.map((e) => Map<String, dynamic>.from(e)));
      } catch (e) {
        // Corrupt/old data — ignore and start fresh.
      }
    }
  }

  static void addToHistory(Map<String, dynamic> article) {
    // Remove any existing entry for this article, then re-add at the top
    // (most recently read first) with a timestamp.
    _history.removeWhere((a) => a['title'] == article['title']);

    final entry = Map<String, dynamic>.from(article);
    entry['readAt'] = DateTime.now().toIso8601String();

    _history.insert(0, entry);

    if (_history.length > _maxItems) {
      _history.removeRange(_maxItems, _history.length);
    }

    _saveToDisk();
  }

  static void clearHistory() {
    _history.clear();
    _saveToDisk();
  }

  static Future<void> _saveToDisk() async {
    if (_prefs == null) return;
    await _prefs!.setString(_storageKey, json.encode(_history));
  }
}