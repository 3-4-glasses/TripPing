import 'package:apacsolchallenge/data/global_trip_data.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:apacsolchallenge/pages/calendar_edit.dart';
import 'package:apacsolchallenge/pages/reminders.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:apacsolchallenge/utilities/calendar_utils.dart';
import '../data/trip_data.dart';

class Calendar extends StatefulWidget {
  final String tripId;
  const Calendar({super.key, required this.tripId});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  List<Event> _events = [];
  List<Event> _selectedEvents = [];
  late Trip _trip;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _loadTripData();
  }

  void _loadTripData(){
    final globalTripData = GlobalTripData.instance;
    _trip = globalTripData.tripData.trips.value.firstWhere((trip) => trip.id == widget.tripId);
    _events.clear();
    _events.addAll(_getEventsFromTrip(_trip));

    if (_selectedDay != null){
      _selectedEvents = CalendarUtils.getEventsForDay(_events, _selectedDay!);
    }

    setState(() {
      
    });
  }

  List<Event> _getEventsFromTrip(Trip trip){
    List<Event> allEvents = [];

    for (var itinerary in trip.itineraries.values){
      DateTime itineraryDate = DateTime.parse(itinerary.date);
      for (var activity in itinerary.activities){
        TimeOfDay startTime = parseTimeOfDay(activity.from);
        TimeOfDay endTime = parseTimeOfDay(activity.to);

        DateTime startDate = itineraryDate;
        DateTime endDate = itineraryDate;

        if (startTime.hour > endTime.hour || (startTime.hour == endTime.hour && startTime.minute > endTime.minute)){
          endDate = endDate.add(const Duration(days: 1));
        }
        
        bool isMultiDay = startDate != endDate;

        allEvents.add(
          Event(
            startDate: startDate,
            endDate: endDate,
            timeStart: startTime,
            timeEnd: endTime,
            title: activity.title,
            notes: activity.details,
            isMultiDay: isMultiDay
          )
        );
      }
    }
    return allEvents;
  }

  TimeOfDay parseTimeOfDay(String timeString){
    List<String> parts = timeString.split(":");
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _handleEditResult(List<Event>? updatedEvents) {
    // Triggered after user comes back from the CalendarEditMode page.

    // Checks whether there are new events added.
    if (updatedEvents != null) {
      setState(() {
        _events = updatedEvents;
        _selectedEvents = CalendarUtils.getEventsForDay(_events, _selectedDay ?? _focusedDay);
        _updateTripItineraries(updatedEvents);
        GlobalTripData.instance.notifyListeners();
      });
    } else {
      _loadTripData();
    }
  }

  void _updateTripItineraries(List<Event> updatedEvents){
    Map<String, Itinerary> existingItineraries = Map.from(_trip.itineraries); 
    _trip.itineraries.clear(); // Clear existing itineraries at the beginning

    final groupedEvents = groupBy(updatedEvents, (Event event) => event.startDate);

    groupedEvents.forEach((date, eventsForDate) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      String dayKey;

      if(existingItineraries.values.any((itinerary) => itinerary.date == formattedDate)){
        dayKey = existingItineraries.keys.firstWhere((key) => existingItineraries[key]!.date == formattedDate);
      }
      else{
         dayKey = "day${_trip.itineraries.length + 1}";
      }

      List<Activity> activitiesForDate = eventsForDate.map((event) {
        return Activity(
          title: event.title,
          from: formatTimeOfDay(event.timeStart),
          to: formatTimeOfDay(event.timeEnd),
          details: event.notes,
        );
      }).toList();

      // Combine with existing activities if the dayKey already exists
      if (_trip.itineraries.containsKey(dayKey)) {
        _trip.itineraries[dayKey]!.activities.addAll(activitiesForDate);
      } else {
        Itinerary itinerary = Itinerary(date: formattedDate, activities: activitiesForDate);
        _trip.itineraries[dayKey] = itinerary;
      }
    });
    GlobalTripData.instance.notifyListeners();
  }

  String formatTimeOfDay(TimeOfDay timeOfDay){
    return '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Calendar"),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 1, 1),
            lastDay: DateTime.utc(2040, 1, 1),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedEvents = CalendarUtils.getEventsForDay(_events, selectedDay);
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              return CalendarUtils.getEventsForDay(_events, day);
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      width: 8,
                      height: 8,
                    ),
                  );
                }
                return null;
              },
            ),
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.lightBlue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  _selectedDay != null
                      ? ''
                      : 'Select a day to see events',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildEventList(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final updatedEvents = await Navigator.push<List<Event>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CalendarEditMode(
                          initialSelectedDay: _selectedDay,
                          events: List.from(_events),
                          tripId: widget.tripId,
                        ),
                      ),
                    );
                    _handleEditResult(updatedEvents);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RemindersPage(trip: _trip)),
                    );
                  },
                  icon: const Icon(Icons.notifications),
                  label: const Text('See Reminders'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Builds the list of events for a single day. INPUT: _selectedEvents
  Widget _buildEventList() {
    // If the _selectedDay has no events (_selectedEvents is empty)
    if (_selectedEvents.isEmpty) {
      return const Center(
        child: Text(
          'No events for selected day',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    // There are events in _selectedDay
    return ListView.builder(
      itemCount: _selectedEvents.length,
      itemBuilder: (context, index) {
        final event = _selectedEvents[index];
        final String timeRange = CalendarUtils.formatEventDuration(event);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 2.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        timeRange,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (event.isMultiDay)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Multi-day',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Location details need GMaps API",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (event.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          event.notes,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// Stores details of an event.
class Event {
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay timeStart;
  final TimeOfDay timeEnd;
  final String title;
  final String notes;
  final bool isMultiDay;

  Event({
    required this.startDate,
    required this.endDate,
    required this.timeStart,
    required this.timeEnd,
    required this.title,
    this.notes = '',
    this.isMultiDay = false,
  });
}