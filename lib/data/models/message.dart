import 'package:isar/isar.dart';

part 'message.g.dart';

@collection
class Message {
  Id id = Isar.autoIncrement;
  late int chatId;
  late bool isUser;
  late String message;
  late String timestamp;
  String? image;
  String? recognizedText;
}