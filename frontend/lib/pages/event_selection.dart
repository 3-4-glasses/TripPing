import 'package:flutter/material.dart';
import 'package:apacsolchallenge/pages/calendar.dart';
import 'package:apacsolchallenge/pages/general_question.dart';
import 'package:apacsolchallenge/pages/main_page.dart';
import '../data/global_trip_data.dart';
import '../data/trip_data.dart';

final tripData = GlobalTripData.instance.tripData; // Access the global TripData instance

class EventSelection extends StatelessWidget {
  const EventSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              elevation: 0,
              title: const Text(
                'Available Plans',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              automaticallyImplyLeading: false,
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: _buildAvailablePlansList(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildAvailablePlansList(BuildContext context) {
    final List<Trip> availableTrips = tripData.trips.value;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final trip = availableTrips[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Calendar(tripId: trip.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          trip.name.value,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        childCount: availableTrips.length,
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
   return BottomNavigationBar(
    items: const <BottomNavigationBarItem>[ // Added const here
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
    currentIndex: 2, //  Consider making this a state variable if it changes
    onTap: (index) {
      // 0: Home, 1: Add Trip, 2: See Trips
      switch (index) {
        case 0: 
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage()));
          break;
        case 1:
          Navigator.push(context, MaterialPageRoute(builder: (context) => GeneralQuestion()));
          break;
        case 2:
          break;
        default:
          break;
      }
    },
  ); 
  }
}