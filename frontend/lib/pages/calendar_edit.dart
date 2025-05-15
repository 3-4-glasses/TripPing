import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:apacsolchallenge/utilities/calendar_utils.dart';
import 'package:apacsolchallenge/pages/calendar.dart';
import '../data/global_trip_data.dart';
import '../data/global_user.dart';
import '../data/trip_data.dart';
import 'package:http/http.dart' as http;


class CalendarEditMode extends StatefulWidget {
  final DateTime? initialSelectedDay;
  final List<Event> events;
  final String tripId;
  // final String ItineraryId;
  const CalendarEditMode(
      {super.key, this.initialSelectedDay, this.events = const [], required this.tripId});

  @override
  State<CalendarEditMode> createState() => _CalendarEditModeState();
}

class _CalendarEditModeState extends State<CalendarEditMode> {
  // Initialize Calendar states
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late List<Event> _allEvents;
  List<Event> _selectedEvents = [];
  // State for new/edited event input
  // State for AI assistance. NOT USED YET. TODO god damn it
  // TODO
  Future<void> _addOrUpdateEvent() async {
    if (_eventTitleController.text.isNotEmpty &&
        _eventStartDate != null &&
        _eventEndDate != null &&
        _eventStartTime != null &&
        _eventEndTime != null) {
      // Validate event timing
      final startDateTime =
          CalendarUtils.combineDateAndTime(_eventStartDate!, _eventStartTime!);
      final endDateTime =
          CalendarUtils.combineDateAndTime(_eventEndDate!, _eventEndTime!);

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time cannot be before start time')),
        );
        return;
      }

