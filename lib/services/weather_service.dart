import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static Future<Map<String, dynamic>?> fetchCurrentWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition();

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${position.latitude}'
        '&longitude=${position.longitude}'
        '&current=temperature_2m,weather_code'
        '&timezone=auto',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      final current = data['current'];

      return {
        'temperature': (current['temperature_2m'] as num).round(),
        'weatherCode': current['weather_code'] as int,
      };
    } catch (e) {
      return null;
    }
  }

  // Maps Open-Meteo's WMO weather codes to a simple label + icon name.
  static Map<String, String> describeWeatherCode(int code) {
    if (code == 0) return {'label': 'Clear Sky', 'icon': 'sunny'};
    if (code <= 2) return {'label': 'Partly Cloudy', 'icon': 'partly_cloudy'};
    if (code == 3) return {'label': 'Overcast', 'icon': 'cloudy'};
    if (code == 45 || code == 48) return {'label': 'Foggy', 'icon': 'fog'};
    if (code >= 51 && code <= 57) return {'label': 'Drizzle', 'icon': 'drizzle'};
    if (code >= 61 && code <= 67) return {'label': 'Rainy', 'icon': 'rain'};
    if (code >= 71 && code <= 77) return {'label': 'Snowy', 'icon': 'snow'};
    if (code >= 80 && code <= 82) return {'label': 'Rain Showers', 'icon': 'rain'};
    if (code >= 95) return {'label': 'Thunderstorm', 'icon': 'storm'};
    return {'label': 'Weather', 'icon': 'cloudy'};
  }
}