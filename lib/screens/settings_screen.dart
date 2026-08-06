import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/country_service.dart';
import '../services/app_settings_service.dart';
import '../services/language_service.dart';
import '../services/city_service.dart';
import 'history_screen.dart';
import '../services/notification_service.dart';
import '../services/app_settings_service.dart'; 

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String locationStatus = '';

  Future<void> detectLocation() async {
    setState(() => locationStatus = 'Detecting...');

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => locationStatus = 'Location services are off.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => locationStatus = 'Permission denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => locationStatus = 'Permission permanently denied.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        locationStatus =
            'Location: ${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
      });
    } catch (e) {
      setState(() => locationStatus = 'Could not get location.');
    }
  }

  void showCountryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: CountryService.countries.length,
          itemBuilder: (context, index) {
            final country = CountryService.countries[index];
            return ListTile(
              title: Text(country['name']!),
              trailing: CountryService.selectedCountry == country['code']
                  ? const Icon(Icons.check, color: Colors.deepOrange)
                  : null,
              onTap: () {
                setState(() {
                  CountryService.setCountry(country['code']!, country['name']!);
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: LanguageService.languages.length,
          itemBuilder: (context, index) {
            final lang = LanguageService.languages[index];
            return ListTile(
              title: Text(lang['name']!),
              trailing: LanguageService.selectedLanguage == lang['code']
                  ? const Icon(Icons.check, color: Colors.deepOrange)
                  : null,
              onTap: () {
                setState(() {
                  LanguageService.setLanguage(lang['code']!, lang['name']!);
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Future<void> showCityInput() async {
    final controller = TextEditingController(text: CityService.selectedCity);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My City'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Hyderabad, Vijayawada',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        CityService.setCity(result);
      });
    }
  }

  void setFontScale(double scale) {
    setState(() {
      AppSettingsService.fontScale = scale;
    });
    widget.onSettingsChanged();
  }

  void toggleDataSaver(bool value) {
    setState(() {
      AppSettingsService.dataSaverMode = value;
    });
    widget.onSettingsChanged();
  }

  void shareApp() {
    Share.share(
      'Check out Newsly — fast, clean, and smart news updates! 📰📲',
    );
  }

  Future<void> sendFeedback() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'chanduchiriki4@gmail.com',
      query: 'subject=Newsly App Feedback',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app.')),
        );
      }
    }
  }

  Widget sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.deepOrange,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          sectionHeader('APPEARANCE'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode),
            value: widget.isDarkMode,
            onChanged: (value) => widget.onToggleTheme(),
          ),
          SwitchListTile(
            title: const Text('Daily Digest Notification'),
            subtitle: const Text('Get a reminder every morning at 8 AM'),
            secondary: const Icon(Icons.notifications_active_outlined),
            value: AppSettingsService.dailyDigestEnabled,
            onChanged: (value) async {
              setState(() {
                AppSettingsService.dailyDigestEnabled = value;
              });
              if (value) {
                await NotificationService.scheduleDailyDigest();
              } else {
                await NotificationService.cancelDailyDigest();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Font Size'),
            subtitle: Text(AppSettingsService.fontSizeLabel),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('A', style: TextStyle(fontSize: 14, color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: AppSettingsService.fontScale,
                    min: 0.85,
                    max: 1.3,
                    divisions: 3,
                    activeColor: Colors.deepOrange,
                    onChanged: setFontScale,
                  ),
                ),
                const Text('A', style: TextStyle(fontSize: 22, color: Colors.grey)),
              ],
            ),
          ),

          sectionHeader('CONTENT & DATA'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Country'),
            subtitle: Text(CountryService.selectedCountryName),
            trailing: const Icon(Icons.chevron_right),
            onTap: showCountryPicker,
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: const Text('News Language'),
            subtitle: Text(LanguageService.selectedLanguageName),
            trailing: const Icon(Icons.chevron_right),
            onTap: showLanguagePicker,
          ),
          ListTile(
            leading: const Icon(Icons.my_location),
            title: const Text('Detect My Location'),
            subtitle: locationStatus.isEmpty
                ? const Text('Tap to detect')
                : Text(locationStatus),
            onTap: detectLocation,
          ),
          ListTile(
            leading: const Icon(Icons.location_city),
            title: const Text('My City'),
            subtitle: Text(
              CityService.hasCity ? CityService.selectedCity : 'Not set — tap to add',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: showCityInput,
          ),
          SwitchListTile(
            title: const Text('Data Saver Mode'),
            subtitle: const Text('Hide images to save mobile data'),
            secondary: const Icon(Icons.data_saver_off),
            value: AppSettingsService.dataSaverMode,
            onChanged: toggleDataSaver,
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Reading History'),
            subtitle: const Text('See articles you\'ve read'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),

          sectionHeader('SUPPORT & ABOUT'),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share Newsly'),
            subtitle: const Text('Tell a friend about the app'),
            onTap: shareApp,
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Send Feedback'),
            subtitle: const Text('Help us improve Newsly'),
            onTap: sendFeedback,
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About Newsly'),
            subtitle: Text('Version 1.0.0 • Built by Chandu'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}