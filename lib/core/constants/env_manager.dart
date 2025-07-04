class EnvManager {
  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'your-api-key-here');
  static const String model = 'gemini-1.5-flash';
  static const String searchApiKey = String.fromEnvironment('SEARCH_API_KEY', defaultValue: 'your-search-api-key');
}