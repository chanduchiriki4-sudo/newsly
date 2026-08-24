import 'dart:convert';
import 'package:http/http.dart' as http;

class WikipediaService {
  // Fetches a short list of related topic titles for a query using
  // Wikipedia's free, keyless search API. Used purely to expand a
  // GNews search with a couple of closely related terms.
  static Future<List<String>> fetchRelatedTopics(String query) async {
    try {
      final url = Uri.parse(
        'https://en.wikipedia.org/w/api.php'
        '?action=query'
        '&list=search'
        '&srsearch=${Uri.encodeComponent(query)}'
        '&format=json'
        '&srlimit=3',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      final results = data['query']?['search'] as List?;
      if (results == null) return [];

      return results
          .map((r) => (r['title'] ?? '').toString())
          .where((title) => title.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }
}