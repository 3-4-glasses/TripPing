// CLASS USED TO STORE REUSED FUNCTIONS IN CALENDAR UIs.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_solution_challenge/pages/calendar.dart';

class CalendarUtils {
    static String formatTimeOfDay(TimeOfDay time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    static DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }

    static List<Event> getEventsForDay(List<Event> events, DateTime day) {
      return events.where((event) {
        if (event.isMultiDay) {
          final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
          final dayStart = DateTime(day.year, day.month, day.day, 0, 0, 0);
          final eventStartDateTime = combineDateAndTime(event.startDate, event.timeStart);
          final eventEndDateTime = combineDateAndTime(event.endDate, event.timeEnd);
          return (eventStartDateTime.isBefore(dayEnd) || eventStartDateTime.isAtSameMomentAs(dayEnd)) &&
                (eventEndDateTime.isAfter(dayStart) || eventEndDateTime.isAtSameMomentAs(dayStart));
        } else {
          return isSameDay(event.startDate, day);
        }
      }).toList();
    }

    static String formatEventDuration(Event event) {
      if (event.isMultiDay) {
        final startFormatter = DateFormat('MMM d');
        final endFormatter = DateFormat('MMM d');
        return '${startFormatter.format(event.startDate)} ${formatTimeOfDay(event.timeStart)} - ${endFormatter.format(event.endDate)} ${formatTimeOfDay(event.timeEnd)}';
      } else {
        return '${formatTimeOfDay(event.timeStart)} - ${formatTimeOfDay(event.timeEnd)}';
      }
    }


    static bool isSameDay(DateTime a, DateTime b) { // Added isSameDay for this class
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }
}

