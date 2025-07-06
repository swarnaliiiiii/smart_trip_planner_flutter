import 'dart:async';
import 'dart:developer';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:meta/meta.dart';
import 'package:talk_trip/data/sources/api/gen_ai_service.dart';
import 'package:talk_trip/data/repo/message_repo.dart';
import 'package:talk_trip/data/models/message.dart';
import 'package:talk_trip/data/models/chat_session.dart';
import 'package:talk_trip/data/models/itinerary.dart';
import 'package:talk_trip/core/utils/network_manager.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GenerativeAIWebService _webService;
  final MessageRepository _messageRepository;
  int _currentChatId = 1;

  ChatBloc(this._webService, this._messageRepository) : super(ChatInitial()) {
    on<PostDataEvent>(_onPostData);
    on<StreamDataEvent>(_onStreamData);
    on<CreateNewChatSessionEvent>(_onCreateNewChatSession);
    on<DeleteChatSessionEvent>(_onDeleteChatSession);
    on<LoadChatSessionEvent>(_onLoadChatSession);
    on<GenerateItineraryEvent>(_onGenerateItinerary);
    
    _initializeDefaultSession();
  }

  Future<void> _initializeDefaultSession() async {
    final sessions = await _messageRepository.getChatSessions();
    if (sessions.isNotEmpty) {
      _currentChatId = sessions.first.chatId;
    }
  }

  Future<void> _onLoadChatSession(
      LoadChatSessionEvent event, Emitter<ChatState> emit) async {
    _currentChatId = event.chatId;
    final messages = await _messageRepository.getMessages(event.chatId);
    emit(ChatSessionLoaded(event.chatId, messages));
  }

  Future<void> _onCreateNewChatSession(
      CreateNewChatSessionEvent event, Emitter<ChatState> emit) async {
    try {
      final messages = await _messageRepository.getMessages(_currentChatId);
      if (messages.isNotEmpty) {
        final newChatId = await _messageRepository.createNewChatSession();
        _currentChatId = newChatId;
        emit(NewChatSessionCreated(newChatId));
      } else {
        emit(ChatFailure("Already in new chat!"));
      }
    } catch (error) {
      emit(ChatFailure("Failed to create new chat session: ${error.toString()}"));
    }
  }

  int get currentChatId => _currentChatId;

  Future<List<Message>> getMessages(int chatId) async {
    return await _messageRepository.getMessages(chatId);
  }

  Future<List<ChatSession>> getChatSessions() async {
    return await _messageRepository.getChatSessions();
  }

  Future<List<Itinerary>> getAllItineraries() async {
    return await _messageRepository.getAllItineraries();
  }

  Future<void> saveItinerary(int chatId, Itinerary itinerary) async {
    await _messageRepository.saveItinerary(chatId, itinerary);
  }

  // ADDED: Method to get itinerary for a specific chat
  Future<Itinerary?> getItinerary(int chatId) async {
    return await _messageRepository.getItinerary(chatId);
  }

  Future<void> _onDeleteChatSession(
      DeleteChatSessionEvent event, Emitter<ChatState> emit) async {
    try {
      await _messageRepository.deleteChatSession(event.chatId);
      emit(ChatSessionDeleted(event.chatId));
    } catch (error) {
      emit(ChatFailure("Failed to delete chat session"));
    }
  }

  Future<void> _onGenerateItinerary(
    GenerateItineraryEvent event, Emitter<ChatState> emit) async {
  emit(ChatLoading());
  try {
    if (!await NetworkManager.isConnected()) {
      emit(ChatFailure("No internet connection"));
      return;
    }

    await _messageRepository.addMessage(
      chatId: event.chatId,
      isUser: true,
      message: event.prompt,
      timestamp: DateTime.now().toIso8601String(),
    );
    emit(ChatSendSuccess());

    final response = await _webService.generateItinerary(event.prompt);
    if (response != null) {
      await _messageRepository.addMessage(
        chatId: event.chatId,
        isUser: false,
        message: response,
        timestamp: DateTime.now().toIso8601String(),
      );

      try {
        log("Raw response: $response");
        
        Map<String, dynamic> parsedJson;
        
        try {
          parsedJson = jsonDecode(response);
        } catch (e) {
          
          final jsonStart = response.indexOf('{');
          final jsonEnd = response.lastIndexOf('}') + 1;
          
          if (jsonStart != -1 && jsonEnd > jsonStart) {
            final jsonString = response.substring(jsonStart, jsonEnd);
            log("Extracted JSON: $jsonString");
            parsedJson = jsonDecode(jsonString);
          } else {
            
            log("No JSON found in response");
            emit(ChatReciveSuccess(response));
            return;
          }
        }
        
        
        if (parsedJson.containsKey('title') && 
            parsedJson.containsKey('destination') && 
            parsedJson.containsKey('days')) {
          
          // FIXED: Save the itinerary to database using the new method
          try {
            await _messageRepository.saveItineraryFromJson(event.chatId, response);
            log("Itinerary saved to database successfully");
            
            // Get the saved itinerary from database to ensure it's properly loaded
            final savedItinerary = await _messageRepository.getItinerary(event.chatId);
            if (savedItinerary != null) {
              log("Retrieved saved itinerary: ${savedItinerary.title} with ${savedItinerary.days.length} days");
              emit(ItineraryReceivedSuccess(savedItinerary));
            } else {
              log("Failed to retrieve saved itinerary");
              // Fallback to creating from JSON
              final itinerary = Itinerary.fromJson(parsedJson);
              emit(ItineraryReceivedSuccess(itinerary));
            }
          } catch (saveError) {
            log("Error saving itinerary: $saveError");
            // Fallback to creating from JSON without saving
            final itinerary = Itinerary.fromJson(parsedJson);
            emit(ItineraryReceivedSuccess(itinerary));
          }
        } else {
          log("JSON doesn't contain required itinerary fields");
          emit(ChatReciveSuccess(response));
        }
        
      } catch (e) {
        log("JSON parsing error: $e");
        log("Response that failed to parse: $response");
        emit(ChatReciveSuccess(response));
      }
    } else {
      emit(ChatFailure("Failed to get a response"));
    }
  } catch (error) {
    log("GenerateItinerary error: $error");
    emit(ChatFailure("Failed to generate itinerary"));
  }
}

  Future<void> _onPostData(PostDataEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      if (!await NetworkManager.isConnected()) {
        emit(ChatFailure("No internet connection"));
        return;
      }

      await _messageRepository.addMessage(
        chatId: event.chatId,
        isUser: true,
        message: event.prompt,
        timestamp: DateTime.now().toIso8601String(),
      );
      emit(ChatSendSuccess());

      final messages = await _messageRepository.getMessages(event.chatId);
      final contents = messages.map((msg) {
        if (msg == messages.last && event.recognizedText != null) {
          return ai.Content.text(
              "${msg.message}\n\n[Recognized Text]: ${event.recognizedText}");
        } else {
          return ai.Content.text(msg.message);
        }
      }).toList();

      final response = await _webService.postData(contents);
      if (response != null) {
        await _messageRepository.addMessage(
          chatId: event.chatId,
          isUser: false,
          message: response,
          timestamp: DateTime.now().toIso8601String(),
        );
        emit(ChatReciveSuccess(response));
      } else {
        emit(ChatFailure("Failed to get a response"));
      }
    } catch (error) {
      log(error.toString());
      emit(ChatFailure("Failed to get a response"));
    }
  }

  Future<void> _onStreamData(StreamDataEvent event, Emitter<ChatState> emit) async {
  emit(ChatLoading());
  final StringBuffer fullResponse = StringBuffer();

  try {
    if (!await NetworkManager.isConnected()) {
      emit(ChatFailure("No internet connection"));
      return;
    }

    await _messageRepository.addMessage(
      chatId: event.chatId,
      isUser: true,
      message: event.prompt,
      timestamp: DateTime.now().toIso8601String(),
    );
    emit(ChatSendSuccess());

    final messages = await _messageRepository.getMessages(event.chatId);
    final contents = messages.map((msg) {
      if (msg == messages.last && event.recognizedText != null) {
        return ai.Content.text(
          "${msg.message}\n\n[Recognized Text]: ${event.recognizedText}",
        );
      } else {
        return ai.Content.text(msg.message);
      }
    }).toList();

    await for (final chunk in _webService.streamData(contents)) {
      if (chunk != null) {
        fullResponse.write(chunk);
        await Future.delayed(Duration(milliseconds: 200));
        emit(ChatStreaming(chunk));
      }
    }

    await Future.delayed(Duration(milliseconds: 500));
    final completeResponse = fullResponse.toString();

    await _messageRepository.addMessage(
      chatId: event.chatId,
      isUser: false,
      message: completeResponse,
      timestamp: DateTime.now().toIso8601String(),
    );

    // Enhanced JSON parsing for streaming
    try {
      log("Complete streaming response: $completeResponse");
      
      Map<String, dynamic> parsedJson;
      
      try {
        parsedJson = jsonDecode(completeResponse);
      } catch (e) {
        // Extract JSON from response
        final jsonStart = completeResponse.indexOf('{');
        final jsonEnd = completeResponse.lastIndexOf('}') + 1;
        
        if (jsonStart != -1 && jsonEnd > jsonStart) {
          final jsonString = completeResponse.substring(jsonStart, jsonEnd);
          parsedJson = jsonDecode(jsonString);
        } else {
          emit(ChatReciveSuccess(completeResponse));
          return;
        }
      }
      
      // Validate and create itinerary
      if (parsedJson.containsKey('title') && 
          parsedJson.containsKey('destination') && 
          parsedJson.containsKey('days')) {
        
        // FIXED: Save the itinerary to database using the new method
        try {
          await _messageRepository.saveItineraryFromJson(event.chatId, completeResponse);
          log("Streaming itinerary saved to database successfully");
          
          // Get the saved itinerary from database to ensure it's properly loaded
          final savedItinerary = await _messageRepository.getItinerary(event.chatId);
          if (savedItinerary != null) {
            log("Retrieved saved streaming itinerary: ${savedItinerary.title} with ${savedItinerary.days.length} days");
            emit(ItineraryReceivedSuccess(savedItinerary));
          } else {
            log("Failed to retrieve saved streaming itinerary");
            // Fallback to creating from JSON
            final itinerary = Itinerary.fromJson(parsedJson);
            emit(ItineraryReceivedSuccess(itinerary));
          }
        } catch (saveError) {
          log("Error saving streaming itinerary: $saveError");
          // Fallback to creating from JSON without saving
          final itinerary = Itinerary.fromJson(parsedJson);
          emit(ItineraryReceivedSuccess(itinerary));
        }
      } else {
        emit(ChatReciveSuccess(completeResponse));
      }
      
    } catch (e) {
      log("Stream JSON parsing error: $e");
      emit(ChatReciveSuccess(completeResponse));
    }
  } catch (error) {
    log("StreamData Error: $error");
    emit(ChatFailure("Failed to get a response"));
  }
}
  Future<int> createNewChatSession() async {
  return await _messageRepository.createNewChatSession();
}
  Future<void> addSystemMessage(int chatId, String message) async {
  await _messageRepository.addMessage(
    chatId: chatId,
    isUser: false,
    message: message,
    timestamp: DateTime.now().toIso8601String(),
  );
}
}