import 'package:flutter/material.dart';

class Expenses extends StatelessWidget {
  const Expenses({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses of the trip')
      ), 
      body: Center(
        child: Text('Expenses of the trip')
      )
    );
  }
}