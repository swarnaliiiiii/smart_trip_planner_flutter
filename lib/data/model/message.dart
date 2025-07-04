@collection
class Itinerary {
  Id id = Isar.autoIncrement;
  late String title;
  late String startDate;
  late String endDate;
  final days = IsarLinks<ItineraryDay>();
}
