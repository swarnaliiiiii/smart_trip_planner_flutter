import 'dart:developer';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:talk_trip/core/constants/env_manager.dart';
import 'package:talk_trip/core/utils/metrics_manager.dart';
import 'package:talk_trip/data/sources/api/search_service.dart';

class EnhancedGenerativeAIService {
  final _model = GenerativeModel(
    model: EnvManager.model,
    apiKey: EnvManager.apiKey,
  );
  final _searchService = SearchService();
  final _metricsManager = MetricsManager();

  Future<String?> generateItineraryWithSearch(String userPrompt) async {
    try {
      // Step 1: Extract search keywords from user prompt
      final searchKeywords = _extractSearchKeywords(userPrompt);
      
      // Step 2: Perform searches for real-time information
      Map<String, List<Map<String, dynamic>>> searchResults = {};
      
      for (String keyword in searchKeywords) {
        log('Searching for: $keyword');
        final results = await _searchService.searchPlaces(keyword);
        if (results.isNotEmpty) {
          searchResults[keyword] = results.take(3).toList(); // Limit to top 3 results
        }
      }

      // Step 3: Create enhanced prompt with search results
      final enhancedPrompt = _buildEnhancedPrompt(userPrompt, searchResults);
      
      // Step 4: Generate itinerary with real-time data
      final inputTokens = MetricsManager.estimateTokens(enhancedPrompt);
      
      final content = [Content.text(enhancedPrompt)];
      final response = await _model.generateContent(content);
      
      final outputTokens = MetricsManager.estimateTokens(response.text ?? '');
      
      // Record metrics
      _metricsManager.recordTokenUsage(
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        requestType: 'Enhanced Itinerary Generation',
      );
      
      return response.text?.trim();
    } catch (e) {
      log('Error in enhanced itinerary generation: $e');
      
      // Fallback to basic generation
      return await _generateBasicItinerary(userPrompt);
    }
  }

  Future<String?> _generateBasicItinerary(String userPrompt) async {
    try {
      final inputTokens = MetricsManager.estimateTokens(userPrompt);
      
      final content = [Content.text(_buildBasicPrompt(userPrompt))];
      final response = await _model.generateContent(content);
      
      final outputTokens = MetricsManager.estimateTokens(response.text ?? '');
      
      _metricsManager.recordTokenUsage(
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        requestType: 'Basic Itinerary Generation',
      );
      
      return response.text?.trim();
    } catch (e) {
      log('Error in basic itinerary generation: $e');
      return null;
    }
  }

  List<String> _extractSearchKeywords(String userPrompt) {
    final keywords = <String>[];
    final prompt = userPrompt.toLowerCase();
    
    // Extract destination
    final destinationPatterns = [
      RegExp(r'(?:to|in|visit|traveling to|going to)\s+([a-zA-Z\s]+?)(?:\s|,|\.|\?|!|$)'),
      RegExp(r'([a-zA-Z\s]+?)(?:\s+trip|\s+vacation|\s+travel)'),
    ];
    
    for (final pattern in destinationPatterns) {
      final match = pattern.firstMatch(prompt);
      if (match != null) {
        final destination = match.group(1)?.trim();
        if (destination != null && destination.length > 2) {
          keywords.add('$destination attractions');
          keywords.add('$destination restaurants');
          keywords.add('$destination hotels');
          break;
        }
      }
    }
    
    // Add activity-specific searches
    if (prompt.contains('food') || prompt.contains('restaurant') || prompt.contains('dining')) {
      keywords.add('best restaurants ${_extractDestination(prompt)}');
    }
    
    if (prompt.contains('hotel') || prompt.contains('accommodation') || prompt.contains('stay')) {
      keywords.add('best hotels ${_extractDestination(prompt)}');
    }
    
    if (prompt.contains('museum') || prompt.contains('culture') || prompt.contains('history')) {
      keywords.add('museums ${_extractDestination(prompt)}');
    }
    
    return keywords.take(5).toList(); // Limit to 5 searches to avoid rate limits
  }

  String _extractDestination(String prompt) {
    final destinationPatterns = [
      RegExp(r'(?:to|in|visit|traveling to|going to)\s+([a-zA-Z\s]+?)(?:\s|,|\.|\?|!|$)'),
    ];
    
    for (final pattern in destinationPatterns) {
      final match = pattern.firstMatch(prompt.toLowerCase());
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }
    return '';
  }

  String _buildEnhancedPrompt(String userPrompt, Map<String, List<Map<String, dynamic>>> searchResults) {
    final buffer = StringBuffer();
    
    buffer.writeln('You are a travel planning expert. Based on the user\'s request and real-time search data, create a detailed travel itinerary.');
    buffer.writeln('\nUser Request: $userPrompt');
    
    if (searchResults.isNotEmpty) {
      buffer.writeln('\nReal-time Search Results:');
      searchResults.forEach((keyword, results) {
        buffer.writeln('\n$keyword:');
        for (final result in results) {
          buffer.writeln('- ${result['title']}: ${result['snippet']}');
          if (result['rating'] != null && result['rating'] > 0) {
            buffer.writeln('  Rating: ${result['rating']}/5');
          }
        }
      });
      buffer.writeln('\nPlease incorporate this real-time information into your itinerary recommendations.');
    }
    
    buffer.writeln(_getItineraryFormatInstructions());
    
    return buffer.toString();
  }

  String _buildBasicPrompt(String userPrompt) {
    return '''
You are a travel planning expert. Based on the user's request, create a detailed travel itinerary.

User Request: $userPrompt

${_getItineraryFormatInstructions()}
''';
  }

  String _getItineraryFormatInstructions() {
    return '''
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
  }

  Future<String?> postData(List<Content> contents) async {
    try {
      final inputText = contents.map((c) => c.parts.map((p) => p.text).join(' ')).join(' ');
      final inputTokens = MetricsManager.estimateTokens(inputText);
      
      final response = await _model.generateContent(contents);
      
      final outputTokens = MetricsManager.estimateTokens(response.text ?? '');
      
      _metricsManager.recordTokenUsage(
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        requestType: 'Chat Response',
      );
      
      return response.text?.trim();
    } catch (e) {
      log('Error in postData: $e');
      throw Exception('Error in postData: $e');
    }
  }

  Stream<String?> streamData(List<Content> contents) async* {
    try {
      final inputText = contents.map((c) => c.parts.map((p) => p.text).join(' ')).join(' ');
      final inputTokens = MetricsManager.estimateTokens(inputText);
      
      final response = _model.generateContentStream(contents);
      final buffer = StringBuffer();
      
      await for (final chunk in response) {
        if (chunk.text != null) {
          buffer.write(chunk.text);
          yield chunk.text;
        }
      }
      
      final outputTokens = MetricsManager.estimateTokens(buffer.toString());
      
      _metricsManager.recordTokenUsage(
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        requestType: 'Streaming Response',
      );
      
    } catch (e) {
      log('Error in streamData: $e');
      throw Exception('Error in streamData: $e');
    }
  }
}