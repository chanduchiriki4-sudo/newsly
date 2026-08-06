import 'dart:convert';
import 'package:http/http.dart' as http;
import 'language_service.dart';

class NewsService {
  static const String apiKey = 'edfe19fdd4ddb58bd7a40c064e41bccf';

  static Future<List<Map<String, dynamic>>> fetchTopHeadlines({
    String country = 'in',
    String category = 'general',
    int page = 1,
    String? lang,
  }) async {
    final language = lang ?? LanguageService.selectedLanguage;
    final url = Uri.parse(
      'https://gnews.io/api/v4/top-headlines?category=$category&lang=$language&country=$country&max=10&page=$page&apikey=$apiKey',
    );
    return _fetchAndParse(url);
  }

  static Future<List<Map<String, dynamic>>> searchNews(
    String query, {
    int page = 1,
    String sortBy = 'relevance', // 'relevance' or 'publishedAt'
    String? lang,
  }) async {
    final language = lang ?? LanguageService.selectedLanguage;
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
      'https://gnews.io/api/v4/search?q=$encodedQuery&lang=$language&max=10&page=$page&sortby=$sortBy&apikey=$apiKey',
    );
    return _fetchAndParse(url);
  }

  static Future<List<Map<String, dynamic>>> fetchTrending() async {
    final categories = ['technology', 'sports', 'business', 'entertainment'];

    try {
      final results = await Future.wait(
        categories.map(
          (cat) => fetchTopHeadlines(category: cat, page: 1).catchError(
            (_) => <Map<String, dynamic>>[],
          ),
        ),
      );

      final List<Map<String, dynamic>> merged = [];
      for (final list in results) {
        if (list.isNotEmpty) merged.add(list.first);
        if (list.length > 1) merged.add(list[1]);
      }

      merged.sort((a, b) {
        final dateA = DateTime.tryParse(a['publishedAt'] ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['publishedAt'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      return merged.take(8).toList();
    } catch (e) {
      return [];
    }
  }

  // Combines headlines from the user's top-read categories into one
  // personalized, deduplicated, most-recent-first feed.
  static Future<List<Map<String, dynamic>>> fetchForYou(
    List<String> topCategories,
  ) async {
    try {
      final results = await Future.wait(
        topCategories.map(
          (cat) => fetchTopHeadlines(category: cat, page: 1).catchError(
            (_) => <Map<String, dynamic>>[],
          ),
        ),
      );

      final List<Map<String, dynamic>> merged = [];
      for (final list in results) {
        merged.addAll(list);
      }

      final seen = <String>{};
      final deduped = merged.where((a) => seen.add(a['title'])).toList();

      deduped.sort((a, b) {
        final dateA = DateTime.tryParse(a['publishedAt'] ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['publishedAt'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      return deduped;
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchAndParse(Uri url) async {
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List articles = data['articles'] ?? [];

        return articles.map<Map<String, dynamic>>((article) {
          return {
            'title': article['title'] ?? 'No title',
            'description': article['description'] ?? '',
            'imageUrl': article['image'] ?? '',
            'source': article['source']?['name'] ?? 'Unknown',
            'publishedAt': article['publishedAt'] ?? '',
            'url': article['url'] ?? '',
            'isBookmarked': false,
          };
        }).toList();
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }
}