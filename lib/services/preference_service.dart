import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static final Map<String, int> _categoryCounts = {};
  static SharedPreferences? _prefs;
  static const String _storageKey = 'category_preferences';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final String? saved = _prefs?.getString(_storageKey);

    if (saved != null && saved.isNotEmpty) {
      try {
        final Map decoded = json.decode(saved);
        _categoryCounts
          ..clear()
          ..addAll(decoded.map((k, v) => MapEntry(k.toString(), v as int)));
      } catch (e) {
        // Corrupt/old data — ignore and start fresh.
      }
    }
  }

  static void recordCategoryView(String category) {
    if (category == 'foryou') return; // don't count the meta-category itself
    _categoryCounts[category] = (_categoryCounts[category] ?? 0) + 1;
    _saveToDisk();
  }

  // Returns the user's top categories by interest, most-read first.
  // Falls back to sensible defaults if there isn't enough data yet.
  static List<String> topCategories({int count = 3}) {
    if (_categoryCounts.isEmpty) {
      return ['general', 'technology', 'sports'].take(count).toList();
    }

    final sorted = _categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.map((e) => e.key).take(count).toList();

    // Pad with defaults if the user has only tried 1-2 categories so far.
    for (final fallback in ['general', 'technology', 'sports']) {
      if (top.length >= count) break;
      if (!top.contains(fallback)) top.add(fallback);
    }

    return top;
  }

  static Future<void> _saveToDisk() async {
    if (_prefs == null) return;
    await _prefs!.setString(_storageKey, json.encode(_categoryCounts));
  }
}