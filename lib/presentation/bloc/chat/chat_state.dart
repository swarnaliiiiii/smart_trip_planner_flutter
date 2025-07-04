part of 'chat_bloc.dart';

@immutable
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatSendSuccess extends ChatState {}

class ChatReciveSuccess extends ChatState {
  final String response;

  const ChatReciveSuccess(this.response);

  @override
  List<Object> get props => [response];
}

class ChatStreaming extends ChatState {
  final String streamedText;

  const ChatStreaming(this.streamedText);

  @override
  List<Object> get props => [streamedText];
}

class ChatFailure extends ChatState {
  final String error;

  const ChatFailure(this.error);

  @override
  List<Object> get props => [error];
}

class NewChatSessionCreated extends ChatState {
  final int newChatId;

  const NewChatSessionCreated(this.newChatId);

  @override
  List<Object> get props => [newChatId];
}

class ChatSessionDeleted extends ChatState {
  final int chatId;

  const ChatSessionDeleted(this.chatId);

  @override
  List<Object> get props => [chatId];
}

class ChatSessionLoaded extends ChatState {
  final int chatId;
  final List<Message> messages;

  const ChatSessionLoaded(this.chatId, this.messages);

  @override
  List<Object> get props => [chatId, messages];
}

class ItineraryReceivedSuccess extends ChatState {
  final Itinerary itinerary;

  const ItineraryReceivedSuccess(this.itinerary);

  @override
  List<Object> get props => [itinerary];
}