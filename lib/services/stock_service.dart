import 'dart:convert';
import 'package:http/http.dart' as http;

class StockService {
  static Future<List<Map<String, dynamic>>> fetchIndices() async {
    final symbols = {
      '^NSEI': 'NIFTY 50',
      '^BSESN': 'SENSEX',
    };

    final List<Map<String, dynamic>> result = [];

    for (final entry in symbols.entries) {
      try {
        final url = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/${entry.key}',
        );
        final response = await http.get(
          url,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        );

        if (response.statusCode != 200) continue;

        final data = json.decode(response.body);
        final meta = data['chart']?['result']?[0]?['meta'];
        if (meta == null) continue;

        final double price = (meta['regularMarketPrice'] as num).toDouble();
        final double prevClose = (meta['previousClose'] ?? meta['chartPreviousClose'] as num).toDouble();
        final double change = price - prevClose;
        final double changePercent = prevClose != 0 ? (change / prevClose) * 100 : 0;

        result.add({
          'name': entry.value,
          'price': price,
          'change24h': changePercent,
        });
      } catch (e) {
        // Skip this index if it fails — don't block the others.
        continue;
      }
    }

    return result;
  }
}