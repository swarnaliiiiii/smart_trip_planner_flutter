import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talk_trip/data/models/message.dart';
import 'package:talk_trip/data/models/chat_session.dart';
import 'package:talk_trip/data/models/itinerary.dart';
import 'package:talk_trip/data/models/user.dart';

class DatabaseService {
  static Isar? _isar;

  static Future<Isar> get instance async {
    if (_isar != null) return _isar!;
    
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        MessageSchema,
        ChatSessionSchema,
        ItinerarySchema,
        ItineraryDaySchema,
        ActivitySchema,
        RestaurantSchema,
        UserSchema,
      ],
      directory: dir.path,
    );
    
    return _isar!;
  }

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}