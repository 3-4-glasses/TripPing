import 'package:flutter/material.dart';
import 'pages/main_page.dart';

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(), // Starting with the Event Selection Page
    );
  }
}