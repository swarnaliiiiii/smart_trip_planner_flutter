import 'dart:developer';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:talk_trip/core/constants/env_manager.dart';
import 'package:talk_trip/core/utils/metrics_manager.dart';
import 'package:talk_trip/data/sources/api/search_service.dart';

class GenerativeAIWebService {
  final _model = GenerativeModel(
    model: EnvManager.model,
    apiKey: EnvManager.apiKey,
  );
  final _metricsManager = MetricsManager();
  final _searchService = SearchService();

  Future<String?> postData(List<Content> contents) async {
    try {
      final inputTokens = _calculateInputTokens(contents);

      final response = await _model.generateContent(contents);
      final outputTokens = _estimateOutputTokens(response.text ?? '');

      _metricsManager.recordTokenUsage(
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        requestType: 'postData',
      );

      return response.text?.trim();
    } on Exception catch (err) {
      log('Error in postData: ${err.toString()}');
      throw Exception('Error in postData: ${err.toString()}');
    }
  }

  Stream<String?> streamData(List<Content> contents) async* {
    try {
      final inputTokens = _calculateInputTokens(contents);
      final response = _model.generateContentStream(contents);

      StringBuffer fullResponse = StringBuffer();
      await for (final chunk in response) {
        if (chunk.text != null) {
          fullResponse.write(chunk.text);
          yield chunk.text;
        }
      }

      final outputTokens = _estimateOutputTokens(fullResponse.toString());
      _metricsManager.recordTokenUsage(
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        requestType: 'streamData',
      );
    } on GenerativeAIException catch (err) {
      log('API Error: ${err.message}');
      throw Exception('Error in streamData: ${err.toString()}');
    } on Exception catch (err) {
      log('General Error: ${err.toString()}');
      throw Exception('Error in streamData: ${err.toString()}');
    }
  }

  Future<String?> generateItinerary(String userPrompt) async {
    try {
      final inputTokens = MetricsManager.estimateTokens(userPrompt);

      // Extract destination and search for real-time information
      String searchContext = '';
      try {
        final destination = _extractDestination(userPrompt);
        if (destination.isNotEmpty) {
          log('Searching for information about: $destination');
          final searchResults = await _searchService
              .searchPlaces('best attractions $destination');
          if (searchResults.isNotEmpty) {
            searchContext = '\n\nReal-time information about $destination:\n';
            for (int i = 0; i < searchResults.length && i < 3; i++) {
              final result = searchResults[i];
              searchContext += '- ${result['title']}: ${result['snippet']}\n';
            }
          }
        }
      } catch (e) {
        log('Search error: $e');
        // Continue without search results
      }

      final prompt = '''
You are a travel planning expert. Based on the user's request, create a detailed travel itinerary in JSON format.

User Request: $userPrompt$searchContext

Please respond with a JSON object that includes:
1. Basic trip information (title, destination, dates, duration, budget, travel style)
2. Day-by-day breakdown with activities and restaurant recommendations
3. Include map links for each location
4. Provide realistic cost estimates
5. Include ratings and descriptions

Format the response as valid JSON with this structure:
{
  "title": "Trip Title",
  "destination": "City, Country",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD", 
  "duration": number_of_days,
  "budget": "budget_range",
  "travelStyle": "solo/couple/family/group",
  "description": "Brief trip overview",
  "days": [
    {
      "dayNumber": 1,
      "date": "YYYY-MM-DD",
      "title": "Day 1 Title",
      "description": "Day overview",
      "activities": [
        {
          "name": "Activity Name",
          "type": "sightseeing/cultural/adventure/relaxation",
          "description": "Activity description",
          "location": "Specific address or area",
          "mapLink": "https://maps.google.com/?q=location",
          "timeSlot": "Morning/Afternoon/Evening",
          "estimatedCost": cost_in_usd,
          "rating": rating_out_of_5,
          "isRecommended": true/false
        }
      ],
      "restaurants": [
        {
          "name": "Restaurant Name",
          "cuisine": "Cuisine type",
          "description": "Restaurant description",
          "location": "Address",
          "mapLink": "https://maps.google.com/?q=restaurant",
          "priceRange": "\$/\$\$/\$\$\$/\$\$\$\$",
          "rating": rating_out_of_5,
          "isRecommended": true/false
        }
      ]
    }
  ]
}

Make sure to provide realistic and helpful recommendations based on the destination and user preferences.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final outputTokens = _estimateOutputTokens(response.text ?? '');

      _metricsManager.recordTokenUsage(
        inputTokens: inputTokens + MetricsManager.estimateTokens(prompt),
        outputTokens: outputTokens,
        requestType: 'generateItinerary',
      );

      return response.text?.trim();
    } catch (e) {
      log('Error generating itinerary: $e');
      return null;
    }
  }

  String _extractDestination(String prompt) {
    // Simple destination extraction - look for common patterns
    final patterns = [
      RegExp(r'in\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)', caseSensitive: false),
      RegExp(r'to\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)', caseSensitive: false),
      RegExp(r'visit\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(prompt);
      if (match != null) {
        return match.group(1) ?? '';
      }
    }

    return '';
  }

  int _calculateInputTokens(List<Content> contents) {
    int totalTokens = 0;
    for (final content in contents) {
      if (content.parts.isNotEmpty && content.parts.first is TextPart) {
        totalTokens += MetricsManager.estimateTokens(
            (content.parts.first as TextPart).text);
      }
    }
    return totalTokens;
  }

  int _estimateOutputTokens(String text) {
    return MetricsManager.estimateTokens(text);
  }
}
