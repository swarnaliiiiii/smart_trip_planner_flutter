import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvManager {
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? 'AIzaSyDummy-Replace-With-Your-Real-API-Key';
  static const String model = 'gemini-1.5-flash';
  static String get searchApiKey => dotenv.env['SEARCH_API_KEY'] ?? 'your-search-api-key';
}