// 
//
//USED FOR THE PURPOSE OF MIMICKING USER DATA FROM BACKEND
//
//

import 'package:flutter/material.dart'; // Import for ValueNotifier

// Data class to represent the location
class Location {
  double latitude;
  double longitude;

  Location({
    required this.latitude,
    required this.longitude,
  });

  // Factory constructor to create a Location object from a JSON map
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: (json['latitude'] ?? 0.0).toDouble(), // Provide default values
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  // Method to convert the Location object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

// Data class to represent an activity
class Activity {
  String from;
  String to;
  String title;
  Location? location; // Made Location nullable
  String details;

  Activity({
    required this.from,
    required this.to,
    required this.title,
    this.location, // Location is optional
    required this.details,
  });

  // Factory constructor to create an Activity object from a JSON map
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      title: json['title'] ?? '',
      location: json['location'] != null
          ? Location.fromJson(json['location'])
          : null, // Handle null location
      details: json['details'] ?? '',
    );
  }

  // Method to convert the Activity object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'title': title,
      'location': location?.toJson(), // Use ?. to handle null
      'details': details,
    };
  }
}

// Data class to represent a day's itinerary
class Itinerary {
  String date;
  List<Activity> activities;

  Itinerary({
    required this.date,
    required this.activities,
  });

  // Factory constructor to create an Itinerary object from a JSON map
  factory Itinerary.fromJson(Map<String, dynamic> json) {
    //print("Parsing Itinerary: $json"); //debugging
    var activitiesList = json['activities'] as List? ?? []; //handles null
    //print("activitiesList: $activitiesList");
    return Itinerary(
      date: json['date'] ?? '',
      activities: activitiesList
          .map((activityJson) => Activity.fromJson(activityJson))
          .toList(),
    );
  }

    // Method to convert the Itinerary object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'activities': activities.map((activity) => activity.toJson()).toList(),
    };
  }
}

// Data class to represent a Trip
class Trip {
  String id; // Changed to String
  ValueNotifier<String> name; // Use ValueNotifier for updatable fields
  ValueNotifier<String?> dateFrom; // Made nullable
  ValueNotifier<String?> dateTo;    // Made nullable
  ValueNotifier<double> expensesUsed;
  ValueNotifier<double> expensesLimit;
  ValueNotifier<List<String>> items; //simplified
  ValueNotifier<List<String>> variableExpenses; //simplified
  ValueNotifier<List<String>> fixedExpenses;    //simplified
  Map<String, Itinerary> itineraries; // Changed to Map<String, Itinerary>

  Trip({
    required this.id,
    required this.name,
    required this.dateFrom,
    required this.dateTo,
    required this.expensesUsed,
    required this.expensesLimit,
    required this.items,
    required this.variableExpenses,
    required this.fixedExpenses,
    required this.itineraries,
  });

  // Factory constructor to create a Trip object from a JSON map
  factory Trip.fromJson(Map<String, dynamic> json) {
    //print("Parsing Trip: $json"); //debugging
    var itinerariesJson = json['itineraries'] as Map<String, dynamic>? ?? {};
    //print("itinerariesJson: $itinerariesJson");
    Map<String, Itinerary> parsedItineraries = {};

     itinerariesJson.forEach((key, value) {
        if (value != null) { //check for null
          parsedItineraries[key] = Itinerary.fromJson(value);
        }
    });
    return Trip(
      id: json['id'] ?? '', //keep as string
      name: ValueNotifier<String>(json['name'] ?? ''),
      dateFrom: ValueNotifier<String?>(json['dateFrom']), // Keep null as is
      dateTo: ValueNotifier<String?>(json['dateTo']),    // Keep null as is
      expensesUsed: ValueNotifier<double>(
          (json['expensesUsed'] ?? 0.0).toDouble()), // Provide default
      expensesLimit: ValueNotifier<double>(
          (json['expensesLimit'] ?? 0.0).toDouble()), // Provide default
      items: ValueNotifier<List<String>>(
          (json['items'] as List? ?? []).cast<String>()), // Provide default
      variableExpenses: ValueNotifier<List<String>>(
          (json['variableExpenses'] as List? ?? []).cast<String>()), //default
      fixedExpenses: ValueNotifier<List<String>>(
          (json['fixedExpenses'] as List? ?? []).cast<String>()),    //default
      itineraries: parsedItineraries,
    );
  }
    // Method to convert the Trip object to a JSON map
    Map<String, dynamic> toJson() {
    Map<String, dynamic> itinerariesJson = {};
    itineraries.forEach((key, value) {
      itinerariesJson[key] = value.toJson();
    });

    return {
      'id': id,
      'name': name.value,
      'dateFrom': dateFrom.value,
      'dateTo': dateTo.value,
      'expensesUsed': expensesUsed.value,
      'expensesLimit': expensesLimit.value,
      'items': items.value,
      'variableExpenses': variableExpenses.value,
      'fixedExpenses': fixedExpenses.value,
      'itineraries': itinerariesJson,
    };
  }
}

// Main data class to hold the list of trips
class TripData {
  // Use ValueNotifier to hold the list of trips.
  final trips = ValueNotifier<List<Trip>>([]);

  // Constructor. Initialize with an empty list.
  TripData() {
    trips.value = [];
  }

  // Method to add a new trip
  void addTrip(Trip trip) {
    trips.value = [...trips.value, trip]; //spread operator
    notifyListeners(); //important
  }

  // Method to update an existing trip
    void updateTrip(String tripId, Trip updatedTrip) {
    int index = trips.value.indexWhere((trip) => trip.id == tripId);
    if (index != -1) {
      trips.value[index] = updatedTrip; // Replace the entire trip
      notifyListeners();
    }
  }

  // Method to delete a trip
  void deleteTrip(String tripId) {
    trips.value = trips.value.where((trip) => trip.id != tripId).toList();
    notifyListeners();
  }

  // Method to get a trip by its ID
  Trip? getTripById(String tripId) {
    try{
      return trips.value.firstWhere((trip) => trip.id == tripId);
    } catch (e){
      return null;
    }
  }
  //method to notify listener
  void notifyListeners(){
    trips.notifyListeners();
  }
}