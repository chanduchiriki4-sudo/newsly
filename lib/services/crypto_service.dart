import 'dart:convert';
import 'package:http/http.dart' as http;

class CryptoService {
  static Future<List<Map<String, dynamic>>> fetchTopCrypto() async {
    try {
      final url = Uri.parse(
        'https://api.coingecko.com/api/v3/simple/price'
        '?ids=bitcoin,ethereum,ripple,dogecoin'
        '&vs_currencies=usd'
        '&include_24hr_change=true',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);

      final coinNames = {
        'bitcoin': {'symbol': 'BTC', 'name': 'Bitcoin'},
        'ethereum': {'symbol': 'ETH', 'name': 'Ethereum'},
        'ripple': {'symbol': 'XRP', 'name': 'XRP'},
        'dogecoin': {'symbol': 'DOGE', 'name': 'Dogecoin'},
      };

      final List<Map<String, dynamic>> result = [];
      for (final id in coinNames.keys) {
        if (data[id] == null) continue;
        result.add({
          'id': id,
          'symbol': coinNames[id]!['symbol'],
          'name': coinNames[id]!['name'],
          'price': (data[id]['usd'] as num).toDouble(),
          'change24h': (data[id]['usd_24h_change'] as num?)?.toDouble() ?? 0.0,
        });
      }

      return result;
    } catch (e) {
      return [];
    }
  }
}