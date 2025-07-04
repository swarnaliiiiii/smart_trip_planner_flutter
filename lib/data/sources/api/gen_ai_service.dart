import 'dart:developer';

import 'package:google_generative_ai/google_generative_ai.dart';


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
}