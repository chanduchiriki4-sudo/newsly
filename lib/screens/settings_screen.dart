import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/country_service.dart';
import '../services/app_settings_service.dart';
import '../services/language_service.dart';
import '../services/city_service.dart';
import '../services/notification_service.dart';
import 'history_screen.dart';

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: CountryService.countries.length,
          itemBuilder: (context, index) {
            final country = CountryService.countries[index];
            return ListTile(
              title: Text(country['name']!),
              trailing: CountryService.selectedCountry == country['code']
                  ? const Icon(Icons.check_circle_rounded, color: Colors.deepOrange)
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: LanguageService.languages.length,
          itemBuilder: (context, index) {
            final lang = LanguageService.languages[index];
            return ListTile(
              title: Text(lang['name']!),
              trailing: LanguageService.selectedLanguage == lang['code']
                  ? const Icon(Icons.check_circle_rounded, color: Colors.deepOrange)
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      padding: const EdgeInsets.fromLTRB(20, 22, 16, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: Colors.deepOrange,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Small colored circular icon badge used consistently across all rows.
  Widget iconBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }

  // Wraps a group of settings rows in a card with soft shadow, consistent
  // with the rest of the app's card styling.
  Widget sectionCard(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings_rounded, color: Colors.deepOrange, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          sectionHeader('APPEARANCE'),
          sectionCard(context, [
            SwitchListTile(
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
              secondary: iconBadge(Icons.dark_mode_rounded, Colors.indigo),
              activeColor: Colors.deepOrange,
              value: widget.isDarkMode,
              onChanged: (value) => widget.onToggleTheme(),
            ),
            const Divider(height: 1, indent: 68),
            SwitchListTile(
              title: const Text('Daily Digest Notification', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Reminder every morning at 8 AM'),
              secondary: iconBadge(Icons.notifications_active_rounded, Colors.amber[800]!),
              activeColor: Colors.deepOrange,
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
            const Divider(height: 1, indent: 68),
            ListTile(
              leading: iconBadge(Icons.text_fields_rounded, Colors.teal),
              title: const Text('Font Size', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(AppSettingsService.fontSizeLabel),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  const Text('A', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: AppSettingsService.fontScale,
                        min: 0.85,
                        max: 1.3,
                        divisions: 3,
                        activeColor: Colors.deepOrange,
                        inactiveColor: Colors.deepOrange.withValues(alpha: 0.15),
                        onChanged: setFontScale,
                      ),
                    ),
                  ),
                  const Text('A', style: TextStyle(fontSize: 20, color: Colors.grey)),
                ],
              ),
            ),
          ]),

          sectionHeader('CONTENT & DATA'),
          sectionCard(context, [
            ListTile(
              leading: iconBadge(Icons.public_rounded, Colors.blue),
              title: const Text('Country', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(CountryService.selectedCountryName),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: showCountryPicker,
            ),
            const Divider(height: 1, indent: 68),
            ListTile(
              leading: iconBadge(Icons.translate_rounded, Colors.purple),
              title: const Text('News Language', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(LanguageService.selectedLanguageName),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: showLanguagePicker,
            ),
            const Divider(height: 1, indent: 68),
            ListTile(
              leading: iconBadge(Icons.my_location_rounded, Colors.green),
              title: const Text('Detect My Location', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: locationStatus.isEmpty
                  ? const Text('Tap to detect')
                  : Text(locationStatus),
              onTap: detectLocation,
            ),
            const Divider(height: 1, indent: 68),
            ListTile(
              leading: iconBadge(Icons.location_city_rounded, Colors.deepOrange),
              title: const Text('My City', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                CityService.hasCity ? CityService.selectedCity : 'Not set — tap to add',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: showCityInput,
            ),
            const Divider(height: 1, indent: 68),
            SwitchListTile(
              title: const Text('Data Saver Mode', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Hide images to save mobile data'),
              secondary: iconBadge(Icons.data_saver_off_rounded, Colors.brown),
              activeColor: Colors.deepOrange,
              value: AppSettingsService.dataSaverMode,
              onChanged: toggleDataSaver,
            ),
            const Divider(height: 1, indent: 68),
            ListTile(
              leading: iconBadge(Icons.history_rounded, Colors.blueGrey),
              title: const Text('Reading History', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('See articles you\'ve read'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              },
            ),
          ]),

          sectionHeader('SUPPORT & ABOUT'),
          sectionCard(context, [
            ListTile(
              leading: iconBadge(Icons.share_rounded, Colors.pink),
              title: const Text('Share Newsly', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Tell a friend about the app'),
              onTap: shareApp,
            ),
            const Divider(height: 1, indent: 68),
            ListTile(
              leading: iconBadge(Icons.feedback_rounded, Colors.orange),
              title: const Text('Send Feedback', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Help us improve Newsly'),
              onTap: sendFeedback,
            ),
            const Divider(height: 1, indent: 68),
            ListTile(
              leading: iconBadge(Icons.info_rounded, Colors.grey),
              title: const Text('About Newsly', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Version 1.0.0 • Built by Chandu'),
            ),
          ]),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}