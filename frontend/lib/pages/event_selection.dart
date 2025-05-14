import 'package:flutter/material.dart';
import 'package:apacsolchallenge/pages/calendar.dart';
import 'package:apacsolchallenge/pages/general_question.dart';
import 'package:apacsolchallenge/pages/main_page.dart';
import '../data/global_trip_data.dart';
import '../data/trip_data.dart';
import 'package:provider/provider.dart';
import '../data/global_user.dart';

class EventSelection extends StatelessWidget {
  const EventSelection({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap the widget that uses GlobalTripData with a Consumer.
    return Consumer<GlobalTripData>(
      builder: (context, globalTripData, child) {
        final List<Trip> availableTrips = globalTripData.tripData.trips.value;
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
                  sliver: _buildAvailablePlansList(context, availableTrips), // Pass availableTrips
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(context),
        );
      },
    );
  }

  Widget _buildAvailablePlansList(BuildContext context, List<Trip> availableTrips) {
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
                        Row( // Added for delete icon
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmationDialog(context, trip.id); // Show dialog
                              },
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                          ],
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

  void _showDeleteConfirmationDialog(BuildContext context, String tripId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you want to delete this trip?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Get the GlobalTripData instance using Provider
                final globalTripData = Provider.of<GlobalTripData>(context, listen: false);
                globalTripData.deleteTrip(tripId); // Delete the trip
                Navigator.of(context).pop(true); // Close the dialog
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
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

