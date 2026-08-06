class CountryService {
  static String selectedCountry = 'in';
  static String selectedCountryName = 'India';

  static final List<Map<String, String>> countries = [
    {'name': 'India', 'code': 'in'},
    {'name': 'United States', 'code': 'us'},
    {'name': 'United Kingdom', 'code': 'gb'},
    {'name': 'Australia', 'code': 'au'},
    {'name': 'Canada', 'code': 'ca'},
    {'name': 'Japan', 'code': 'jp'},
    {'name': 'Germany', 'code': 'de'},
    {'name': 'France', 'code': 'fr'},
    {'name': 'Brazil', 'code': 'br'},
    {'name': 'Singapore', 'code': 'sg'},
  ];

  static void setCountry(String code, String name) {
    selectedCountry = code;
    selectedCountryName = name;
  }
}