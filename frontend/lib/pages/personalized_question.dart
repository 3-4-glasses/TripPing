import 'dart:convert';

import 'package:apacsolchallenge/pages/main_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/global_trip_data.dart';
import '../data/global_user.dart';
import '../data/trip_data.dart';

class PersonalizedQuestion extends StatefulWidget {
  final String tripName;
  final String destination;
  final DateTime? departureDate;
  final TimeOfDay? departureTime;
  final DateTime? returnDate;
  final TimeOfDay? returnTime;
  final int adultCount;
  final int childCount;
  final String transportation;
  const PersonalizedQuestion({super.key,
    required this.tripName,
    required this.destination,
    this.departureDate,
    this.departureTime,
    this.returnDate,
    this.returnTime,
    required this.adultCount,
    required this.childCount,
    required this.transportation});

  @override
  State<PersonalizedQuestion> createState() => _PersonalizedQuestionState();
}

class _PersonalizedQuestionState extends State<PersonalizedQuestion> {
  final _dreamExperienceController = TextEditingController();
  String _validationError = '';


  int _timeOfDayToUnixMs(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return dt.millisecondsSinceEpoch; // Return the milliseconds since epoch
  }


  Future<void> _navigateFinish() async {
    // In a real scenario, we would send the text to Gemini for validation here.
    // For now, we'll just navigate if the text box is not empty.
    if (_dreamExperienceController.text.isNotEmpty) {
      final response = await http.post(
        Uri.parse('https://backend-server-412321340776.us-west1.run.app/gemini/validate'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'input': _dreamExperienceController.text}),
      );
      if (response.statusCode == 201) {
        if(jsonDecode(response.body)['valid']){
          final answer =  await http.post(Uri.parse('https://backend-server-412321340776.us-west1.run.app/gemini/itinerary'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, dynamic>{
              'input': _dreamExperienceController.text,
              'title': widget.tripName,
              'destination': widget.destination,
              "departureTime": _timeOfDayToUnixMs(widget.departureTime!),
              "returnTime": _timeOfDayToUnixMs(widget.returnTime!),
              "numChildren": widget.childCount,
              "numAdult": widget.adultCount,
              "preferredTransportation": widget.transportation,
              "userId": UserSession.instance.uid
            })
          );
          if (answer.statusCode == 200) {
            final json = jsonDecode(answer.body);
            final result = json['result'];

            final tripId = UniqueKey().toString();
            final name = widget.tripName;
            final fromDate = widget.departureTime.toString().split(" ").first;
            final toDate = widget.returnTime.toString().split(" ").first;

            List<Map<String, dynamic>> fixedExpenses = (result['setExpenses'] as List).map((e) {
              return {'item': e['item'], 'price': (e['price'] as num).toDouble()};
            }).toList();

            List<Map<String, dynamic>> variableExpenses = (result['variableExpenses'] as List).map((e) {
              return {'item': e['item'], 'price': (e['price'] as num).toDouble()};
            }).toList();

            Map<String, Itinerary> itineraryMap = {};
            for (var key in result.keys) {
              if (key.startsWith("day")) {
                final day = result[key];
                final date = day["date"];
                final activitiesJson = day["activities"] as List;

                List<Activity> activities = activitiesJson.map((activityJson) {
                  final location = activityJson['location'];
                  return Activity(
                    from: activityJson['from'],
                    to: activityJson['to'],
                    title: activityJson['title'],
                    details: activityJson['details'],
                    locationDetail: activityJson['locationDetail'],
                    location: location != null
                        ? Location(
                      latitude: (location['latitude'] as num).toDouble(),
                      longitude: (location['longitude'] as num).toDouble(),
                    )
                        : null,
                  );
                }).toList();

                itineraryMap[key] = Itinerary(date: date, activities: activities);
              }
            }

            final newTrip = Trip(
              id: tripId,
              name: ValueNotifier<String>(name),
              dateFrom: ValueNotifier<String?>(fromDate),
              dateTo: ValueNotifier<String?>(toDate),
              expensesUsed: ValueNotifier<double>(result['estimatedExpenses']?.toDouble() ?? 0.0),
              expensesLimit: ValueNotifier<double>(result['expensesLimit']?.toDouble() ?? 0.0),
              items: ValueNotifier<List<String>>([]),
              fixedExpenses: ValueNotifier<List<Map<String, dynamic>>>(fixedExpenses),
              variableExpenses: ValueNotifier<List<Map<String, dynamic>>>(variableExpenses),
              itineraries: itineraryMap,
            );

            GlobalTripData.instance.addTrip(newTrip);

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => MainPage()),
                  (Route<dynamic> route) => false,
            );
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Trip Creation Failed"),
                  content: Text("An error occurred: ${answer.body}"),
                  actions: [
                    TextButton(
                      child: Text("OK"),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              },
            );

          }

        }
        else{
          setState(() {
            _validationError="Please enter a coherent plan, try again with the required field";
          });
        }

      } else {
        // If the server did not return a 201 CREATED response,
        // then throw an exception.
        setState(() {
          _validationError="Backend error";
        });
      }
    } else {
      setState(() {
        _validationError = 'Please describe your dream trip experience.';
      });
    }
  }

  void _goBackToBasicQuestionnaire() {
    Navigator.pop(context); // Navigate back to the AddTripPage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Personalization'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToBasicQuestionnaire,
        ),
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
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _dreamExperienceController,
              maxLines: 10, // Allow for a larger text input
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe your dream travel experience, mentioning dates, destination, time of day, accommodation, transportation, and total budget.',
              ),
              onChanged: (value) {
                // Clear the validation error when the user starts typing
                setState(() {
                  _validationError = '';
                });
              },
            ),
            if (_validationError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _validationError,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 32.0),

            ElevatedButton(
              onPressed: _navigateFinish,
              child: const Text('Next'),
            ),
          ],
        ),
      ),),),
    );
  }
}