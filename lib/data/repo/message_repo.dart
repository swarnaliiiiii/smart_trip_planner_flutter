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
        await _isar.messages.put(newMessage);
        session.messages.add(newMessage);
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
        .sortByTimestamp()
        .findAll();
  }

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

  Future<int> createNewChatSession() async {
    final maxIdSession = await _isar.chatSessions
        .where()
        .sortByChatIdDesc()
        .findFirst();

    final newChatId = (maxIdSession?.chatId ?? 0) + 1;

    final newSession = ChatSession()
      ..chatId = newChatId
      ..createdAt = DateTime.now().toIso8601String();

    await _isar.writeTxn(() async {
      await _isar.chatSessions.put(newSession);
    });

    return newChatId;
  }

  Future<List<ChatSession>> getChatSessions() async {
    final sessions = await _isar.chatSessions.where().sortByChatIdDesc().findAll();

    if (sessions.isEmpty) {
      final defaultSession = ChatSession()
        ..chatId = 1
        ..createdAt = DateTime.now().toIso8601String();

      await _isar.writeTxn(() async {
        await _isar.chatSessions.put(defaultSession);
      });

      return [defaultSession];
    }

    return sessions;
  }

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

  Future<void> saveItinerary(int chatId, Itinerary itinerary) async {
    await _isar.writeTxn(() async {
      await _isar.itineraries.put(itinerary);
      
      final session = await _isar.chatSessions
          .filter()
          .chatIdEqualTo(chatId)
          .findFirst();

      if (session != null) {
        session.itinerary.value = itinerary;
        await session.itinerary.save();
      }
    });
  }

  Future<Itinerary?> getItinerary(int chatId) async {
    final session = await _isar.chatSessions
        .filter()
        .chatIdEqualTo(chatId)
        .findFirst();

    if (session != null) {
      await session.itinerary.load();
      return session.itinerary.value;
    }
    return null;
  }

  Future<List<Itinerary>> getAllItineraries() async {
    return await _isar.itineraries.where().sortByCreatedAtDesc().findAll();
  }
}