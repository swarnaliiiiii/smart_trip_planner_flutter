part of 'itinerary_bloc.dart';

@immutable
abstract class ItineraryState {}

class ItineraryInitial extends ItineraryState {}

class ItineraryLoading extends ItineraryState {}

class ItineraryLoaded extends ItineraryState {
  final Itinerary itinerary;
  ItineraryLoaded(this.itinerary);
}

class ItineraryError extends ItineraryState {
  final String message;
  ItineraryError(this.message);
}