      // Check for time conflicts
      if (_checkTimeConflict(
          startDateTime, endDateTime, _eventStartTime!, _eventEndTime!, _editingIndex)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event time conflicts with another event')),
        );
        return;
      }

      Event newEvent = Event(
        startDate: _eventStartDate!,
        endDate: _eventEndDate!,
        timeStart: _eventStartTime!,
        timeEnd: _eventEndTime!,
        title: _eventTitleController.text,
        notes: _eventNotesController.text,
        locationDetail: _locationDetailController.text,
        isMultiDay: _isMultiDayEvent,
      );

      Activity newActivity = Activity(
        from: CalendarUtils.formatTimeOfDay(_eventStartTime!),
        to: CalendarUtils.formatTimeOfDay(_eventEndTime!),
        title: _eventTitleController.text,
        details: _eventNotesController.text,
        locationDetail: _locationDetailController.text
      );

      DateTime tripDateFrom = DateTime.parse(_trip.dateFrom.value!);
      int dayDifference =
          _eventStartDate!.difference(tripDateFrom).inDays + 1;
      String dayKey = "day$dayDifference";

      //  Make sure the dayKey exists.
      if (!_trip.itineraries.containsKey(dayKey)) {
        _trip.itineraries[dayKey] = Itinerary(
          // id: , TODO
          date: DateFormat('yyyy-MM-dd').format(_eventStartDate!),
          activities: [], //  Initialize with an empty list.
        );
      }
      // Update or add
      if (_editingIndex != null) {
        // Update
        _allEvents[_editingIndex!] = newEvent;

        // Update activity
        // TODO here
        bool found = false;
        for (var activity in _trip.itineraries[dayKey]!.activities)
        {
          if (activity.title == _eventTitleController.text)
          {
            activity.from = CalendarUtils.formatTimeOfDay(_eventStartTime!);
            activity.to = CalendarUtils.formatTimeOfDay(_eventEndTime!);
            activity.details = _eventNotesController.text;
            found = true;
            break;
          }
        }
        if (!found)
        {
          _trip.itineraries[dayKey]!.activities.add(newActivity);
        }

      } else {
        // Add
        _allEvents.add(newEvent);

        _trip.itineraries[dayKey]!.activities.add(newActivity);
      }

      // Sort
      _allEvents.sort((a, b) {
        int startTimeComparison = a.startDate.compareTo(b.startDate);
        if (startTimeComparison != 0) {
          return startTimeComparison;
        }
        return a.timeStart.compareTo(b.timeStart);
      });

      GlobalTripData.instance.notifyListeners();
      await sendUpdatedItinerary(UserSession.instance.uid, _trip.id, _trip.itineraries);

      setState(() {
        _selectedEvents = CalendarUtils.getEventsForDay(_allEvents, _selectedDay!);
        _eventTitleController.clear();
        _eventStartTime = null;
        _eventEndTime = null;
        _eventNotesController.clear();
        _locationDetailController.clear();
        _eventStartDate = _selectedDay;
        _eventEndDate = _selectedDay;
        _isMultiDayEvent = false;
        _editingIndex = null; // Reset editing index
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please fill in the event title, dates and times')),
      );
    }
  }
  // Function to check for time conflicts

  late Trip _trip;
  final TextEditingController _eventTitleController = TextEditingController();
  DateTime? _eventStartDate;
  DateTime? _eventEndDate;
  TimeOfDay? _eventStartTime;
  TimeOfDay? _eventEndTime;
  final TextEditingController _eventNotesController = TextEditingController();
  final TextEditingController _locationDetailController = TextEditingController();
  bool _isMultiDayEvent = false;

  int? _editingIndex; // Track the index of the event being edited, null for new events

  final TextEditingController _aiRequestController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialSelectedDay ?? DateTime.now();
    _selectedDay = _focusedDay;
    _allEvents = List.from(widget.events);
    _selectedEvents = CalendarUtils.getEventsForDay(_allEvents, _selectedDay!);

    // Initialize start date for new event form
    _eventStartDate = _selectedDay;
    _eventEndDate = _selectedDay;

    _trip = GlobalTripData.instance.tripData.trips.value.firstWhere((trip) => trip.id == widget.tripId);
  }

  @override
  void dispose() {
    _eventTitleController.dispose();
    _eventNotesController.dispose();
    super.dispose();
  }

  Future<void> _selectEventStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventStartDate ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        _eventStartDate = picked;

        // If end date is before start date, update end date to match start date
        if (_eventEndDate != null && _eventEndDate!.isBefore(_eventStartDate!)) {
          _eventEndDate = _eventStartDate;
        }

        // Check if it's a multi-day event
        _updateMultiDayState();
      });
    }
  }

  Future<void> _selectEventEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventEndDate ?? _eventStartDate ?? DateTime.now(),
      firstDate: _eventStartDate ?? DateTime(2010),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _eventEndDate = picked;

        // Check if it's a multi-day event
        _updateMultiDayState();
      });
    }
  }

  void _updateMultiDayState() {
    if (_eventStartDate != null && _eventEndDate != null) {
      setState(() {
        _isMultiDayEvent = !isSameDay(_eventStartDate!, _eventEndDate!);
      });
    }
  }

  Future<void> _selectEventStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _eventStartTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _eventStartTime = picked;

        // If start and end date are the same and end time is before start time,
        // update end time to be after start time
        if (!_isMultiDayEvent && _eventEndTime != null) {
          if (_timeOfDayToMinutes(_eventEndTime!) <=
              _timeOfDayToMinutes(_eventStartTime!)) {
            _eventEndTime = TimeOfDay(
              hour: (_eventStartTime!.hour + 1) % 24,
              minute: _eventStartTime!.minute,
            );
          }
        }
      });
    }
  }

  Future<void> _selectEventEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _eventEndTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _eventEndTime = picked;
      });
    }
  }

  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }
  bool _checkTimeConflict(
    DateTime startDate, DateTime endDate, TimeOfDay startTime, TimeOfDay endTime,
      [int? excludeIndex]) {
    for (int i = 0; i < _allEvents.length; i++) {
      if (i == excludeIndex) continue; // Skip the event being edited
      final existingEvent = _allEvents[i];
      
      // Combine existing event's start and end dates with their times
      final existingStartDateTime = CalendarUtils.combineDateAndTime(
          existingEvent.startDate, existingEvent.timeStart);
      final existingEndDateTime = CalendarUtils.combineDateAndTime(
          existingEvent.endDate, existingEvent.timeEnd);
      
      // New event's datetime
      final newStartDateTime = CalendarUtils.combineDateAndTime(startDate, startTime);
      final newEndDateTime = CalendarUtils.combineDateAndTime(endDate, endTime);
      
      // Check if the events overlap in both date and time
      if (newStartDateTime.isBefore(existingEndDateTime) && 
          newEndDateTime.isAfter(existingStartDateTime)) {
        return true; // Conflict found
      }
    }
    return false; 
  }

  String _ensureIsoDateTime(String time, String date) {
    try {
      // Check if `time` is full ISO 8601 datetime
      final parsedFullDate = DateTime.tryParse(time.trim());
      if (parsedFullDate != null) {
        // It's already a full ISO datetime string
        return parsedFullDate.toIso8601String();
      }

      // Otherwise, assume `time` is "HH:mm" format

      // Ensure `date` contains only yyyy-MM-dd part
      final dateOnly = date.split('T').first;

      final dateTimeString = '$dateOnly $time';
      final combined = DateFormat("yyyy-MM-dd HH:mm").parse(dateTimeString);
      return combined.toIso8601String();
    } catch (e) {
      print('Invalid date/time: $date + $time — $e');
      throw FormatException('Invalid date or time: "$date", "$time"');
    }
  }


  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> sendAIItineraryRequest(
      String userId,
      String tripId,
      Map<String, Itinerary> itineraries,
      String input,
      ) async {
    print("----");
    print(itineraries);
    print("----");
    final itineraryPayload = prepareItineraryForApi(itineraries);
    print("----");
    print(itineraryPayload);
    final response = await http.post(
      Uri.parse('https://backend-server-412321340776.us-west1.run.app/gemini/editItenerary'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
        'tripId': tripId,
        'itineraries': itineraryPayload,
        'input': input,
      }),
    );

    if (response.statusCode == 201) {
      print("AI-generated itinerary received.");
      final jsonResponse = jsonDecode(response.body);

      // handle and update local state
      final List<dynamic> newItinerary = jsonResponse['itinerary'];
      print(newItinerary);
      // Clear existing itineraries
      _trip.itineraries.clear();
      final Map<String, Itinerary> updatedItineraries = {};
      // Rebuild from updated response
      for (var day in newItinerary) {
        final dateStr = day['date'];
        final DateTime date = DateTime.parse(dateStr);
        final String formattedDate = DateFormat('yyyy-MM-dd').format(date);


        final List<Activity> activities = (day['activities'] as List).map((activity) {
          return Activity(
            from: DateFormat("HH:mm").format(DateTime.parse(activity['from'])),
            to: DateFormat("HH:mm").format(DateTime.parse(activity['to'])),
            title: activity['title'],
            details: activity['details'],
            locationDetail: activity['locationDetail'] ?? '',
            location: activity['location'] != null &&
                activity['location']['latitude'] != null &&
                activity['location']['longitude'] != null
                ? Location(
              latitude: (activity['location']['latitude'] as num).toDouble(),
              longitude: (activity['location']['longitude'] as num).toDouble(),
            )
                : null,

          );
        }).toList();
        updatedItineraries["day${updatedItineraries.length + 1}"] = Itinerary(
          date: formattedDate,
          activities: activities,
        );
      }
      setState(() {
        // Replace the entire itinerary map at once
        _trip.itineraries = updatedItineraries;

        // Update events list based on new itineraries
        _allEvents = [];
        _trip.itineraries.forEach((key, itinerary) {
          for (var activity in itinerary.activities) {
            _allEvents.add(Event(
              startDate: DateTime.parse(itinerary.date),
              endDate: DateTime.parse(itinerary.date),
              timeStart: _parseTimeOfDay(activity.from),
              timeEnd: _parseTimeOfDay(activity.to),
              title: activity.title,
              notes: activity.details,
              locationDetail: activity.locationDetail,
              isMultiDay: false, // You may want to adjust this
            ));
          }
        });

        _allEvents.sort((a, b) {
          int dateCompare = a.startDate.compareTo(b.startDate);
          if (dateCompare != 0) return dateCompare;
          return _timeOfDayToMinutes(a.timeStart).compareTo(_timeOfDayToMinutes(b.timeStart));
        });

        // Update selected events for the currently selected day
        _selectedEvents = CalendarUtils.getEventsForDay(_allEvents, _selectedDay!);
      });

      GlobalTripData.instance.notifyListeners(); // Notifies UI
    } else {
      print("AI itinerary generation failed: ${response.body}");
    }
  }


  List<Map<String, dynamic>> prepareItineraryForApi(Map<String, Itinerary> itineraries) {
    List<Map<String, dynamic>> payload = [];

    itineraries.forEach((key, itinerary) {
      // Extract only date part (yyyy-MM-dd) from itinerary.date
      String dateOnly = itinerary.date.split('T').first;

      payload.add({
        'date': dateOnly,  // also send dateOnly here for consistency
        'activities': itinerary.activities.map((activity) => {
          'from': _ensureIsoDateTime(activity.from, dateOnly),
          'to': _ensureIsoDateTime(activity.to, dateOnly),
          'title': activity.title,
          'details': activity.details,
          'locationDetail': activity.locationDetail,
          'location': activity.location != null
              ? {
            'latitude': activity.location!.latitude,
            'longitude': activity.location!.longitude,
          }
              : null,
        }).toList(),
      });
    });

    return payload;
  }

  /// Converts 'HH:mm' + itinerary.date into full ISO 8601 string
  DateTime _convertToFullDateTime(String dateStr, String timeStr) {
    // Extract date only (ignore time in dateStr if present)
    DateTime date = DateTime.parse(dateStr).toLocal();

    // Parse time string "HH:mm"
    final timeParts = timeStr.split(':');
    if (timeParts.length != 2) {
      throw FormatException('Invalid time format: $timeStr');
    }
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);

    return DateTime(date.year, date.month, date.day, hour, minute);
  }



  Future<void> sendUpdatedItinerary(String userId, String tripId, Map<String, Itinerary> itineraries) async {
    final itineraryPayload = prepareItineraryForApi(itineraries);

    final response = await http.post(
      Uri.parse('https://backend-server-412321340776.us-west1.run.app/trip/edit-itinerary'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
        'tripId': tripId,
        'itinerary': itineraryPayload,
      }),
    );

    if (response.statusCode == 201) {
      print("Itinerary updated successfully");
    } else {
      print("Failed to update itinerary: ${response.body}");
    }
  }

  void _deleteEvent(Event event) {
    setState(() async {
      _allEvents.remove(event);
      _trip.itineraries.forEach((key, itinerary) {
        itinerary.activities.removeWhere((activity) =>
            activity.title == event.title &&
            activity.from == CalendarUtils.formatTimeOfDay(event.timeStart) &&
            activity.to == CalendarUtils.formatTimeOfDay(event.timeEnd));
      });
      GlobalTripData.instance.notifyListeners();
      await sendUpdatedItinerary(UserSession.instance.uid, _trip.id, _trip.itineraries);


      _selectedEvents = CalendarUtils.getEventsForDay(_allEvents, _selectedDay!);
    });
  }

  void _editEvent(int index) {
    final event = _selectedEvents[index]; // Use _selectedEvents
    _eventTitleController.text = event.title;
    _eventStartDate = event.startDate;
    _eventEndDate = event.endDate;
    _eventStartTime = event.timeStart;
    _eventEndTime = event.timeEnd;
    _eventNotesController.text = event.notes;
    _isMultiDayEvent = event.isMultiDay;
    _editingIndex = _allEvents.indexOf(event); // Store the index in _allEvents

    setState(() {
      _eventStartDate = event.startDate;
      _eventEndDate = event.endDate;
    });
  }

  Future<void> _confirmChanges() async {
    GlobalTripData.instance.notifyListeners();
    print(_allEvents.first.title);
    await sendUpdatedItinerary(UserSession.instance.uid, _trip.id, _trip.itineraries);
    Navigator.pop(context, _allEvents);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return DateFormat('MMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Calendar'),
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
                _selectedEvents =
                    CalendarUtils.getEventsForDay(_allEvents, selectedDay);

                // Update start/end date for new event form
                if (_eventStartDate == null || _eventEndDate == null) {
                  _eventStartDate = selectedDay;
                  _eventEndDate = selectedDay;
                }
                _editingIndex = null;
                _eventTitleController.clear();
                _eventNotesController.clear();
                _eventStartTime = null;
                _eventEndTime = null;
                _isMultiDayEvent = false;
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
              return CalendarUtils.getEventsForDay(_allEvents, day);
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
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _selectedEvents.isEmpty
                      ? const Column(
                          children: [
                            Text("No events for this day")
                          ],
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedEvents.length,
                          itemBuilder: (context, index) {
                            final event = _selectedEvents[index];
                            return Card(
                              margin:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${CalendarUtils.formatEventDuration(event)}: ${event.title}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        if (event.isMultiDay)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                    if (event.notes.isNotEmpty)
                                      Text('Notes: ${event.notes}',
                                          style: const TextStyle(
                                              fontStyle:
                                                  FontStyle.italic)),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () {
                                              _editEvent(index);
                                            }
                                        ),
                                        IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () =>
                                                _deleteEvent(event)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 24),
                  Text(
                    _editingIndex == null
                        ? 'Add New Event:'
                        : 'Edit Event:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _eventTitleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectEventStartDate(context),
                          child: InputDecorator(
                            decoration:
                                const InputDecoration(labelText: 'Start Date'),
                            child: Text(_formatDate(_eventStartDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectEventEndDate(context),
                          child: InputDecorator(
                            decoration:
                                const InputDecoration(labelText: 'End Date'),
                            child: Text(_formatDate(_eventEndDate)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isMultiDayEvent)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10,  vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.blue.withOpacity(0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.date_range,
                                size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Multi-day event',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectEventStartTime(context),
                          child: InputDecorator(
                            decoration:
                                const InputDecoration(labelText: 'Start Time'),
                            child: Text(_eventStartTime == null
                                ? 'Select Time'
                                : CalendarUtils.formatTimeOfDay(
                                    _eventStartTime!)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectEventEndTime(context),
                          child: InputDecorator(
                            decoration:
                                const InputDecoration(labelText: 'End Time'),
                            child: Text(_eventEndTime == null
                                ? 'Select Time'
                                : CalendarUtils.formatTimeOfDay(
                                    _eventEndTime!)),
                          ),
                        ),
                      )],
                    ),
                  TextField(
                    controller: _locationDetailController,
                    decoration:
                    const InputDecoration(labelText: 'Location detail (Optional'),
                    maxLines: 2,
                  ),
                  TextField(
                    controller: _eventNotesController,
                    decoration:
                        const InputDecoration(labelText: 'Notes (Optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _addOrUpdateEvent,
                      child: Text(_editingIndex == null
                          ? 'Add Event'
                          : 'Update Event')),
                  const SizedBox(height: 24),
                  const Text('AI Assistance:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _aiRequestController,
                    decoration: const InputDecoration(
                        labelText: 'Ask AI for suggestions'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: () async {
                        print("Pressed");
                        await sendAIItineraryRequest(
                      UserSession.instance.uid,
                      _trip.id,
                      _trip.itineraries,
                      _aiRequestController.text.trim(),
                      );
                        print("Done");
                      }, child: const Text('Send')),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child:
                        const Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _confirmChanges();
                    },
                    child:
                        const Text('Confirm', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}