// 
//
//USED FOR THE PURPOSE OF MIMICKING USER DATA FROM BACKEND
//
//

import 'package:flutter/material.dart';
import 'trip_data.dart'; 

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class GlobalTripData {
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

    final activity1 = Activity(
      from: "09:00",
      to: "10:30",
      title: "Visit Tanah Lot Temple",
      location: location1,
      details:
          "Explore a scenic seaside Balinese Hindu temple and learn about local traditions.",
    );
    final activity2 = Activity(
      from: "23:30",
      to: "23:59",
      title: "Local market tour",
      details:
          "Support local artisans by exploring handmade crafts and regional food.",
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
      date: "2025-07-28",
      activities: [activity1, activity2],
    );
    final itinerary2 = Itinerary(
      date: "2025-07-29",
      activities: [activity3],
    );
    final itinerary3 = Itinerary(
      date: "2025-07-30",
      activities: [activity4],
    );

    final trip1 = Trip(
      id: 'trip1',
      name: ValueNotifier<String>('Bali Adventure'),
      dateFrom: ValueNotifier<String?>('2025-07-28'),
      dateTo: ValueNotifier<String?>('2025-08-02'),
      expensesUsed: ValueNotifier<double>(250.0),
      expensesLimit: ValueNotifier<double>(1000.0),
      items: ValueNotifier<List<String>>(['Sunscreen', 'Hat']),
      variableExpenses: ValueNotifier<List<String>>(['Food', 'Souvenirs']),
      fixedExpenses: ValueNotifier<List<String>>(['Accommodation', 'Transport']),
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
      expensesUsed: ValueNotifier<double>(500.0),
      expensesLimit: ValueNotifier<double>(2000.0),
      items: ValueNotifier<List<String>>(['Passport', 'Charger']),
      variableExpenses: ValueNotifier<List<String>>(['Food', 'Shopping']),
      fixedExpenses: ValueNotifier<List<String>>(['Hotel', 'Train']),
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
}