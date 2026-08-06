class LanguageService {
  static String selectedLanguage = 'en';
  static String selectedLanguageName = 'English';

  static final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'Hindi (हिन्दी)'},
    {'code': 'te', 'name': 'Telugu (తెలుగు)'},
    {'code': 'ta', 'name': 'Tamil (தமிழ்)'},
    {'code': 'ml', 'name': 'Malayalam (മലയാളം)'},
    {'code': 'kn', 'name': 'Kannada (ಕನ್ನಡ)'},
    {'code': 'mr', 'name': 'Marathi (मराठी)'},
    {'code': 'bn', 'name': 'Bengali (বাংলা)'},
  ];

  static void setLanguage(String code, String name) {
    selectedLanguage = code;
    selectedLanguageName = name;
  }
}