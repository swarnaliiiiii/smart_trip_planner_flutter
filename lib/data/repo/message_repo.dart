import 'dart:developer';
import 'package:isar/isar.dart';
import 'package:talk_trip/data/models/message.dart';
import 'package:talk_trip/data/models/chat_session.dart';
import 'package:talk_trip/data/models/itinerary.dart';

class MessageRepository {
  final Isar _isar;

  MessageRepository(this._isar);

  
  Future<void> addMessage({
    required int chatId,
    required bool isUser,
    required String message,
    required String timestamp,
    String? image,
    String? recognizedText,
  }) async {
    try {
      final session = await _isar.chatSessions
          .filter()
          .chatIdEqualTo(chatId)
          .findFirst();

      if (session == null) {
        throw Exception("Session $chatId not found");
      }

      final newMessage = Message()
        ..chatId = chatId
        ..isUser = isUser
        ..message = message
        ..timestamp = timestamp
        ..image = image
        ..recognizedText = recognizedText;

      await _isar.writeTxn(() async {
        session.messages.add(newMessage);
        await _isar.messages.put(newMessage);
        await session.messages.save();
      });
    } catch (e) {
      log("Isar addMessage error: $e");
    }
  }

  
  Future<List<Message>> getMessages(int chatId) async {
    return await _isar.messages
        .filter()
        .chatIdEqualTo(chatId)
        .sortByTimestampDesc()
        .findAll();
  }

  // Clear all messages for a session
  Future<void> clearMessages(int chatId) async {
    await _isar.writeTxn(() async {
      final messages = await _isar.messages
          .filter()
          .chatIdEqualTo(chatId)
          .findAll();

      for (final msg in messages) {
        await _isar.messages.delete(msg.id);
      }

      final session = await _isar.chatSessions
          .filter()
          .chatIdEqualTo(chatId)
          .findFirst();

      if (session != null) {
        session.messages.clear();
        await session.messages.save();
      }
    });
  }

  // Create a new chat session
  Future<int> createNewChatSession() async {
    final maxIdSession = await _isar.chatSessions
        .where()
        .sortByChatIdDesc()
        .findFirst();

    final newChatId = (maxIdSession?.chatId ?? 1) + 1;

    final newSession = ChatSession()
      ..chatId = newChatId
      ..createdAt = DateTime.now().toIso8601String();

    await _isar.writeTxn(() async {
      await _isar.chatSessions.put(newSession);
    });

    return newChatId;
  }

  // Get all chat sessions
  Future<List<ChatSession>> getChatSessions() async {
    final sessions = await _isar.chatSessions.where().sortByChatIdDesc().findAll();

    if (sessions.isEmpty) {
      final defaultSession = ChatSession()
        ..chatId = 1
        ..createdAt = DateTime.now().toIso8601String();

      final welcomeMsg1 = Message()
        ..chatId = 1
        ..isUser = true
        ..message = "Hello"
        ..timestamp = DateTime.now().toIso8601String();

      final welcomeMsg2 = Message()
        ..chatId = 1
        ..isUser = false
        ..message = "How can I help you today?"
        ..timestamp = DateTime.now().toIso8601String();

      await _isar.writeTxn(() async {
        await _isar.chatSessions.put(defaultSession);
        await _isar.messages.putAll([welcomeMsg1, welcomeMsg2]);
        defaultSession.messages.addAll([welcomeMsg1, welcomeMsg2]);
        await defaultSession.messages.save();
      });

      return [defaultSession];
    }

    return sessions;
  }

  // Delete a session + its messages
  Future<void> deleteChatSession(int chatId) async {
    await _isar.writeTxn(() async {
      final session = await _isar.chatSessions
          .filter()
          .chatIdEqualTo(chatId)
          .findFirst();

      if (session != null) {
        await session.messages.load();
        for (final msg in session.messages) {
          await _isar.messages.delete(msg.id);
        }
        await _isar.chatSessions.delete(session.id);
      }
    });
  }

  // Store itinerary in session
  Future<void> updateItinerary(int chatId, Itinerary itinerary) async {
    await _isar.writeTxn(() async {
      final session = await _isar.chatSessions
          .filter()
          .chatIdEqualTo(chatId)
          .findFirst();

      if (session != null) {
        session.itinerary = itinerary;
        await _isar.itineraries.put(itinerary);
        await _isar.chatSessions.put(session);
      }
    });
  }

  // Fetch itinerary from session
  Future<Itinerary?> getItinerary(int chatId) async {
    final session = await _isar.chatSessions
        .filter()
        .chatIdEqualTo(chatId)
        .findFirst();

    return session?.itinerary;
  }
}
