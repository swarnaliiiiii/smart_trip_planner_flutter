import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:talk_trip/data/models/itinerary.dart';
import 'package:talk_trip/data/sources/api/gen_ai_service.dart';
import 'dart:convert';

part 'itinerary_event.dart';
part 'itinerary_state.dart';

class ItineraryBloc extends Bloc<ItineraryEvent, ItineraryState> {
  final Isar isar;
  final GenerativeAIWebService _aiService;

  ItineraryBloc(this.isar)
      : _aiService = GenerativeAIWebService(),
        super(ItineraryInitial()) {
    on<CreateItinerary>(_onCreateItinerary);
    on<RegenerateItinerary>(_onRegenerateItinerary);
    on<SaveItinerary>(_onSaveItinerary);
    on<FollowUpItinerary>(_onFollowUpItinerary);
    on<CopyItinerary>(_onCopyItinerary);
  }

  Future<void> _onCreateItinerary(
      CreateItinerary event, Emitter<ItineraryState> emit) async {
    emit(ItineraryLoading());
    try {
      // Call AI API to generate itinerary from event.prompt
      final response = await _aiService.generateItinerary(event.prompt);

      if (response != null) {
        try {
          // Parse the JSON response
          Map<String, dynamic> parsedJson;

          try {
            parsedJson = jsonDecode(response);
          } catch (e) {
            // Try to extract JSON if it's wrapped in text
            final jsonStart = response.indexOf('{');
            final jsonEnd = response.lastIndexOf('}') + 1;

            if (jsonStart != -1 && jsonEnd > jsonStart) {
              final jsonString = response.substring(jsonStart, jsonEnd);
              parsedJson = jsonDecode(jsonString);
            } else {
              throw Exception('Invalid JSON response');
            }
          }

          // Create itinerary from parsed JSON
          final itinerary = Itinerary()
            ..title = parsedJson['title'] ?? 'Generated Trip'
            ..destination = parsedJson['destination'] ?? 'Unknown Destination'
            ..duration = parsedJson['duration'] ?? 1
            ..description = parsedJson['description'] ?? ''
            ..jsonData = response; // Store the full JSON response

          await isar.writeTxn(() async => await isar.itinerarys.put(itinerary));
          emit(ItineraryLoaded(itinerary));
        } catch (e) {
          // If JSON parsing fails, create a basic itinerary with the raw response
          final itinerary = Itinerary()
            ..title = 'Generated Trip'
            ..destination = 'Unknown Destination'
            ..duration = 1
            ..description = 'AI generated itinerary'
            ..jsonData = response;

          await isar.writeTxn(() async => await isar.itinerarys.put(itinerary));
          emit(ItineraryLoaded(itinerary));
        }
      } else {
        emit(ItineraryError('Failed to generate itinerary from AI service'));
      }
    } catch (e) {
      emit(ItineraryError('Failed to create itinerary: ${e.toString()}'));
    }
  }

  Future<void> _onRegenerateItinerary(
      RegenerateItinerary event, Emitter<ItineraryState> emit) async {
    emit(ItineraryLoading());
    try {
      // Call AI API to regenerate itinerary
      final response = await _aiService.generateItinerary(
          'Regenerate this itinerary: ${event.itinerary.description}');

      if (response != null) {
        try {
          Map<String, dynamic> parsedJson = jsonDecode(response);

          event.itinerary.title = parsedJson['title'] ?? event.itinerary.title;
          event.itinerary.destination =
              parsedJson['destination'] ?? event.itinerary.destination;
          event.itinerary.duration =
              parsedJson['duration'] ?? event.itinerary.duration;
          event.itinerary.description =
              parsedJson['description'] ?? event.itinerary.description;
          event.itinerary.jsonData = response;

          await isar
              .writeTxn(() async => await isar.itinerarys.put(event.itinerary));
          emit(ItineraryLoaded(event.itinerary));
        } catch (e) {
          event.itinerary.jsonData = response;
          await isar
              .writeTxn(() async => await isar.itinerarys.put(event.itinerary));
          emit(ItineraryLoaded(event.itinerary));
        }
      } else {
        emit(ItineraryError('Failed to regenerate itinerary'));
      }
    } catch (e) {
      emit(ItineraryError('Failed to regenerate itinerary: ${e.toString()}'));
    }
  }

  Future<void> _onSaveItinerary(
      SaveItinerary event, Emitter<ItineraryState> emit) async {
    try {
      await isar
          .writeTxn(() async => await isar.itinerarys.put(event.itinerary));
      emit(ItineraryLoaded(event.itinerary));
    } catch (e) {
      emit(ItineraryError('Failed to save itinerary'));
    }
  }

  Future<void> _onFollowUpItinerary(
      FollowUpItinerary event, Emitter<ItineraryState> emit) async {
    emit(ItineraryLoading());
    try {
      // TODO: Call AI API to modify itinerary based on follow-up
      emit(ItineraryLoaded(event.itinerary));
    } catch (e) {
      emit(ItineraryError('Failed to follow up itinerary'));
    }
  }

  Future<void> _onCopyItinerary(
      CopyItinerary event, Emitter<ItineraryState> emit) async {
    // No state change needed, handled in UI
  }
}
