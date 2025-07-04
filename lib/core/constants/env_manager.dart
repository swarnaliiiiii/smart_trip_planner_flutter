class EnvManager {
  static const String apiKey = String.fromEnvironment(
    'GEMINI_API_KEY', 
    defaultValue: 'AIzaSyDummy-Replace-With-Your-Real-API-Key'
  );
  static const String model = 'gemini-1.5-flash';
  static const String searchApiKey = String.fromEnvironment(
    'SEARCH_API_KEY', 
    defaultValue: 'your-search-api-key'
  );
}