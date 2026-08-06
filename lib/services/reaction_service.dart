import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReactionService {
  static final Map<String, String> _reactions = {}; // title -> emoji
  static SharedPreferences? _prefs;
  static const String _storageKey = 'article_reactions';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final String? saved = _prefs?.getString(_storageKey);

    if (saved != null && saved.isNotEmpty) {
      try {
        final Map decoded = json.decode(saved);
        _reactions
          ..clear()
          ..addAll(decoded.map((k, v) => MapEntry(k.toString(), v.toString())));
      } catch (e) {
        // Corrupt/old data — ignore and start fresh.
      }
    }
  }

  static String? getReaction(String title) {
    return _reactions[title];
  }

  static void setReaction(String title, String emoji) {
    if (_reactions[title] == emoji) {
      // Tapping the same reaction again removes it.
      _reactions.remove(title);
    } else {
      _reactions[title] = emoji;
    }
    _saveToDisk();
  }

  static Future<void> _saveToDisk() async {
    if (_prefs == null) return;
    await _prefs!.setString(_storageKey, json.encode(_reactions));
  }
}