import 'dart:convert';

import 'package:apacsolchallenge/pages/main_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  final String uid;
  const PersonalizedQuestion({super.key,
    required this.tripName,
    required this.destination,
    this.departureDate,
    this.departureTime,
    this.returnDate,
    this.returnTime,
    required this.adultCount,
    required this.childCount,
    required this.transportation,
    required this.uid});

  @override
  State<PersonalizedQuestion> createState() => _PersonalizedQuestionState();
}

class _PersonalizedQuestionState extends State<PersonalizedQuestion> {
  final _dreamExperienceController = TextEditingController();
  String _validationError = '';

  Future<void> _navigateFinish() async {
    // In a real scenario, we would send the text to Gemini for validation here.
    // For now, we'll just navigate if the text box is not empty.
    if (_dreamExperienceController.text.isNotEmpty) {
      final response = await http.post(
        Uri.parse('https://backend-server-412321340776.us-west1.run.app/validate'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'input': _dreamExperienceController.text}),
      );
      if (response.statusCode == 201) {
        print(jsonDecode(response.body)['valid']);
        if(jsonDecode(response.body)['valid']){
          final answer =  await http.post(Uri.parse('https://backend-server-412321340776.us-west1.run.app/itinerary'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, dynamic>{
              'input': _dreamExperienceController.text,
              'title': widget.tripName,
              'destination': widget.destination,
              "departureTime": widget.departureTime,
              "returnTime": widget.returnTime,
              "numChildren": widget.childCount,
              "numAdult": widget.adultCount,
              "preferredTransportation": widget.transportation,
              "userId": widget.uid
            })
          );
          if(answer.statusCode==200){
            // Get trip, put trip data, terip data is in result, trip id if in triop id

          }else{

          }

        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainPage()),
              (Route<dynamic> route) => false,
        );
      } else {
        // If the server did not return a 201 CREATED response,
        // then throw an exception.
        throw Exception('Failed to create album.');
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
        title: const Text('Personalization'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToBasicQuestionnaire,
        ),
      ),
      body: SingleChildScrollView(
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
      ),
    );
  }
}