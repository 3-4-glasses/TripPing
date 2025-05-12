import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_solution_challenge/pages/calendar.dart';
import 'package:google_solution_challenge/utilities/calendar_utils.dart';

class CalendarEditMode extends StatefulWidget {
  final DateTime? initialSelectedDay;
  final List<Event> events;

  const CalendarEditMode({super.key, this.initialSelectedDay, this.events = const []});

  @override
  State<CalendarEditMode> createState() => _CalendarEditModeState();
}

class _CalendarEditModeState extends State<CalendarEditMode> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late List<Event> _allEvents;
  List<Event> _selectedEvents = [];

  // State for new event input
  final TextEditingController _newEventTitleController = TextEditingController();
  DateTime? _newEventStartDate;
  DateTime? _newEventEndDate;
  TimeOfDay? _newEventStartTime;
  TimeOfDay? _newEventEndTime;
  final TextEditingController _newEventLocationController = TextEditingController();
  final TextEditingController _newEventNotesController = TextEditingController();
  bool _isMultiDayEvent = false;

  // State for AI assistance. NOT USED YET.
  final TextEditingController _aiRequestController = TextEditingController();
  final String _aiResponse = '';

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialSelectedDay ?? DateTime.now();
    _selectedDay = _focusedDay;
    _allEvents = List.from(widget.events);
    _selectedEvents = CalendarUtils.getEventsForDay(_allEvents ,_selectedDay!);
    
    // Initialize start date for new event form
    _newEventStartDate = _selectedDay;
    _newEventEndDate = _selectedDay;
  }

  Future<void> _selectNewEventStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _newEventStartDate ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _newEventStartDate = picked;
        
        // If end date is before start date, update end date to match start date
        if (_newEventEndDate != null && _newEventEndDate!.isBefore(_newEventStartDate!)) {
          _newEventEndDate = _newEventStartDate;
        }
        
        // Check if it's a multi-day event
        _updateMultiDayState();
      });
    }
  }

  Future<void> _selectNewEventEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _newEventEndDate ?? _newEventStartDate ?? DateTime.now(),
      firstDate: _newEventStartDate ?? DateTime(2010),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _newEventEndDate = picked;
        
        // Check if it's a multi-day event
        _updateMultiDayState();
      });
    }
  }

  void _updateMultiDayState() {
    if (_newEventStartDate != null && _newEventEndDate != null) {
      setState(() {
        _isMultiDayEvent = !isSameDay(_newEventStartDate!, _newEventEndDate!);
      });
    }
  }

  Future<void> _selectNewEventStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _newEventStartTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _newEventStartTime = picked;
        
        // If start and end date are the same and end time is before start time,
        // update end time to be after start time
        if (!_isMultiDayEvent && _newEventEndTime != null) {
          if (_timeOfDayToMinutes(_newEventEndTime!) <= _timeOfDayToMinutes(_newEventStartTime!)) {
            _newEventEndTime = TimeOfDay(
              hour: (_newEventStartTime!.hour + 1) % 24,
              minute: _newEventStartTime!.minute,
            );
          }
        }
      });
    }
  }

  Future<void> _selectNewEventEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _newEventEndTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _newEventEndTime = picked;
      });
    }
  }

  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  void _addNewEvent() {
    if (_newEventTitleController.text.isNotEmpty && 
        _newEventStartDate != null && 
        _newEventEndDate != null && 
        _newEventStartTime != null && 
        _newEventEndTime != null) {
      
      // Validate event timing
      final startDateTime = CalendarUtils.combineDateAndTime(_newEventStartDate!, _newEventStartTime!);
      final endDateTime = CalendarUtils.combineDateAndTime(_newEventEndDate!, _newEventEndTime!);
      
      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time cannot be before start time')),
        );
        return;
      }

      setState(() {
        _allEvents.add(
          Event(
            startDate: _newEventStartDate!,
            endDate: _newEventEndDate!,
            timeStart: _newEventStartTime!,
            timeEnd: _newEventEndTime!,
            title: _newEventTitleController.text,
            location: _newEventLocationController.text,
            notes: _newEventNotesController.text,
            isMultiDay: _isMultiDayEvent,
          ),
        );
        _selectedEvents = CalendarUtils.getEventsForDay(_allEvents, _selectedDay!);
        _newEventTitleController.clear();
        _newEventStartTime = null;
        _newEventEndTime = null;
        _newEventLocationController.clear();
        _newEventNotesController.clear();
        // Keep the dates set to the selected day
        _newEventStartDate = _selectedDay;
        _newEventEndDate = _selectedDay;
        _isMultiDayEvent = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the event title, dates and times')),
      );
    }
  }

  void _deleteEvent(Event event) {
    setState(() {
      _allEvents.remove(event);
      _selectedEvents = CalendarUtils.getEventsForDay(_allEvents, _selectedDay!);
    });
  }

  void _confirmChanges() {
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
                _selectedEvents = CalendarUtils.getEventsForDay(_allEvents, selectedDay);
                
                // Update start/end date for new event form
                if (_newEventStartDate == null || _newEventEndDate == null) {
                  _newEventStartDate = selectedDay;
                  _newEventEndDate = selectedDay;
                }
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
                  Text(
                    _selectedDay != null
                        ? 'Editing events for ${DateFormat('EEEE, MMMM d, y').format(_selectedDay!)}'
                        : 'Select a day to edit events',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  const Text('Events for this day:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _selectedEvents.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('No events for this day.'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedEvents.length,
                          itemBuilder: (context, index) {
                            final event = _selectedEvents[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${CalendarUtils.formatEventDuration(event)}: ${event.title}',
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        if (event.isMultiDay)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                    if (event.location.isNotEmpty) Text('Location: ${event.location}'),
                                    if (event.notes.isNotEmpty) Text('Notes: ${event.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(icon: const Icon(Icons.edit), onPressed: () {
                                          // Implement edit functionality
                                        }),
                                        IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteEvent(event)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 24),
                  const Text('Add New Event:', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _newEventTitleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectNewEventStartDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Start Date'),
                            child: Text(_formatDate(_newEventStartDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectNewEventEndDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'End Date'),
                            child: Text(_formatDate(_newEventEndDate)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.date_range, size: 16, color: Colors.blue),
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
                          onTap: () => _selectNewEventStartTime(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Start Time'),
                            child: Text(_newEventStartTime == null ? 'Select Time' : CalendarUtils.formatTimeOfDay(_newEventStartTime!)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectNewEventEndTime(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'End Time'),
                            child: Text(_newEventEndTime == null ? 'Select Time' : CalendarUtils.formatTimeOfDay(_newEventEndTime!)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _newEventLocationController,
                    decoration: const InputDecoration(labelText: 'Location (Optional)'),
                  ),
                  TextField(
                    controller: _newEventNotesController,
                    decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _addNewEvent, child: const Text('Add Event')),
                  const SizedBox(height: 24),
                  const Text('AI Assistance:', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _aiRequestController,
                    decoration: const InputDecoration(labelText: 'Ask AI for suggestions'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () {}, child: const Text('Send')),
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
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _confirmChanges();
                    },
                    child: const Text('Confirm', style: TextStyle(fontSize: 16)),
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