import 'package:apacsolchallenge/pages/main_page.dart';
import 'package:flutter/material.dart';
import 'package:google_solution_challenge/widget_tree.dart';

void main() {
  final globalTripData = GlobalTripData.instance;
  globalTripData.initialize(); // Initialize trip data

  runApp(
    MultiProvider( // Use MultiProvider to provide GlobalTripData
      providers: [
        ChangeNotifierProvider(create: (_) => globalTripData),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
      ),
      home: MainPage()
    );
  }
}