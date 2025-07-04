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
          final jsonStart = response.indexOf('{');
          final jsonEnd = response.lastIndexOf('}') + 1;
          if (jsonStart != -1 && jsonEnd > jsonStart) {
            final jsonString = response.substring(jsonStart, jsonEnd);
            final parsedJson = jsonDecode(jsonString);
            final itinerary = Itinerary.fromJson(parsedJson);
            
            await _messageRepository.saveItinerary(event.chatId, itinerary);
            emit(ItineraryReceivedSuccess(itinerary));
          } else {
            emit(ChatReciveSuccess(response));
          }
        } catch (e) {
          log("JSON parsing error: $e");
          emit(ChatReciveSuccess(response));
        }
      } else {
        emit(ChatFailure("Failed to get a response"));
      }
    } catch (error) {
      log(error.toString());
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

      try {
        final parsedJson = jsonDecode(completeResponse);
        final itinerary = Itinerary.fromJson(parsedJson);
        await _messageRepository.saveItinerary(event.chatId, itinerary);
        emit(ItineraryReceivedSuccess(itinerary));
      } catch (e) {
        emit(ChatReciveSuccess(completeResponse));
      }
    } catch (error) {
      log("StreamData Error: $error");
      emit(ChatFailure("Failed to get a response"));
    }
  }
}