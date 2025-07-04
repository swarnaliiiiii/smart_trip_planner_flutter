import 'package:isar/isar.dart';
import 'message.dart';
import 'itinerary.dart';

part 'chat_session.g.dart';

@collection
class ChatSession {
  Id id = Isar.autoIncrement;
  late int chatId;
  late String createdAt;

  final messages = IsarLinks<Message>();
  final itinerary = IsarLink<Itinerary>();
}