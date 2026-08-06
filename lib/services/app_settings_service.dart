class AppSettingsService {
  static double fontScale = 1.0;
  static bool dataSaverMode = false;
  static bool dailyDigestEnabled = false; // కొత్త line

  static String get fontSizeLabel {
    if (fontScale <= 0.9) return 'Small';
    if (fontScale <= 1.0) return 'Medium';
    if (fontScale <= 1.2) return 'Large';
    return 'Extra Large';
  }
}