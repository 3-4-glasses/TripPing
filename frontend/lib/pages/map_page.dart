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
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text("Best Route"),
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
            child: Center(
            // Will be changed to the actual Maps API.
            child: Image.network( "https://outsystemsui.outsystems.com/OutSystemsMapsSample/img/OutSystemsMapsSample.mapPlaceholder.jpg?QkR0P7jN5v2j5mt1uqAHTQ",
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          ),
        ),
      ),
    );
  }
}