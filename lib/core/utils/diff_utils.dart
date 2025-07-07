class ItineraryDiff {
  final List<String> addedActivities;
  final List<String> removedActivities;
  final List<String> modifiedActivities;
  final List<String> addedRestaurants;
  final List<String> removedRestaurants;
  final Map<String, String> changedFields;

  ItineraryDiff({
    this.addedActivities = const [],
    this.removedActivities = const [],
    this.modifiedActivities = const [],
    this.addedRestaurants = const [],
    this.removedRestaurants = const [],
    this.changedFields = const {},
  });

  bool get hasChanges => 
    addedActivities.isNotEmpty ||
    removedActivities.isNotEmpty ||
    modifiedActivities.isNotEmpty ||
    addedRestaurants.isNotEmpty ||
    removedRestaurants.isNotEmpty ||
    changedFields.isNotEmpty;
}

class DiffUtils {
  static ItineraryDiff compareItineraries(
    Itinerary? oldItinerary,
    Itinerary newItinerary,
  ) {
    if (oldItinerary == null) {
      return ItineraryDiff(); // No diff for first itinerary
    }

    List<String> addedActivities = [];
    List<String> removedActivities = [];
    List<String> modifiedActivities = [];
    List<String> addedRestaurants = [];
    List<String> removedRestaurants = [];
    Map<String, String> changedFields = {};

    // Compare basic fields
    if (oldItinerary.title != newItinerary.title) {
      changedFields['title'] = 'Title changed from "${oldItinerary.title}" to "${newItinerary.title}"';
    }
    if (oldItinerary.duration != newItinerary.duration) {
      changedFields['duration'] = 'Duration changed from ${oldItinerary.duration} to ${newItinerary.duration} days';
    }
    if (oldItinerary.budget != newItinerary.budget) {
      changedFields['budget'] = 'Budget changed from "${oldItinerary.budget}" to "${newItinerary.budget}"';
    }

    // Get all activities from old and new itineraries
    Set<String> oldActivities = {};
    Set<String> newActivities = {};
    Set<String> oldRestaurants = {};
    Set<String> newRestaurants = {};

    for (final day in oldItinerary.days) {
      for (final activity in day.activities) {
        oldActivities.add(activity.name);
      }
      for (final restaurant in day.restaurants) {
        oldRestaurants.add(restaurant.name);
      }
    }

    for (final day in newItinerary.days) {
      for (final activity in day.activities) {
        newActivities.add(activity.name);
      }
      for (final restaurant in day.restaurants) {
        newRestaurants.add(restaurant.name);
      }
    }

    // Find differences
    addedActivities = newActivities.difference(oldActivities).toList();
    removedActivities = oldActivities.difference(newActivities).toList();
    addedRestaurants = newRestaurants.difference(oldRestaurants).toList();
    removedRestaurants = oldRestaurants.difference(newRestaurants).toList();

    return ItineraryDiff(
      addedActivities: addedActivities,
      removedActivities: removedActivities,
      modifiedActivities: modifiedActivities,
      addedRestaurants: addedRestaurants,
      removedRestaurants: removedRestaurants,
      changedFields: changedFields,
    );
  }
}