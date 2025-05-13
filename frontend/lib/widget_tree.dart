import 'package:flutter/material.dart';
import 'pages/calendar.dart';
import 'pages/event_selection.dart';
import 'pages/add_expenses.dart';
import 'pages/add_item.dart';
import 'pages/calendar_edit.dart';
import 'pages/expenses.dart';
import 'pages/general_question.dart';
import 'pages/main_page.dart';
import 'pages/map_page.dart';
import 'pages/personalized_question.dart';
import 'pages/reminders.dart';

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EventSelection(), // Starting with the Event Selection Page
      routes: {
        '/home': (context) => MainPage(),
        '/add_trip': (context) => GeneralQuestion(),
        '/personalized_questionnaires': (context) => PersonalizedQuestion(),
        '/calendar': (context) => const Calendar(),
        '/calendar_edit': (context) => const CalendarEditMode(),
        '/reminders': (context) => const Reminders(),
        '/add_item': (context) => const AddItem(),
        '/expenses_trip': (context) => const Expenses(),
        '/add_expenses': (context) => const AddExpenses(),
        '/map': (context) => const MapPage(),
        '/event_selection': (context) => const EventSelection(), // Explicit route for this page
      },
    );
  }
}