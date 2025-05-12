import 'package:apacsolchallenge/pages/event_selection.dart';
import 'package:apacsolchallenge/pages/general_question.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/global_trip_data.dart'; // Import for GlobalTripData
import '../data/trip_data.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final tripData = GlobalTripData.instance.tripData; // Access the global TripData instance
  DateTime today = DateTime.now();
  String username = "User";

  @override
  Widget build(BuildContext context) {
    final closestTrip = _findClosestTrip(tripData.trips.value, today);

    if (tripData.trips.value.isEmpty || closestTrip == null){
      return _buildNoTripsAvailableView(context);
    } 
    final isTomorrow = _isTripTomorrow(closestTrip, today);
    final isOngoing = _isTripOngoing(closestTrip, today);

    List<Activity> relevantActivities = _getRelevantActivities(closestTrip, today);
    return _buildMainContent(context, closestTrip, today, relevantActivities);
  }

  String _getGreeting(){
    if(today.hour < 12){
      return 'Good morning, $username';
    }
    else if (today.hour < 18){
      return 'Good afternoon, $username';
    }
    else{
      return 'Good evening, $username';
    }
  }

  Trip? _findClosestTrip(List<Trip> trips, DateTime today){
    if (trips.isEmpty) {
      return null;
    }
  
    Trip? closestTrip;
    Duration? closestDuration;
  
    final todayNormalized = DateTime(today.year, today.month, today.day);
  
    for (final trip in trips) {
      final dateFrom = trip.dateFrom.value;
      if (dateFrom == null) {
        continue;
      }
    
    try {
      final tripDate = DateTime.parse(dateFrom);
      final tripDateNormalized = DateTime(tripDate.year, tripDate.month, tripDate.day);
      
      final dateTo = trip.dateTo.value;
      final DateTime? tripEndDate = dateTo != null ? DateTime.parse(dateTo) : null;
      
      bool isOngoing = false;
      if (tripEndDate != null) {
        final tripEndNormalized = DateTime(tripEndDate.year, tripEndDate.month, tripEndDate.day);
        isOngoing = (todayNormalized.isAtSameMomentAs(tripDateNormalized) || 
                    todayNormalized.isAfter(tripDateNormalized)) &&
                   (todayNormalized.isAtSameMomentAs(tripEndNormalized) || 
                    todayNormalized.isBefore(tripEndNormalized));
      } else {
        isOngoing = todayNormalized.isAtSameMomentAs(tripDateNormalized) || 
                   todayNormalized.isAfter(tripDateNormalized);
      }

      bool isFuture = tripDateNormalized.isAfter(todayNormalized);

      if (isOngoing) {
        closestTrip = trip;
        closestDuration = Duration.zero; // Set to zero to give highest priority
        break; // Stop searching if we find an ongoing trip
      }
    
      if (isFuture) {
        final duration = tripDateNormalized.difference(todayNormalized);
        
        if (closestTrip == null) {
          closestTrip = trip;
          closestDuration = duration;
        } else if (closestDuration != null && duration < closestDuration) {
          closestTrip = trip;
          closestDuration = duration;
        }
      }
    } catch (e) {
        print("Error parsing date for trip ${trip.name.value}: $e");
      }
    }

    return closestTrip;
  }

  List<Activity> _getRelevantActivities(Trip closestTrip, DateTime today){
    // Format today as a string in the same format as stored in the itinerary dates
    final todayString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    // Find today's itinerary
    Itinerary? todaysItinerary;
    for (final entry in closestTrip.itineraries.entries) {
      final itinerary = entry.value;
      
      // Try both formatted and direct comparison
      if (itinerary.date == todayString) {
        todaysItinerary = itinerary;
        break;
      }
      
      // Try parsing the date and comparing year, month, day
      try {
        final itineraryDate = DateTime.parse(itinerary.date);
        final todayDate = DateTime(today.year, today.month, today.day);
        
        if (itineraryDate.year == todayDate.year && 
            itineraryDate.month == todayDate.month && 
            itineraryDate.day == todayDate.day) {
          todaysItinerary = itinerary;
          break;
        }
      } catch (e) {
        print("Error parsing date: $e");
      }
    }
    
    if (todaysItinerary == null) {
      return [];
    }
    
    // Get the current time for filtering activities
    final currentTime = TimeOfDay.fromDateTime(today);
    final currentHourMinutes = currentTime.hour * 60 + currentTime.minute;
    
    // Find activities that haven't started yet or are ongoing
    final relevantActivities = todaysItinerary.activities.where((activity) {
      final activityStartTime = parseTime(activity.from);
      final activityEndTime = parseTime(activity.to);
      
      final activityStartMinutes = activityStartTime.hour * 60 + activityStartTime.minute;
      final activityEndMinutes = activityEndTime.hour * 60 + activityEndTime.minute;
      
      // An activity is relevant if:
      // 1. It starts now or in the future, OR
      // 2. It's ongoing (started before now but ends after now)
      final isUpcoming = activityStartMinutes >= currentHourMinutes;
      final isOngoing = activityStartMinutes < currentHourMinutes && activityEndMinutes > currentHourMinutes;
      final isRelevant = isUpcoming || isOngoing;
          
      return isRelevant;
    }).toList();
    
    return relevantActivities;
  }

  TimeOfDay parseTime(String timeString){
    final parts = timeString.split(':');
    if (parts.length != 2){
      return const TimeOfDay(hour: 0, minute: 0);
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null){
      return const TimeOfDay(hour: 0, minute: 0);
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  bool _isTripTomorrow(Trip trip, DateTime today){
    final dateFrom = trip.dateFrom.value;
    if (dateFrom == null){
      return false;
    }

    final tripStartDate = DateTime.parse(dateFrom);
    final tomorrow = today.add(const Duration(days: 1));
    return tripStartDate.year == tomorrow.year && tripStartDate.month == tomorrow.month && tripStartDate.day == tomorrow.day;
  }

  bool _isTripOngoing(Trip trip, DateTime today){
    final dateFrom = trip.dateFrom.value;
    if (dateFrom == null){
      return false;
    }
    final tripStartDate = DateTime.parse(dateFrom);
    return today.isAtSameMomentAs(tripStartDate) || today.isAfter(tripStartDate);
  }

  Widget _buildNoTripsAvailableView(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text(_getGreeting())),
      body: Center(
        child: Text('No trips available. Add a new trip!')
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context)
    );
  }

  Widget _buildEventItem(Activity event){
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('${event.from} - ${event.to}')
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(fontWeight: FontWeight.bold)
                ),
                Text("Location details: Need GMaps API")
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: Icon(Icons.chevron_right))
        ],
      ),
    );
  }

  Widget _buildItinerarySection(Trip closestTrip, DateTime today, List<Activity> relevantActivities){
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Ongoing itinerary", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () {}, icon: Icon(Icons.settings))
            ],
          ),
          SizedBox(height: 6),
          Container(
            padding: EdgeInsets.all(12),
            decoration:BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM dd, yyyy').format(today),
                  style: TextStyle(fontWeight: FontWeight.bold)
                ),
                SizedBox(height: 10),
                // Display a maximum of 3 events in a day.
                ...relevantActivities.take(3).map((event) => _buildEventItem(event)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, Trip closestTrip, DateTime today, List<Activity> relevantActivities){
      return Scaffold(
      appBar: AppBar(
        title: Text(_getGreeting()),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.notifications)),
          IconButton(onPressed: () {}, icon: Icon(Icons.menu))
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildItinerarySection(closestTrip, today, relevantActivities)
            ]
          )
        )
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
}


Widget _buildBottomNavigationBar(BuildContext context) {
  return BottomNavigationBar(
    items: <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.add),
        label: 'Add Trip',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today),
        label: 'See Trips',
      ),
    ],
    currentIndex: 0,
    onTap: (index) {
      if (index == 1) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
          return GeneralQuestion();
        }));
      }
      else if (index == 2) {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return EventSelection();
        }));
      } 
    },
  );
}