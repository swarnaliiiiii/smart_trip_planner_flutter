import 'dart:async';
import 'dart:developer';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:meta/meta.dart';
import 'package:talk_trip/data/sources/api/gen_ai_service.dart';
import 'package:talk_trip/data/repo/message_repo.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GenerativeAIWebService _webService;
  final MessageRepository _messageRepository;

  ChatBloc(this._webService, this._messageRepository) : super(ChatInitial()) {
    on<PostDataEvent>(_onPostData);
    on<StreamDataEvent>(_onStreamData);
    on<CreateNewChatSessionEvent>(_onCreateNewChatSession);
    on<DeleteChatSessionEvent>(_onDeleteChatSession);
  }

  Future<void> _onCreateNewChatSession(
      CreateNewChatSessionEvent event, Emitter<ChatState> emit) async {
    try {
      final messages = _messageRepository.getMessages(getSessionId()).toList();
      if (messages.isNotEmpty) {
        final newChatId = await _messageRepository.createNewChatSession();
        emit(NewChatSessionCreated(newChatId));
      } else {
        emit(ChatFailure("Already in new chat!"));
      }
    } catch (error) {
      emit(ChatFailure(
          "Failed to create new chat session: ${error.toString()}"));
    }
  }

  int getSessionId() {
    return _messageRepository.getChatSessions().last.chatId;
  }

  List<Message> getMessages(int chatId) {
    return _messageRepository.getMessages(chatId).reversed.toList();
  }

  List<ChatSession> getChatSessions() {
    return _messageRepository.getChatSessions().reversed.toList();
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

  Future<void> _onPostData(PostDataEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      if (!await NetworkManager.isConnected()) {
        emit(ChatFailure("No internet connection"));
      }

      await _messageRepository.addMessage(
        chatId: event.chatId,
        isUser: true,
        message: event.prompt,
        timestamp: DateTime.now().toString(),
      );
      emit(ChatSendSuccess());
      final messages = _messageRepository.getMessages(event.chatId);

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
          timestamp: DateTime.now().toString(),
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

  Future<void> _onStreamData(
    StreamDataEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    final StringBuffer fullResponse = StringBuffer();

    try {
      // Check for network
      if (!await NetworkManager.isConnected()) {
        emit(ChatFailure("No internet connection"));
        return;
      }

      // Save user message
      await _messageRepository.addMessage(
        chatId: event.chatId,
        isUser: true,
        message: event.prompt,
        timestamp: DateTime.now().toString(),
      );
      emit(ChatSendSuccess());

      // Prepare contents for LLM
      final messages = _messageRepository.getMessages(event.chatId);
      final contents = messages.map((msg) {
        if (msg == messages.last && event.recognizedText != null) {
          return ai.Content.text(
            "${msg.message}\n\n[Recognized Text]: ${event.recognizedText}",
          );
        } else {
          return ai.Content.text(msg.message);
        }
      }).toList();

      // Stream response
      await for (final chunk in _webService.streamData(contents)) {
        if (chunk != null) {
          fullResponse.write(chunk);
          await Future.delayed(Duration(milliseconds: 200));
          emit(ChatStreaming(chunk));
        }
      }

      // Give a small delay before processing full result
      await Future.delayed(Duration(milliseconds: 500));
      final completeResponse = fullResponse.toString();

      // Save assistant's response
      await _messageRepository.addMessage(
        chatId: event.chatId,
        isUser: false,
        message: completeResponse,
        timestamp: DateTime.now().toString(),
      );

      // Try parsing as itinerary JSON
      try {
        final parsedJson = jsonDecode(completeResponse);
        final itinerary = Itinerary.fromJson(parsedJson);
        emit(ItineraryReceivedSuccess(itinerary));
      } catch (e) {
        // Not a JSON itinerary – fallback to text response
        emit(ChatReciveSuccess(completeResponse));
      }
    } catch (error) {
      log("StreamData Error: $error");
      emit(ChatFailure("Failed to get a response"));
    }
  }
}
