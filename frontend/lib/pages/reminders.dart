import 'package:flutter/material.dart';

class Reminders extends StatelessWidget {
  const Reminders({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('See Reminders')
      ), 
      body: Center(
        child: Text('See Reminders')
      )
    );
  }
}