import 'package:isar/isar.dart';

part 'itinerary.g.dart';

@collection
class Itinerary {
  Id id = Isar.autoIncrement;
  
  late String title;
  late String destination;
  late String startDate;
  late String endDate;
  late int duration;
  late String budget;
  late String travelStyle;
  String? description;
  
  @Index()
  late String createdAt;
  
  final days = IsarLinks<ItineraryDay>();

  Itinerary();

  Itinerary.fromJson(Map<String, dynamic> json) {
    title = json['title'] ?? '';
    destination = json['destination'] ?? '';
    startDate = json['startDate'] ?? '';
    endDate = json['endDate'] ?? '';
    duration = json['duration'] ?? 0;
    budget = json['budget'] ?? '';
    travelStyle = json['travelStyle'] ?? '';
    description = json['description'];
    createdAt = DateTime.now().toIso8601String();
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'destination': destination,
      'startDate': startDate,
      'endDate': endDate,
      'duration': duration,
      'budget': budget,
      'travelStyle': travelStyle,
      'description': description,
      'createdAt': createdAt,
    };
  }
}

@collection
class ItineraryDay {
  Id id = Isar.autoIncrement;
  
  late int dayNumber;
  late String date;
  late String title;
  String? description;
  
  final activities = IsarLinks<Activity>();
  final restaurants = IsarLinks<Restaurant>();

  ItineraryDay();
}

@collection
class Activity {
  Id id = Isar.autoIncrement;
  
  late String name;
  late String type;
  String? description;
  String? location;
  String? mapLink;
  String? timeSlot;
  double? estimatedCost;
  double? rating;
  String? imageUrl;
  bool isRecommended = false;

  Activity();
}

@collection
class Restaurant {
  Id id = Isar.autoIncrement;
  
  late String name;
  late String cuisine;
  String? description;
  String? location;
  String? mapLink;
  String? priceRange;
  double? rating;
  String? imageUrl;
  bool isRecommended = false;

  Restaurant();
}