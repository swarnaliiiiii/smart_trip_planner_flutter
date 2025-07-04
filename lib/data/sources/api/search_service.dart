import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:talk_trip/core/constants/env_manager.dart';

class SearchService {
  static const String _baseUrl = 'https://api.serpapi.com/search';

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?engine=google&q=$query&api_key=${EnvManager.searchApiKey}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['organic_results'] as List? ?? [];
        
        return results.map((result) => {
          'title': result['title'] ?? '',
          'link': result['link'] ?? '',
          'snippet': result['snippet'] ?? '',
          'rating': _extractRating(result['snippet'] ?? ''),
        }).toList();
      }
    } catch (e) {
      log('Search error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeName, String location) async {
    try {
      final query = '$placeName $location';
      final response = await http.get(
        Uri.parse('$_baseUrl?engine=google_maps&q=$query&api_key=${EnvManager.searchApiKey}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final place = data['place_results'];
        
        if (place != null) {
          return {
            'name': place['title'] ?? placeName,
            'rating': place['rating']?.toDouble() ?? 0.0,
            'address': place['address'] ?? '',
            'phone': place['phone'] ?? '',
            'website': place['website'] ?? '',
            'mapLink': 'https://maps.google.com/?q=${Uri.encodeComponent(query)}',
            'imageUrl': place['thumbnail'] ?? '',
          };
        }
      }
    } catch (e) {
      log('Place details error: $e');
    }
    return null;
  }

  double _extractRating(String text) {
    final ratingRegex = RegExp(r'(\d+\.?\d*)\s*(?:stars?|★|rating)');
    final match = ratingRegex.firstMatch(text.toLowerCase());
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }
    return 0.0;
  }
}