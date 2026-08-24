import 'package:flutter/material.dart';

class InfoStripCard extends StatelessWidget {
  final int? temperature;
  final String? weatherLabel;
  final String? weatherIcon;
  final List<Map<String, dynamic>> cryptoList;
  final List<Map<String, dynamic>> stockList;

  const InfoStripCard({
    super.key,
    this.temperature,
    this.weatherLabel,
    this.weatherIcon,
    required this.cryptoList,
    this.stockList = const [],
  });

  IconData get _weatherIconData {
    switch (weatherIcon) {
      case 'sunny':
        return Icons.wb_sunny_rounded;
      case 'partly_cloudy':
        return Icons.wb_cloudy_rounded;
      case 'fog':
        return Icons.foggy;
      case 'drizzle':
      case 'rain':
        return Icons.water_drop_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'storm':
        return Icons.thunderstorm_rounded;
      default:
        return Icons.cloud_rounded;
    }
  }

  List<Color> get _weatherGradient {
    switch (weatherIcon) {
      case 'sunny':
        return [const Color(0xFFFFA751), const Color(0xFFFF7A45)];
      case 'partly_cloudy':
        return [const Color(0xFF6FA8DC), const Color(0xFF4A7BB5)];
      case 'cloudy':
      case 'fog':
        return [const Color(0xFF8A97A8), const Color(0xFF64707F)];
      case 'drizzle':
      case 'rain':
        return [const Color(0xFF4A90D9), const Color(0xFF2E6FB5)];
      case 'snow':
        return [const Color(0xFF8FB8D9), const Color(0xFF5E8CB0)];
      case 'storm':
        return [const Color(0xFF5B5F7A), const Color(0xFF383B52)];
      default:
        return [const Color(0xFF4A90D9), const Color(0xFF2E6FB5)];
    }
  }

  // Builds a combined ticker list: stock indices first (₹), then crypto ($).
  List<Map<String, dynamic>> get _tickerItems {
    final items = <Map<String, dynamic>>[];

    for (final stock in stockList) {
      items.add({
        'label': stock['name'],
        'price': stock['price'],
        'change': stock['change24h'],
        'prefix': '₹',
        'decimals': 2,
      });
    }

    for (final coin in cryptoList) {
      items.add({
        'label': coin['symbol'],
        'price': coin['price'],
        'change': coin['change24h'],
        'prefix': '\$',
        'decimals': coin['price'] >= 1 ? 2 : 4,
      });
    }

    return items;
  }

  String _formatPrice(double price, String prefix, int decimals) {
    if (price >= 1000) {
      final formatted = price.toStringAsFixed(0);
      final withCommas = formatted.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
      return '$prefix$withCommas';
    }
    return '$prefix${price.toStringAsFixed(decimals)}';
  }

  @override
  Widget build(BuildContext context) {
    final bool hasWeather = temperature != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _tickerItems;

    return SizedBox(
      height: 86,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            if (hasWeather)
              Container(
                width: 128,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _weatherGradient,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_weatherIconData, color: Colors.white, size: 24),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$temperature°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            weatherLabel ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (hasWeather && items.isNotEmpty) const SizedBox(width: 10),
            if (items.isNotEmpty)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.withValues(alpha: 0.08),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final bool isPositive = (item['change'] as double) >= 0;
                      return Container(
                        width: 84,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        margin: EdgeInsets.only(
                          right: index == items.length - 1 ? 0 : 14,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item['label'],
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _formatPrice(item['price'], item['prefix'], item['decimals']),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositive
                                      ? Icons.arrow_drop_up_rounded
                                      : Icons.arrow_drop_down_rounded,
                                  size: 13,
                                  color: isPositive ? Colors.green : Colors.red,
                                ),
                                Text(
                                  '${item['change'].abs().toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isPositive ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}