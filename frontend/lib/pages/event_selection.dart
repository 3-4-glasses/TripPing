import 'package:flutter/material.dart';
import 'package:apacsolchallenge/pages/calendar.dart';
import 'package:apacsolchallenge/pages/general_question.dart';
import 'package:apacsolchallenge/pages/main_page.dart';
import '../data/global_trip_data.dart';

final tripData = GlobalTripData.instance.tripData; // Access the global TripData instance

class EventSelection extends StatelessWidget {
  const EventSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Available plans',
              style: TextStyle(
                fontSize: 24.0, fontWeight: FontWeight.bold
              ),
            ),
            SizedBox(
              height: 16.0,
            ),
            _buildAvailablePlansList(context),
          ],
        )
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Trip'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'See Trips')
        ],
        currentIndex: 2,
        onTap: (index) {
          if (index == 0){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
              return MainPage();
            }));
          }
          else if (index == 1){
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return GeneralQuestion();
            }));
          }
        },
      ),
    );
  }

  Widget _buildAvailablePlansList(BuildContext context){
    List<String> availableTrips = _getTripNames();
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: availableTrips.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            title: Text(availableTrips[index]),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return Calendar(tripId: "trip1",);
              }));
            },
          )
        );
      }
    );
  }

  List<String> _getTripNames(){
    final tripList = tripData.trips.value;
    
    final tripNames = tripList.map((trip) => trip.name.value).toList();
    return tripNames; 
  }
}