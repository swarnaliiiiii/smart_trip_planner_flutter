
@collection
class ChatSession {
  Id id = Isar.autoIncrement;
  late int chatId;
  late String createdAt;

  final messages = IsarLinks<Message>();
  final itinerary = IsarLink<Itinerary>();
}
