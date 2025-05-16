import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:apacsolchallenge/utilities/calendar_utils.dart';
import 'package:apacsolchallenge/pages/calendar.dart';
import '../data/global_trip_data.dart';
import '../data/trip_data.dart';

class CalendarEditMode extends StatefulWidget {
  final DateTime? initialSelectedDay;
  final List<Event> events;
  final String tripId;

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
  late Trip _trip;

  // State for new/edited event input
  final TextEditingController _eventTitleController = TextEditingController();
  DateTime? _eventStartDate;
  DateTime? _eventEndDate;
  TimeOfDay? _eventStartTime;
  TimeOfDay? _eventEndTime;
  final TextEditingController _eventNotesController = TextEditingController();
  bool _isMultiDayEvent = false;
  int? _editingIndex; // Track the index of the event being edited, null for new events

  // State for AI assistance. NOT USED YET.
  final TextEditingController _aiRequestController = TextEditingController();
  final String _aiResponse = '';

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

  // Function to check for time conflicts
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

  void _addOrUpdateEvent() {
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
        isMultiDay: _isMultiDayEvent,
      );

      Activity newActivity = Activity(
        from: CalendarUtils.formatTimeOfDay(_eventStartTime!),
        to: CalendarUtils.formatTimeOfDay(_eventEndTime!),
        title: _eventTitleController.text,
        details: _eventNotesController.text,
      );

      DateTime tripDateFrom = DateTime.parse(_trip.dateFrom.value!);
      int dayDifference =
          _eventStartDate!.difference(tripDateFrom).inDays + 1;
      String dayKey = "day$dayDifference";

      //  Make sure the dayKey exists.
      if (!_trip.itineraries.containsKey(dayKey)) {
        _trip.itineraries[dayKey] = Itinerary(
          date: DateFormat('yyyy-MM-dd').format(_eventStartDate!),
          activities: [], //  Initialize with an empty list.
        );
      }
      // Update or add
      if (_editingIndex != null) {
        // Update
        _allEvents[_editingIndex!] = newEvent;

        // Update activity
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
      setState(() {
        _selectedEvents = CalendarUtils.getEventsForDay(_allEvents, _selectedDay!);
        _eventTitleController.clear();
        _eventStartTime = null;
        _eventEndTime = null;
        _eventNotesController.clear();
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

  void _deleteEvent(Event event) {
    setState(() {
      _allEvents.remove(event);

      _trip.itineraries.forEach((key, itinerary) {
        itinerary.activities.removeWhere((activity) =>
            activity.title == event.title &&
            activity.from == CalendarUtils.formatTimeOfDay(event.timeStart) &&
            activity.to == CalendarUtils.formatTimeOfDay(event.timeEnd));
      });
      GlobalTripData.instance.notifyListeners();

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

  void _confirmChanges() {
    GlobalTripData.instance.notifyListeners();
    print(_allEvents.first.title);
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
        elevation: 0,
        backgroundColor: Color(0xFFA0CDC3),
        title: const Text('Edit Calendar'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFA0CDC3),
              Color(0xFFA0E9F2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
      child: Column(
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
                            horizontal: 10, vertical: 4),
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
                      onPressed: () {}, child: const Text('Send')),
                  if (_aiResponse.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_aiResponse),
                    ),
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
                    onPressed: () {
                      _confirmChanges();
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
      ),
      ),
    );
  }
}