import 'dart:math';

class QuoteService {
  static final List<Map<String, String>> quotes = [
    {
      'quote': 'The only way to do great work is to love what you do.',
      'author': 'Steve Jobs',
    },
    {
      'quote': 'Success is not final, failure is not fatal: it is the courage to continue that counts.',
      'author': 'Winston Churchill',
    },
    {
      'quote': 'Believe you can and you\'re halfway there.',
      'author': 'Theodore Roosevelt',
    },
    {
      'quote': 'The future belongs to those who believe in the beauty of their dreams.',
      'author': 'Eleanor Roosevelt',
    },
    {
      'quote': 'It does not matter how slowly you go as long as you do not stop.',
      'author': 'Confucius',
    },
    {
      'quote': 'Knowledge is power. Information is liberating.',
      'author': 'Kofi Annan',
    },
    {
      'quote': 'The best way to predict the future is to create it.',
      'author': 'Abraham Lincoln',
    },
    {
      'quote': 'Stay hungry, stay foolish.',
      'author': 'Steve Jobs',
    },
  ];

  static Map<String, String> getTodaysQuote() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return quotes[dayOfYear % quotes.length];
  }

  static Map<String, String> getRandomQuote() {
    final random = Random();
    return quotes[random.nextInt(quotes.length)];
  }
}