// 
//
//USED FOR THE PURPOSE OF MIMICKING USER DATA FROM BACKEND
//
//

import 'package:flutter/material.dart';
import 'trip_data.dart'; 

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class GlobalTripData extends ChangeNotifier{
  static final GlobalTripData _instance = GlobalTripData._internal();
  static GlobalTripData get instance => _instance;

  late TripData tripData;

  GlobalTripData._internal();

  // Initialize the tripData
  void initialize() {
    tripData = _createDummyTripData(); // Or load from storage/API
  }

  TripData _createDummyTripData() {

    final tripData = TripData();

    final location1 = Location(latitude: -8.6216, longitude: 115.0866);
    final location2 = Location(latitude: -8.4095, longitude: 115.1889);
    final location3 = Location(latitude: -8.3405, longitude: 115.0919);
    final location5 = Location(latitude: -8.3605, longitude: 112.0002);

    final activity1 = Activity(
      from: "08:30",
      to: "09:30",
      title: "Visit Tanah Lot Temple",
      location: location1,
      details:
          "Explore a scenic seaside Balinese Hindu temple and learn about local traditions.",
    );
    final activity2 = Activity(
      from: "16:00",
      to: "19:00",
      title: "Local market tour",
      details:
          "Support local artisans by exploring handmade crafts and regional food.",
    );
    final activity5 = Activity(
      from: "20:00",
      to: "24:00",
      title: "Dinner at the beach",
      location: location5,
      details:
          "Get some fried scallops.",
    );
    final activity3 = Activity(
      from: "14:00",
      to: "16:00",
      title: "Ubud Monkey Forest",
      location: location2,
      details: "Interact with playful monkeys in a sacred forest.",
    );
    final activity4 = Activity(
      from: "10:00",
      to: "12:00",
      title: "Tegallalang Rice Terraces",
      location: location3,
      details: "Visit the beautiful rice fields",
    );

    final itinerary1 = Itinerary(
      date: "2025-05-14",
      activities: [activity1, activity2, activity5],
    );
    final itinerary2 = Itinerary(
      date: "2025-05-15",
      activities: [activity3],
    );
    final itinerary3 = Itinerary(
      date: "2025-05-16",
      activities: [activity4],
    );

    final trip1 = Trip(
      id: 'trip1',
      name: ValueNotifier<String>('Bali Adventure'),
      dateFrom: ValueNotifier<String?>('2025-05-14'),
      dateTo: ValueNotifier<String?>('2025-05-16'),
      expensesUsed: ValueNotifier<double>(380.0),
      expensesLimit: ValueNotifier<double>(1000.0),
      items: ValueNotifier<List<String>>(['Sunscreen', 'Hat']),
      variableExpenses: ValueNotifier<List<Map<String, dynamic>>>([]),
      fixedExpenses: ValueNotifier<List<Map<String, dynamic>>>([
        {'item': 'Accommodation', 'price': 300.0},
        {'item': 'Transport', 'price': 80.0},
      ]),
      itineraries: {
        'day1': itinerary1,
        'day2': itinerary2,
        'day3': itinerary3,
      },
    );

    final trip2 = Trip(
      id: 'trip2',
      name: ValueNotifier<String>('Japan Tour'),
      dateFrom: ValueNotifier<String?>('2025-08-10'),
      dateTo: ValueNotifier<String?>('2025-08-17'),
      expensesUsed: ValueNotifier<double>(700.0),
      expensesLimit: ValueNotifier<double>(2000.0),
      items: ValueNotifier<List<String>>(['Passport', 'Charger']),
      variableExpenses: ValueNotifier<List<Map<String, dynamic>>>([]),
      fixedExpenses: ValueNotifier<List<Map<String, dynamic>>>([
        {'item': 'Hotel', 'price': 600.0},
        {'item': 'Train', 'price': 100.0},
      ]),
      itineraries: {
        'day1': Itinerary(
          date: '2025-08-11',
          activities: [
            Activity(
              from: '10:00',
              to: '17:00',
              title: 'Tokyo City Tour',
              details: 'Explore Tokyo',
            ),
          ],
        ),
      },
    );

    // Add the trip to the TripData
    tripData.addTrip(trip1);
    tripData.addTrip(trip2);
    return tripData;
  }

  void addTrip(Trip trip){
    tripData.addTrip(trip);
    notifyListeners();
  }

  void updateTrip(String tripId, Trip updateTrip){
    tripData.updateTrip(tripId, updateTrip);
    notifyListeners();
  }

  void deleteTrip(String tripId){
    tripData.deleteTrip(tripId);
    notifyListeners();
  }
}