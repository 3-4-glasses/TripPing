import 'package:flutter/material.dart';
import '../data/trip_data.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.fromActivity, required this.toActivity});

  final Activity? fromActivity;
  final Activity toActivity;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Best Route"),
      ),
      body: Center(
        // Will be changed to the actual Maps API.
        child: Image.network( "https://outsystemsui.outsystems.com/OutSystemsMapsSample/img/OutSystemsMapsSample.mapPlaceholder.jpg?QkR0P7jN5v2j5mt1uqAHTQ",
          height: double.infinity,
          width: double.infinity,
          fit: BoxFit.cover,
        )
      ),
    );
  }
}