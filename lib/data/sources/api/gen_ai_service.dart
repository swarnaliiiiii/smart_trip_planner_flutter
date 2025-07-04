import 'dart:developer';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:talk_trip/core/constants/env_manager.dart';

class GenerativeAIWebService {
  final _model = GenerativeModel(
    model: EnvManager.model,
    apiKey: EnvManager.apiKey,
  );

  Future<String?> postData(List<Content> contents) async {
    try {
      final response = await _model.generateContent(contents);
      return response.text?.trim();
    } on Exception catch (err) {
      log('Error in postData: ${err.toString()}');
      throw Exception('Error in postData: ${err.toString()}');
    }
  }

  Stream<String?> streamData(List<Content> contents) async* {
    try {
      final response = _model.generateContentStream(contents);
      await for (final chunk in response) {
        if (chunk.text != null) yield chunk.text;
      }
    } on GenerativeAIException catch (err) {
      log('API Error: ${err.message}');
      throw Exception('Error in streamData: ${err.toString()}');
    } on Exception catch (err) {
      log('General Error: ${err.toString()}');
      throw Exception('Error in streamData: ${err.toString()}');
    }
  }

  Future<String?> generateItinerary(String userPrompt) async {
    final prompt = '''
You are a travel planning expert. Based on the user's request, create a detailed travel itinerary in JSON format.

User Request: $userPrompt

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

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text?.trim();
    } catch (e) {
      log('Error generating itinerary: $e');
      return null;
    }
  }
}