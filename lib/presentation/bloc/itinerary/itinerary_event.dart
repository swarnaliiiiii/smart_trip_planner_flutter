part of 'itinerary_bloc.dart';

@immutable
abstract class ItineraryEvent {}

class CreateItinerary extends ItineraryEvent {
  final String prompt;
  CreateItinerary({required this.prompt});
}

class RegenerateItinerary extends ItineraryEvent {
  final Itinerary itinerary;
  RegenerateItinerary({required this.itinerary});
}

class SaveItinerary extends ItineraryEvent {
  final Itinerary itinerary;
  SaveItinerary({required this.itinerary});
}

class FollowUpItinerary extends ItineraryEvent {
  final Itinerary itinerary;
  final String followUp;
  FollowUpItinerary({required this.itinerary, required this.followUp});
}

class CopyItinerary extends ItineraryEvent {
  final Itinerary itinerary;
  CopyItinerary({required this.itinerary});
}
