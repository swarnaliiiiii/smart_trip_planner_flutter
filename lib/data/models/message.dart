import 'package:isar/isar.dart';

part 'message.g.dart';

@collection
class Message {
  Id id = Isar.autoIncrement;
  
  @Index()
  late int chatId;
  
  late bool isUser;
  late String message;
  
  @Index()
  late String timestamp;
  
  String? image;
  String? recognizedText;

  Message();
}