import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService {
  static final List<Map<String, dynamic>> _bookmarkedArticles = [];
  static SharedPreferences? _prefs;
  static const String _storageKey = 'bookmarked_articles';

  static List<Map<String, dynamic>> get bookmarks => _bookmarkedArticles;

  // Call this once at app startup (before runApp) to load saved bookmarks.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final String? saved = _prefs?.getString(_storageKey);

    if (saved != null && saved.isNotEmpty) {
      try {
        final List decoded = json.decode(saved);
        _bookmarkedArticles
          ..clear()
          ..addAll(decoded.map((e) => Map<String, dynamic>.from(e)));
      } catch (e) {
        // Corrupt/old data — ignore and start fresh.
      }
    }
  }

  static bool isBookmarked(String title) {
    return _bookmarkedArticles.any((article) => article['title'] == title);
  }

  static void toggleBookmark(Map<String, dynamic> article) {
    if (isBookmarked(article['title'])) {
      _bookmarkedArticles.removeWhere((a) => a['title'] == article['title']);
    } else {
      _bookmarkedArticles.add(article);
    }
    _saveToDisk();
  }

  static Future<void> _saveToDisk() async {
    if (_prefs == null) return;
    await _prefs!.setString(_storageKey, json.encode(_bookmarkedArticles));
  }
}