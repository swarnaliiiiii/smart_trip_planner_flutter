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
      'days': days.map((day) => day.toJson()).toList(),
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

  ItineraryDay.fromJson(Map<String, dynamic> json) {
    dayNumber = json['dayNumber'] ?? 0;
    date = json['date'] ?? '';
    title = json['title'] ?? '';
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'date': date,
      'title': title,
      'description': description,
      'activities': activities.map((activity) => activity.toJson()).toList(),
      'restaurants': restaurants.map((restaurant) => restaurant.toJson()).toList(),
    };
  }
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

  Activity.fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? '';
    type = json['type'] ?? '';
    description = json['description'];
    location = json['location'];
    mapLink = json['mapLink'];
    timeSlot = json['timeSlot'];
    estimatedCost = json['estimatedCost']?.toDouble();
    rating = json['rating']?.toDouble();
    imageUrl = json['imageUrl'];
    isRecommended = json['isRecommended'] ?? false;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'location': location,
      'mapLink': mapLink,
      'timeSlot': timeSlot,
      'estimatedCost': estimatedCost,
      'rating': rating,
      'imageUrl': imageUrl,
      'isRecommended': isRecommended,
    };
  }
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

  Restaurant.fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? '';
    cuisine = json['cuisine'] ?? '';
    description = json['description'];
    location = json['location'];
    mapLink = json['mapLink'];
    priceRange = json['priceRange'];
    rating = json['rating']?.toDouble();
    imageUrl = json['imageUrl'];
    isRecommended = json['isRecommended'] ?? false;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cuisine': cuisine,
      'description': description,
      'location': location,
      'mapLink': mapLink,
      'priceRange': priceRange,
      'rating': rating,
      'imageUrl': imageUrl,
      'isRecommended': isRecommended,
    };
  }
}

