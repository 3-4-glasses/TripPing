// 
//
//USED FOR THE PURPOSE OF MIMICKING USER DATA FROM BACKEND
//
//

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'trip_data.dart';
import 'package:http/http.dart' as http;
import '../data/global_user.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class GlobalTripData extends ChangeNotifier{
  static final GlobalTripData _instance = GlobalTripData._internal();
  static GlobalTripData get instance => _instance;

  late TripData tripData;

  GlobalTripData._internal();

  // Initialize the tripData
  void initialize() {
    tripData = new TripData();
  }

  Future<void> initializeDbData() async {
    try {
      final res = await http.get(
      Uri.parse('https://backend-server-412321340776.us-west1.run.app/trip/all?userId=${UserSession.instance.uid}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        print(body);
        final tripsJson = body['trips'] ?? [];

        await updateFromJson(tripsJson);

      } else {
        throw Exception(res.body);
        }
      } catch (e) {
        // On failure, fall back to dummy data

        tripData = new TripData();
        print('Error fetching trips: $e');
      }
      notifyListeners();
  }
  Future<void> updateFromJson(List<dynamic> tripsJson) async {
    final TripData newTripData = TripData();
    for (var trip in tripsJson) {
      try {
        final res = await http.get(
          Uri.parse(
              'https://backend-server-412321340776.us-west1.run.app/trip/itineraries?userId=${UserSession.instance.uid}&tripId=${trip['id']}'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          print('Full Response: $body');


          final itinerariesJson = body['iteneraries'] ?? [];  // Fixed typo from 'iteneraries' to 'itineraries'

          // Check that itinerariesJson is a List
          if (itinerariesJson is List) {
            // Create a Map to hold itinerary data
            Map<String, Itinerary> itineraries = {};

            // Map each itinerary data to the Map
            for (var itinerary in itinerariesJson) {
              try {
                String itineraryId = itinerary['id'];

                // Parse the activities
                List<Activity> activities = [];
                for (var activityJson in itinerary['activities']) {

                  DateTime fromDateTime = DateTime.fromMillisecondsSinceEpoch(
                      (activityJson['from']['_seconds'] as int) * 1000);
                  DateTime toDateTime = DateTime.fromMillisecondsSinceEpoch(
                      (activityJson['to']['_seconds'] as int) * 1000);

                  String fromTime = DateFormat('HH:mm').format(fromDateTime);
                  String toTime = DateFormat('HH:mm').format(toDateTime);

                  // Safely parse 'location' as a Map<String, dynamic>
                  Map<String, dynamic> location = {};
                  if (activityJson['location'] != null && activityJson['location'] is Map) {
                    location = Map<String, dynamic>.from(activityJson['location']);
                  }

                  Activity activity = Activity.fromJson({
                    'from': fromTime,  // Use the time string instead of DateTime
                    'to': toTime,
                    'title': activityJson['title'],
                    'details': activityJson['details'],
                    'location': location, // Ensure the location is correctly formatted
                    'locationDetail': activityJson['locationDetail']
                  });

                  activities.add(activity);
                }

                Itinerary itineraryObj = Itinerary(
                  // id:itineraryId, TODO
                  date: itinerary['date'] ?? '',
                  activities: activities,
                );

                itineraries[itineraryId] = itineraryObj;
              } catch (e) {
                print("Error processing itinerary: $e");
              }
            }

            // Add itineraries to the trip
            final fromTimestamp = trip['from'];
            final toTimestamp = trip['to'];

            final from = DateTime.fromMillisecondsSinceEpoch(
                fromTimestamp['_seconds'] * 1000);
            final to = DateTime.fromMillisecondsSinceEpoch(
                toTimestamp['_seconds'] * 1000);

            final List<dynamic> fixedExpensesList = trip['setExpenses'] ?? [];
            final List<dynamic> variableExpensesList = trip['variableExpenses'] ?? [];

            Trip newTrip = Trip(
              id: trip['id'] ?? '',
              name: ValueNotifier<String>(trip['title'] ?? 'Unnamed Trip'),
              dateFrom: ValueNotifier<String?>(from.toIso8601String().split("T").first),
              dateTo: ValueNotifier<String?>(to.toIso8601String().split("T").first),
              expensesUsed: ValueNotifier<double>((trip['expensesUsed'] as num?)?.toDouble() ?? 0.0),
              expensesLimit: ValueNotifier<double>((trip['expensesLimit'] as num?)?.toDouble() ?? 0.0),
              items: ValueNotifier<List<String>>(List<String>.from(trip['items'] ?? [])),
              fixedExpenses: ValueNotifier<List<Map<String, dynamic>>>(
                fixedExpensesList.map<Map<String, dynamic>>((e) {
                  return {
                    'item': e['item'] ?? '',
                    'price': (e['price'] as num?)?.toDouble() ?? 0.0,
                  };
                }).toList(),
              ),
              variableExpenses: ValueNotifier<List<Map<String, dynamic>>>(
                variableExpensesList.map<Map<String, dynamic>>((e) {
                  return {
                    'item': e['item'] ?? '',
                    'price': (e['price'] as num?)?.toDouble() ?? 0.0,
                  };
                }).toList(),
              ),
              itineraries: itineraries,  // Assign itineraries data here
            );

            newTripData.addTrip(newTrip);
          } else {
            print('Itineraries is not a List');
          }
        }
      } catch (e) {
        print(e);
      }
    }

    tripData = newTripData;
    tripData.notifyListeners();
    notifyListeners();
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