import 'dart:convert';

import 'package:apacsolchallenge/authenticationWindow.dart';
import 'package:apacsolchallenge/pages/add_expenses.dart';
import 'package:apacsolchallenge/pages/event_selection.dart';
import 'package:apacsolchallenge/pages/expenses.dart';
import 'package:apacsolchallenge/pages/general_question.dart';
import 'package:apacsolchallenge/pages/calendar.dart';
import 'package:apacsolchallenge/pages/map_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../data/global_trip_data.dart';
import '../data/trip_data.dart';
import 'package:apacsolchallenge/utilities/calendar_utils.dart';
import '../data/global_user.dart';
import 'package:http/http.dart' as http;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {



  DateTime today = DateTime.now();
  String username = UserSession().name;
  bool _showExpenses = false;
  late TripData tripData;

  @override
  void initState() {
    super.initState();
    tripData = GlobalTripData.instance.tripData;

    // Listen for changes and call setState
    tripData.trips.addListener(_onTripsChanged);
  }

  void _onTripsChanged() {
    setState(() {}); // Rebuild when trips update
  }

  @override
  void dispose() {
    tripData.trips.removeListener(_onTripsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trips = tripData.trips.value;
    final today = DateTime.now();
    final closestTrip = _findClosestTrip(trips, today);
    print("Trips length: ${tripData.trips.value.length}");

    if (trips.isEmpty || closestTrip == null) {
      return _buildNoTripsAvailableView(context);
    }

    final isInFuture = _isTripInFuture(closestTrip, today);
    final isTomorrow = _isTripTomorrow(closestTrip, today);
    final relevantInFuture = _getRelevantInFuture(closestTrip, today);

    if (isInFuture) {
      return _buildInTheFutureContent(context, closestTrip, relevantInFuture);
    }

    if (isTomorrow) {
      return _buildTomorrowContent(context, closestTrip, relevantInFuture);
    }

    final relevantToday = _getRelevantActivities(closestTrip, today);
    return _buildCompleteContent(context, closestTrip, today, relevantToday);
  }

  String _getGreeting() {
    if (today.hour < 12) {
      return 'Good morning, $username';
    } else if (today.hour < 18) {
      return 'Good afternoon, $username';
    } else {
      return 'Good evening, $username';
    }
  }

  Trip? _findClosestTrip(List<Trip> trips, DateTime today) {
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
        final tripDateNormalized =
            DateTime(tripDate.year, tripDate.month, tripDate.day);

        final dateTo = trip.dateTo.value;
        final DateTime? tripEndDate =
            dateTo != null ? DateTime.parse(dateTo) : null;

        bool isOngoing = false;
        if (tripEndDate != null) {
          final tripEndNormalized =
              DateTime(tripEndDate.year, tripEndDate.month, tripEndDate.day);
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
          closestDuration =
              Duration.zero; // Set to zero to give highest priority
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

  List<Activity> _getRelevantActivities(Trip closestTrip, DateTime today) {
    // Format today as a string in the same format as stored in the itinerary dates
    final todayString =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

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

    // Sort activities by start time to ensure proper ordering
    final sortedActivities = List<Activity>.from(todaysItinerary.activities);
    sortedActivities.sort((a, b) {
      final aStartMinutes = _timeToMinutes(parseTime(a.from));
      final bStartMinutes = _timeToMinutes(parseTime(b.from));
      return aStartMinutes.compareTo(bStartMinutes);
    });

    // Find upcoming and ongoing activities
    final List<Activity> relevantActivities = [];
    Activity? lastCompletedActivity;
    Activity? nextUpcomingActivity;

    // First pass: Find ongoing, upcoming, and the most recent completed activity
    for (int i = 0; i < sortedActivities.length; i++) {
      final activity = sortedActivities[i];
      final activityStartTime = parseTime(activity.from);
      final activityEndTime = parseTime(activity.to);

      final activityStartMinutes = _timeToMinutes(activityStartTime);
      final activityEndMinutes = _timeToMinutes(activityEndTime);

      final isUpcoming = activityStartMinutes > currentHourMinutes;
      final isOngoing = activityStartMinutes <= currentHourMinutes &&
          activityEndMinutes >= currentHourMinutes;
      final isCompleted = activityEndMinutes < currentHourMinutes;

      if (isOngoing) {
        // Current activity is ongoing - add it
        relevantActivities.add(activity);
      } else if (isUpcoming) {
        // Activity is upcoming - if it's the first upcoming one, note it
        if (nextUpcomingActivity == null) {
          nextUpcomingActivity = activity;
        }
      } else if (isCompleted) {
        // Keep track of the last completed activity
        lastCompletedActivity = activity;
      }
    }

    // Second pass: Add the upcoming activities
    bool addedFirstUpcoming = false;
    for (final activity in sortedActivities) {
      final activityStartMinutes = _timeToMinutes(parseTime(activity.from));

      if (activityStartMinutes > currentHourMinutes) {
        // Only add upcoming activities
        relevantActivities.add(activity);

        // If this is the first upcoming activity and there's a gap with the previous activity,
        // add the last completed activity as the origin point
        if (!addedFirstUpcoming &&
            lastCompletedActivity != null &&
            nextUpcomingActivity == activity) {
          // Check if there's a significant gap between last completed and next upcoming
          final lastCompletedEndMinutes =
              _timeToMinutes(parseTime(lastCompletedActivity.to));
          final nextUpcomingStartMinutes =
              _timeToMinutes(parseTime(nextUpcomingActivity!.from));

          // If there's more than a 5-minute gap, include the last completed activity
          if (nextUpcomingStartMinutes - lastCompletedEndMinutes > 5 &&
              !relevantActivities.contains(lastCompletedActivity)) {
            relevantActivities.insert(0, lastCompletedActivity);
          }
        }

        addedFirstUpcoming = true;
      }
    }

    // If there's no ongoing or upcoming activity but there is a completed one,
    // include the last completed activity as it might be the user's current location
    if (relevantActivities.isEmpty && lastCompletedActivity != null) {
      relevantActivities.add(lastCompletedActivity);
    }

    return relevantActivities;
  }

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  List<Activity> _getRelevantInFuture(Trip closestTrip, DateTime today) {
    List<Activity> relevantActivities = [];
    for (var itinerary in closestTrip.itineraries.values) {
      try {
        DateTime itineraryDate = DateTime.parse(itinerary.date);
        if (itineraryDate.isAfter(today)) {
          relevantActivities.addAll(itinerary.activities);
        }
      } catch (e) {
        print("Error parsing itinerary date: $e");
      }
    }
    return relevantActivities;
  }

  TimeOfDay parseTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 2) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  bool _isTripInFuture(Trip trip, DateTime today) {
    final dateFrom = trip.dateFrom.value;
    if (dateFrom == null) {
      return false;
    }

    // Parse the trip start date
    final tripStartDate = DateTime.parse(dateFrom);

    // Create a DateTime for the start of today (midnight)
    final startOfToday = DateTime(today.year, today.month, today.day);

    // Create a DateTime for the start of the day that's two days from now
    final startOfTwoDaysFromNow = startOfToday.add(const Duration(days: 2));

    // Return true if trip starts on or after two days from now
    return tripStartDate.isAfter(startOfTwoDaysFromNow) ||
        CalendarUtils.isSameDay(tripStartDate, startOfTwoDaysFromNow);
  }

  bool _isTripTomorrow(Trip trip, DateTime today) {
    final dateFrom = trip.dateFrom.value;
    if (dateFrom == null) {
      return false;
    }

    final tripStartDate = DateTime.parse(dateFrom);
    final tomorrow = today.add(const Duration(days: 1));
    return tripStartDate.year == tomorrow.year &&
        tripStartDate.month == tomorrow.month &&
        tripStartDate.day == tomorrow.day;
  }

  Activity? _getLastActivityFromPreviousDay(Trip trip, DateTime today) {
    DateTime yesterday = today.subtract(const Duration(days: 1));
    List<Itinerary> previousDayActivities = trip.itineraries.values.where((itinerary) {
      return CalendarUtils.isSameDay(DateTime.parse(itinerary.date), yesterday);
    }).toList();

    if (previousDayActivities.isEmpty) return null;

    print(previousDayActivities[0].activities.last.title);
    return previousDayActivities[0].activities.last;
  }

  Widget _buildEstimatedTime(
      List<Activity> relevantActivities, Activity? lastActivityFromPreviousDay) {
    Activity? fromActivity;
    Activity? toActivity;
    String statusMessage = "";
    bool isFirstTripOfDay = false;

    final currentTime = TimeOfDay.now();
    final currentHourMinutes = currentTime.hour * 60 + currentTime.minute;

    // Debug info
    print("Current time in minutes: $currentHourMinutes");
    print("Relevant activities count: ${relevantActivities.length}");
    if (relevantActivities.isNotEmpty) {
      print(
          "First activity: ${relevantActivities[0].title} at ${relevantActivities[0].from}");
    }
    if (lastActivityFromPreviousDay != null) {
      print(
          "Last activity from previous day: ${lastActivityFromPreviousDay.title}");
    }

    // Case 1: No activities today
    if (relevantActivities.isEmpty) {
      fromActivity = lastActivityFromPreviousDay;
      toActivity = null;
      statusMessage = "No where to go";
      print("Case 1: No activities today - $statusMessage");
    }
    // Case 2: One activity today
    else if (relevantActivities.length == 1) {
      final activity = relevantActivities[0];
      final activityStartMinutes =
      _timeToMinutes(parseTime(activity.from));

      if (activityStartMinutes > currentHourMinutes) {
        // The activity is in the future - first trip of the day
        if (lastActivityFromPreviousDay != null) {
          fromActivity = lastActivityFromPreviousDay;
          toActivity = activity;
          isFirstTripOfDay = true;
          print(
              "Case 2A: One future activity. fromActivity = ${fromActivity.title}, toActivity = ${toActivity.title}");
        } else {
          // Missing origin point
          fromActivity = null;
          toActivity = activity;
          statusMessage = "Cannot generate route";
          print(
              "Case 2B: One future activity but no previous day activity - $statusMessage");
        }
      } else {
        // The activity is in the past or ongoing - nowhere to go next
        fromActivity = activity;
        toActivity = null;
        statusMessage = "No where to go";
        print("Case 2C: One past/ongoing activity - $statusMessage");
      }
    }
    // Case 3: Multiple activities today
    else {
      final firstActivity = relevantActivities[0];
      final firstActivityStartMinutes =
      _timeToMinutes(parseTime(firstActivity.from));

      if (firstActivityStartMinutes > currentHourMinutes) {
        // The first activity is in the future - first trip of the day
        if (lastActivityFromPreviousDay != null) {
          fromActivity = lastActivityFromPreviousDay;
          toActivity = firstActivity;
          isFirstTripOfDay = true;
          print(
              "Case 3A: First activity is future. fromActivity = ${fromActivity.title}, toActivity = ${toActivity.title}");
        } else {
          // Missing origin point
          fromActivity = null;
          toActivity = firstActivity;
          statusMessage = "Cannot generate route";
          print(
              "Case 3B: First activity is future but no previous day activity - $statusMessage");
        }
      } else {
        // Current time is after or during first activity

        // Find the current or most recent activity
        int currentActivityIndex = 0;
        for (int i = 0; i < relevantActivities.length; i++) {
          final activity = relevantActivities[i];
          final startMinutes = _timeToMinutes(parseTime(activity.from));

          if (startMinutes <= currentHourMinutes) {
            currentActivityIndex = i;
          } else {
            break;
          }
        }

        fromActivity = relevantActivities[currentActivityIndex];

        // Check if there's a next activity
        if (currentActivityIndex + 1 < relevantActivities.length) {
          toActivity = relevantActivities[currentActivityIndex + 1];
          print(
              "Case 3C: Between activities. fromActivity = ${fromActivity.title}, toActivity = ${toActivity.title}");
        } else {
          // No next activity - last activity of the day
          toActivity = null;
          statusMessage = "No where to go";
          print("Case 3D: After last activity - $statusMessage");
        }
      }
    }

    // Final check based on main premise
    if (toActivity?.location == null) {
      statusMessage = "No where to go";
    } else if (fromActivity?.location == null) {
      statusMessage = "Cannot generate route";
    }

    // Determine display titles
    final String fromTitle = lastActivityFromPreviousDay == null && isFirstTripOfDay
        ? "Home"
        : (fromActivity?.title ?? "No starting location");
    final String toTitle = toActivity?.title ?? "No next location";

    print("Final fromActivity: ${fromActivity?.title}");
    print("Final toActivity: ${toActivity?.title}");
    print("isFirstTripOfDay: $isFirstTripOfDay");
    print("statusMessage: $statusMessage");

    // Get estimated time if possible
    String? estimatedTime;
    if (statusMessage.isEmpty && fromActivity?.location != null && toActivity?.location != null) {
      // Since we can't directly use async in a build method, we'll use FutureBuilder
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recommended route",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("From:",
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(fromTitle,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const Text("To:",
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(toTitle,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const Text("Estimation:",
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                        fontSize: 14)),
                const SizedBox(height: 4),
                FutureBuilder<String?>(
                  future: getEstimatedTime(fromActivity!, toActivity!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Calculating travel time...",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    } else if (snapshot.hasData && snapshot.data != null) {
                      return Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            snapshot.data!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return const Text(
                        "Could not estimate travel time",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Use regular display with status message
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recommended route",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("From:",
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(fromTitle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  const Text("To:",
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(toTitle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  const Text("Estimation:",
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    statusMessage.isNotEmpty
                        ? statusMessage
                        : (fromActivity?.location != null && toActivity?.location != null
                        ? ""
                        : "No route available or location is not given"),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
          );
    }
  }

  Widget _buildNoTripsAvailableView(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_getGreeting()),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications),
            ),
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                icon: const Icon(Icons.menu),
              ),
            ),
          ],
        ),
        endDrawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text(
                  'Settings',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Change Name'),
                onTap: () => _changeName(context),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),

        body: const Center(child: Text('No trips available. Add a new trip!')),
        bottomNavigationBar: _buildBottomNavigationBar(context));
  }

  Widget _buildEventItem(Activity event) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('${event.from} - ${event.to}')),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(event.locationDetail!=null || event.locationDetail!='' ?
                "Location details: ${event.locationDetail}" : "No location detail available")
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryFuture(
      Trip closestTrip, List<Activity> relevantInFuture) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Upcoming itinerary",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return Calendar(tripId: closestTrip.id);
                    }));
                  },
                  icon: const Icon(Icons.settings))
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    DateFormat('MMMM dd, yyyy').format(DateTime.parse(
                        closestTrip.dateFrom.value!)), //show full date
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // Display a maximum of 3 events.
                Column(
                  children: <Widget>[
                    if (relevantInFuture.isNotEmpty)
                      ...relevantInFuture
                          .take(3)
                          .map((event) => _buildEventItem(event))
                    else
                      const SizedBox(
                        width: double.infinity,
                        child: Text(
                          "No activities for this trip!",
                          textAlign: TextAlign.center,
                        ),
                      )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildItineraryTomorrow(
      Trip closestTrip, List<Activity> relevantInFuture) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Upcoming tomorrow",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return Calendar(tripId: closestTrip.id);
                    }));
                  },
                  icon: const Icon(Icons.settings))
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    DateFormat('MMMM dd, yyyy').format(DateTime.parse(
                        closestTrip.dateFrom.value!)), //show full date
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // Display a maximum of 3 events.
                Column(
                  children: <Widget>[
                    if (relevantInFuture.isNotEmpty)
                      ...relevantInFuture
                          .take(3)
                          .map((event) => _buildEventItem(event))
                    else
                      const SizedBox(
                        width: double.infinity,
                        child: Text(
                          "No activities for this trip!",
                          textAlign: TextAlign.center,
                        ),
                      )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTomorrowLocation(List<Activity> relevantTomorrow){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upcoming location",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("First stop",
                style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                      fontSize: 14)
              ),
              const SizedBox(height: 2),
              Text(relevantTomorrow[0].title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
              const SizedBox(height: 2),
              Text("${relevantTomorrow[0].location?.latitude} : ${relevantTomorrow[0].location?.longitude}"),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildRecommendedRoute(
    List<Activity> relevantActivities, Activity? lastActivityFromPreviousDay) {
    Activity? fromActivity;
    Activity? toActivity;
    String statusMessage = "";
    bool isFirstTripOfDay = false;
    bool showButton =
        false; // Start with false, only enable under certain conditions.

    final currentTime = TimeOfDay.now();
    final currentHourMinutes = currentTime.hour * 60 + currentTime.minute;

    // Debug info
    print("Current time in minutes: $currentHourMinutes");
    print("Relevant activities count: ${relevantActivities.length}");
    if (relevantActivities.isNotEmpty) {
      print(
          "First activity: ${relevantActivities[0].title} at ${relevantActivities[0].from}");
    }
    if (lastActivityFromPreviousDay != null) {
      print(
          "Last activity from previous day: ${lastActivityFromPreviousDay.title}");
    }

    // Case 1: No activities today
    if (relevantActivities.isEmpty) {
      fromActivity = lastActivityFromPreviousDay;
      toActivity = null;
      statusMessage = "No where to go";
      print("Case 1: No activities today - $statusMessage");
    }
    // Case 2: One activity today
    else if (relevantActivities.length == 1) {
      final activity = relevantActivities[0];
      final activityStartMinutes =
          _timeToMinutes(parseTime(activity.from));

      if (activityStartMinutes > currentHourMinutes) {
        // The activity is in the future - first trip of the day
        if (lastActivityFromPreviousDay != null) {
          fromActivity = lastActivityFromPreviousDay;
          toActivity = activity;
          isFirstTripOfDay = true;
          showButton = true; // Show button in this specific case
          print(
              "Case 2A: One future activity. fromActivity = ${fromActivity.title}, toActivity = ${toActivity.title}");
        } else {
          // Missing origin point
          fromActivity = null;
          toActivity = activity;
          statusMessage = "Cannot generate route";
          print(
              "Case 2B: One future activity but no previous day activity - $statusMessage");
        }
      } else {
        // The activity is in the past or ongoing - nowhere to go next
        fromActivity = activity;
        toActivity = null;
        statusMessage = "No where to go";
        print("Case 2C: One past/ongoing activity - $statusMessage");
      }
    }
    // Case 3: Multiple activities today
    else {
      final firstActivity = relevantActivities[0];
      final firstActivityStartMinutes =
          _timeToMinutes(parseTime(firstActivity.from));

      if (firstActivityStartMinutes > currentHourMinutes) {
        // The first activity is in the future - first trip of the day
        if (lastActivityFromPreviousDay != null) {
          fromActivity = lastActivityFromPreviousDay;
          toActivity = firstActivity;
          isFirstTripOfDay = true;
          showButton = true; //show button
          print(
              "Case 3A: First activity is future. fromActivity = ${fromActivity.title}, toActivity = ${toActivity.title}");
        } else {
          // Missing origin point
          fromActivity = null;
          toActivity = firstActivity;
          statusMessage = "Cannot generate route";
          print(
              "Case 3B: First activity is future but no previous day activity - $statusMessage");
        }
      } else {
        // Current time is after or during first activity

        // Find the current or most recent activity
        int currentActivityIndex = 0;
        for (int i = 0; i < relevantActivities.length; i++) {
          final activity = relevantActivities[i];
          final startMinutes = _timeToMinutes(parseTime(activity.from));

          if (startMinutes <= currentHourMinutes) {
            currentActivityIndex = i;
          } else {
            break;
          }
        }

        fromActivity = relevantActivities[currentActivityIndex];

        // Check if there's a next activity
        if (currentActivityIndex + 1 < relevantActivities.length) {
          toActivity = relevantActivities[currentActivityIndex + 1];
          showButton = true; //show button
          print(
              "Case 3C: Between activities. fromActivity = ${fromActivity.title}, toActivity = ${toActivity.title}");
        } else {
          // No next activity - last activity of the day
          toActivity = null;
          statusMessage = "No where to go";
          print("Case 3D: After last activity - $statusMessage");
        }
      }
    }

    // Final check based on main premise
    if (toActivity == null) {
      statusMessage = "No where to go";
      showButton = false;
    } else if (fromActivity == null) {
      statusMessage = "Cannot generate route";
      showButton = false;
    }

    // Determine display titles
    final String fromTitle = lastActivityFromPreviousDay == null && isFirstTripOfDay
        ? "Home"
        : (fromActivity?.title ?? "No starting location");
    final String toTitle = toActivity?.title ?? "No next location";

    print("Final fromActivity: ${fromActivity?.title}");
    print("Final toActivity: ${toActivity?.title}");
    print("isFirstTripOfDay: $isFirstTripOfDay");
    print("showButton: $showButton");
    print("statusMessage: $statusMessage");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Ensure left alignment
      children: [
        const Text(
          "Recommended route",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity, // Make container full-width
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Ensure left alignment within container
            children: [
              const Text("From:",
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text(fromTitle,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const Text("To:",
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text(toTitle,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const Text("Estimation:",
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                statusMessage.isNotEmpty
                    ? statusMessage
                    : (fromActivity != null && toActivity != null
                        ? "Estimated time"
                        : "No route available"),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              if (showButton)
                SizedBox(
                  width: double.infinity, // Make button full-width
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return MapPage(
                          fromActivity: fromActivity!,
                          toActivity: toActivity!,
                        );
                      }));
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Best route",
                        style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesNotComplete(Trip closestTrip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Expenses", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8)
          ),
          child: ValueListenableBuilder<double>( // Wrap the part that depends on expensesLimit
            valueListenable: closestTrip.expensesLimit, // Listen to changes in expensesLimit
            builder: (context, expensesLimitValue, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("IDR", style: TextStyle(fontWeight: FontWeight.bold),),
                      ValueListenableBuilder<double>( //listen to expensesUsed
                        valueListenable: closestTrip.expensesUsed,
                        builder: (context, expensesUsedValue, child){
                         return Text(
                            "${_showExpenses ? expensesUsedValue.toStringAsFixed(2) : "*****"} / ${expensesLimitValue.toStringAsFixed(2)}",
                            style: TextStyle(color: expensesUsedValue > expensesLimitValue ? Colors.red : Colors.black)
                          );
                        }
                      ),
                      IconButton(onPressed: () {
                        setState(() {
                          _showExpenses = !_showExpenses;
                        });
                      }, icon: Icon(_showExpenses ? Icons.visibility : Icons.visibility_off))
                    ],
                  ),
                ],
              );
            }
          ),
        )
      ],
    );
  }

  Widget _buildExpensesComplete(Trip closestTrip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Expenses", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8)
          ),
          child: ValueListenableBuilder<double>( // Wrap the part that depends on expensesLimit
            valueListenable: closestTrip.expensesLimit, // Listen to changes in expensesLimit
            builder: (context, expensesLimitValue, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("IDR", style: TextStyle(fontWeight: FontWeight.bold),),
                      ValueListenableBuilder<double>( //listen to expensesUsed
                        valueListenable: closestTrip.expensesUsed,
                        builder: (context, expensesUsedValue, child){
                         return Text(
                            "${_showExpenses ? expensesUsedValue.toStringAsFixed(2) : "*****"} / ${expensesLimitValue.toStringAsFixed(2)}",
                            style: TextStyle(color: expensesUsedValue > expensesLimitValue ? Colors.red : Colors.black)
                          );
                        }
                      ),
                      IconButton(onPressed: () {
                        setState(() {
                          _showExpenses = !_showExpenses;
                        });
                      }, icon: Icon(_showExpenses ? Icons.visibility : Icons.visibility_off))
                    ],
                  ),
                  const SizedBox(width: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                    ElevatedButton(onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context){
                        return AddExpenses(tripId: closestTrip.id);
                      }));
                    }, child: const Text('Add Expenses')),
                    ElevatedButton(onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context){
                        return Expenses(trip: closestTrip);
                      }));
                    }, child: const Text('Expenses Page'))
                    ]
                  )
                ],
              );
            }
          ),
        )
      ],
    );
  }


  Future<String?> getEstimatedTime(Activity fromActivity, Activity toActivity) async {
    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      if (apiKey == null || apiKey.isEmpty){
        return null;
      }

      final origin = "${fromActivity.location!.latitude},${fromActivity.location!.longitude}";
      final destination = "${toActivity.location!.latitude},${toActivity.location!.longitude}";

      final url = Uri.parse('https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200){
        final data = json.decode(response.body);

        if (data['status'] == 'OK'){
          final duration = data['routes'][0]['legs'][0]['duration']['text'];
          return duration;
        } else {
          print('Directions API error: ${data['status']}');
          return null;
        }
      } else {
        print('Failed to fetch directions data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting estimated time: $e');
      return null;
    }
  }
  Widget _buildItineraryComplete(
      Trip closestTrip, DateTime today, List<Activity> relevantActivities) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Ongoing itinerary",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return Calendar(tripId: closestTrip.id);
                    }));
                  },
                  icon: const Icon(Icons.settings))
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('MMMM dd, yyyy').format(today), //show full date
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // Display a maximum of 3 events in a day.
                Column(
                  children: <Widget>[
                    if (relevantActivities.isNotEmpty)
                      ...relevantActivities
                          .take(3)
                          .map((event) => _buildEventItem(event))
                    else
                      const SizedBox(
                        width: double.infinity,
                        child: Text(
                          "No more activities for today!",
                          textAlign: TextAlign.center,
                        ),
                      )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInTheFutureContent(
      BuildContext context, Trip closestTrip, List<Activity> relevantInFuture) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getGreeting()),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications)),
          IconButton(onPressed: () => Scaffold.of(context).openEndDrawer(), icon: const Icon(Icons.menu))
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Settings', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Change Name'),
              onTap: () => _changeName(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildItineraryFuture(closestTrip, relevantInFuture),
              const SizedBox(height: 16),
              _buildExpensesNotComplete(closestTrip)
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildTomorrowContent(
      BuildContext context, Trip closestTrip, List<Activity> relevantTomorrow) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getGreeting()),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
          ),
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              icon: const Icon(Icons.menu),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Settings',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Change Name'),
              onTap: () => _changeName(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildItineraryTomorrow(closestTrip, relevantTomorrow),
              const SizedBox(height: 16),
              _buildTomorrowLocation(relevantTomorrow),
              const SizedBox(height: 16),
              _buildExpensesNotComplete(closestTrip)
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  void _changeName(BuildContext context) {
    final TextEditingController _nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Name'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Enter new name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newName = _nameController.text.trim();
                if (newName.isNotEmpty) {
                  // Do something with the new name (e.g. update state or backend)
                  final res = await http.post(
                    Uri.parse('https://backend-server-412321340776.us-west1.run.app/user/rename'),
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: jsonEncode(<String, String>{
                      'userId': UserSession.instance.uid,
                      'username': newName}),
                    );
                  if (res.statusCode == 200) {
                    UserSession.instance.name = newName;
                    setState(() {
                      username = newName;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Name changed to "$newName"')),
                    );
                    Navigator.of(context).pop(); // Close dialog
                  }

                }

              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _logout(BuildContext context) async {
    // Your logic to logout
    await FirebaseAuth.instance.signOut();
    UserSession.instance.uid = '';
    UserSession.instance.name='';
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthenticationWindow()),
    );
  }

  Widget _buildCompleteContent(BuildContext context, Trip closestTrip,
      DateTime today, List<Activity> relevantActivities) {
    Activity? lastActivityFromPreviousDay;

    if (relevantActivities.isNotEmpty) {
      final currentTime = TimeOfDay.fromDateTime(today);
      final currentHourMinutes = currentTime.hour * 60 + currentTime.minute;

      final firstActivity = relevantActivities[0];
      final firstActivityStartMinutes = _timeToMinutes(parseTime(firstActivity.from));

      if (firstActivityStartMinutes > currentHourMinutes) {
        lastActivityFromPreviousDay = _getLastActivityFromPreviousDay(closestTrip, today);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getGreeting()),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
          ),
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              icon: const Icon(Icons.menu),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Settings',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Change Name'),
              onTap: () => _changeName(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: [
                _buildItineraryComplete(closestTrip, today, relevantActivities),
                const SizedBox(height: 16),
                _buildEstimatedTime(relevantActivities, lastActivityFromPreviousDay),
                const SizedBox(height: 16),
                _buildExpensesComplete(closestTrip)
              ]))),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        // Added const here
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
        // 0: Home, 1: Add Trip, 2: See Trips
        switch (index) {
          case 1:
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => GeneralQuestion()));
            break;
          case 2: // 'See Trips'
            // *IMPORTANT*:  Use push instead of pushReplacement.
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => EventSelection()));
            break;
          case 0:
            break;
          default:
            break;
        }
      },
    );
  }
}