import 'package:flutter/material.dart';
import 'package:apacsolchallenge/pages/calendar_edit.dart';
import 'package:apacsolchallenge/pages/reminders.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:apacsolchallenge/utilities/calendar_utils.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  List<Event> _events = [
    Event(
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      timeStart: const TimeOfDay(hour: 9, minute: 0),
      timeEnd: const TimeOfDay(hour: 11, minute: 30),
      title: 'Visit Eiffel Tower',
      location: 'Champ de Mars, Paris',
      notes: 'Remember to book tickets in advance',
    ),
    Event(
      startDate: DateTime.now().add(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 2)),
      timeStart: const TimeOfDay(hour: 14, minute: 0),
      timeEnd: const TimeOfDay(hour: 16, minute: 0),
      title: 'Museum Tour',
      location: 'The Louvre, Paris',
      notes: 'Audio guide available at entrance',
    ),
    // Example of a multi-day event
    Event(
      startDate: DateTime.now().add(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 6)),
      timeStart: const TimeOfDay(hour: 18, minute: 30),
      timeEnd: const TimeOfDay(hour: 9, minute: 0),
      title: 'Dinner Cruise + Hotel Stay',
      location: 'Seine River, Paris',
      notes: 'Formal attire recommended, includes overnight stay',
      isMultiDay: true,
    ),
  ];
  List<Event> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _selectedEvents = CalendarUtils.getEventsForDay(_events, _selectedDay!);
  }

  void _handleEditResult(List<Event>? updatedEvents) {
    if (updatedEvents != null) {
      setState(() {
        _events = updatedEvents;
        _selectedEvents = CalendarUtils.getEventsForDay(_events, _selectedDay ?? _focusedDay);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
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
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _selectedDay != null
                    ? 'Events on ${DateFormat('MMM d, yyyy').format(_selectedDay!)}'
                    : 'Select a day to see events',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                      MaterialPageRoute(builder: (context) => const RemindersPage()),
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
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
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
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Placeholder()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Placeholder()));
          }
        },
      ),
    );
  }

  Widget _buildEventList() {
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
                        event.location,
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

class Event {
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay timeStart;
  final TimeOfDay timeEnd;
  final String title;
  final String location;
  final String notes;
  final bool isMultiDay;

  Event({
    required this.startDate,
    required this.endDate,
    required this.timeStart,
    required this.timeEnd,
    required this.title,
    required this.location,
    this.notes = '',
    this.isMultiDay = false,
  });
}