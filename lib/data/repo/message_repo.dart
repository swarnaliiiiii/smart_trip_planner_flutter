import 'dart:convert';
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

  Future<void> saveItineraryFromJson(int chatId, String jsonString) async {
    try {
      log("Parsing JSON: $jsonString");
      
      // Extract JSON from response if needed
      String cleanJsonString = jsonString;
      if (!jsonString.trim().startsWith('{')) {
        final jsonStart = jsonString.indexOf('{');
        final jsonEnd = jsonString.lastIndexOf('}') + 1;
        
        if (jsonStart != -1 && jsonEnd > jsonStart) {
          cleanJsonString = jsonString.substring(jsonStart, jsonEnd);
        }
      }
      
      // Parse JSON string
      final jsonData = jsonDecode(cleanJsonString);
      
      // Create itinerary from JSON
      final itinerary = Itinerary.fromJson(jsonData);
      
      // Create days, activities, and restaurants
      List<ItineraryDay> days = [];
      List<Activity> allActivities = [];
      List<Restaurant> allRestaurants = [];
      
      if (jsonData['days'] != null) {
        for (var dayJson in jsonData['days']) {
          final day = ItineraryDay.fromJson(dayJson);
          
          // Create activities for this day
          if (dayJson['activities'] != null) {
            for (var activityJson in dayJson['activities']) {
              final activity = Activity.fromJson(activityJson);
              allActivities.add(activity);
            }
          }
          
          // Create restaurants for this day
          if (dayJson['restaurants'] != null) {
            for (var restaurantJson in dayJson['restaurants']) {
              final restaurant = Restaurant.fromJson(restaurantJson);
              allRestaurants.add(restaurant);
            }
          }
          
          days.add(day);
        }
      }
      
      await _isar.writeTxn(() async {
        // 1. Save all activities first
        for (final activity in allActivities) {
          await _isar.activitys.put(activity);
        }
        
        // 2. Save all restaurants
        for (final restaurant in allRestaurants) {
          await _isar.restaurants.put(restaurant);
        }
        
        // 3. Save all days and link activities/restaurants
        int activityIndex = 0;
        int restaurantIndex = 0;
        
        for (int i = 0; i < days.length; i++) {
          final day = days[i];
          await _isar.itineraryDays.put(day);
          
          // Link activities to this day
          final dayJson = jsonData['days'][i];
          if (dayJson['activities'] != null) {
            for (int j = 0; j < dayJson['activities'].length; j++) {
              day.activities.add(allActivities[activityIndex]);
              activityIndex++;
            }
          }
          
          // Link restaurants to this day
          if (dayJson['restaurants'] != null) {
            for (int j = 0; j < dayJson['restaurants'].length; j++) {
              day.restaurants.add(allRestaurants[restaurantIndex]);
              restaurantIndex++;
            }
          }
          
          // Save the links
          await day.activities.save();
          await day.restaurants.save();
          
          // Add day to itinerary
          itinerary.days.add(day);
        }
        
        // 4. Save the main itinerary
        await _isar.itinerarys.put(itinerary);
        await itinerary.days.save();
        
        // 5. Link itinerary to chat session
        final session = await _isar.chatSessions
            .filter()
            .chatIdEqualTo(chatId)
            .findFirst();

        if (session != null) {
          session.itinerary.value = itinerary;
          await session.itinerary.save();
        }
      });
      
      log("Itinerary saved successfully with ${days.length} days");
    } catch (e) {
      log("Error saving itinerary: $e");
      rethrow;
    }
  }

  Future<void> saveItinerary(int chatId, Itinerary itinerary) async {
    await _isar.writeTxn(() async {
      await _isar.itinerarys.put(itinerary);
      
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
    try {
      final session = await _isar.chatSessions
          .filter()
          .chatIdEqualTo(chatId)
          .findFirst();

      if (session != null) {
        await session.itinerary.load();
        final itinerary = session.itinerary.value;
        
        if (itinerary != null) {
          // Load all related data
          await itinerary.days.load();
          for (final day in itinerary.days) {
            await day.activities.load();
            await day.restaurants.load();
          }
        }
        
        return itinerary;
      }
      return null;
    } catch (e) {
      log("Error getting itinerary: $e");
      return null;
    }
  }

  Future<List<Itinerary>> getAllItineraries() async {
    final itineraries = await _isar.itinerarys.where().sortByCreatedAtDesc().findAll();
    
    // Load all related data for each itinerary
    for (final itinerary in itineraries) {
      await itinerary.days.load();
      for (final day in itinerary.days) {
        await day.activities.load();
        await day.restaurants.load();
      }
    }
    
    return itineraries;
  }
}