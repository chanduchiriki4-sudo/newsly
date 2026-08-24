import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  final int temperature;
  final String label;
  final String icon;

  const WeatherCard({
    super.key,
    required this.temperature,
    required this.label,
    required this.icon,
  });

  IconData get _iconData {
    switch (icon) {
      case 'sunny':
        return Icons.wb_sunny_rounded;
      case 'partly_cloudy':
        return Icons.wb_cloudy_rounded;
      case 'cloudy':
        return Icons.cloud_rounded;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A90D9), Color(0xFF2E6FB5)],
        ),
      ),
      child: Row(
        children: [
          Icon(_iconData, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$temperature°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.my_location_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
        ],
      ),
    );
  }
}