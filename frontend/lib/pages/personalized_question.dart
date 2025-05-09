import 'package:flutter/material.dart';
import 'calendar.dart';

class PersonalizedQuestion extends StatefulWidget {
  const PersonalizedQuestion({super.key});

  @override
  State<PersonalizedQuestion> createState() => _PersonalizedQuestionState();
}

class _PersonalizedQuestionState extends State<PersonalizedQuestion> {
  final _dreamExperienceController = TextEditingController();
  String _validationError = '';

  void _navigateToCalendar() {
    // In a real scenario, we would send the text to Gemini for validation here.
    // For now, we'll just navigate if the text box is not empty.
    if (_dreamExperienceController.text.isNotEmpty) {
      // TODO: Implement the actual validation logic using Gemini (backend).
      // For now, we'll just proceed.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Calendar()),
      );
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
              onPressed: _navigateToCalendar,
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}