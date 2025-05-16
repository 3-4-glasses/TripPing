import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'personalized_question.dart';
import '../data/global_user.dart';

class GeneralQuestion extends StatefulWidget {
  const GeneralQuestion({super.key});

  @override
  State<GeneralQuestion> createState() => _GeneralQuestionState();
}

class _GeneralQuestionState extends State<GeneralQuestion> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tripNameController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  DateTime? _returnDate;
  TimeOfDay? _returnTime;
  int _adultCount = 1;
  int _childCount = 0;
  final TextEditingController _transportationController = TextEditingController();
  bool _isNextButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    
    // Add listeners to text controllers
    _tripNameController.addListener(_checkIfAllFieldsFilled);
    _destinationController.addListener(_checkIfAllFieldsFilled);
    _transportationController.addListener(_checkIfAllFieldsFilled);
    
    _checkIfAllFieldsFilled();
  }

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed
    _tripNameController.dispose();
    _destinationController.dispose();
    _transportationController.dispose();
    super.dispose();
  }

  void _checkIfAllFieldsFilled(){
    setState(() {
      _isNextButtonEnabled = _tripNameController.text.isNotEmpty &&
      _destinationController.text.isNotEmpty &&
      _departureDate != null &&
      _departureTime != null &&
      _returnDate != null &&
    _returnTime != null &&  // Fixed: was checking _returnDate twice
      _transportationController.text.isNotEmpty;
    });
  }

  Future<void> _selectDepartureDate(BuildContext context) async{
    final DateTime? picked = await showDatePicker(context: context, 
      initialDate: _departureDate ?? DateTime.now(),
      firstDate: DateTime.now(), lastDate: DateTime(2101),
    );
    if (picked != null){
      setState(() {
        _departureDate = picked;
        _checkIfAllFieldsFilled();
      });
    }
  }

  Future<void> _selectDepartureTime(BuildContext context) async{
    final TimeOfDay? picked = await showTimePicker(context: context, 
      initialTime: _departureTime ?? TimeOfDay.now()
    );
    if (picked != null){
      setState(() {
        _departureTime = picked;
        _checkIfAllFieldsFilled();
      });
    }
  }

  Future<void> _selectReturnDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _returnDate = picked;
        _checkIfAllFieldsFilled();
      });
    }
  }

  Future<void> _selectReturnTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _returnTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _returnTime = picked;
        _checkIfAllFieldsFilled();
      });
    }
  }

  void _incrementAdultCount() {
    setState(() {
      _adultCount++;
    });
  }

  void _decrementAdultCount() {
    if (_adultCount > 1) {
      setState(() {
        _adultCount--;
      });
    }
  }

  void _incrementChildCount() {
    setState(() {
      _childCount++;
    });
  }

  void _decrementChildCount() {
    if (_childCount > 0) {
      setState(() {
        _childCount--;
      });
    }
  }

  void _showSaveDiscardDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save?'),
          content: const Text('Do you want to save?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the previous screen
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToNextPage() {
    if (_isNextButtonEnabled) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PersonalizedQuestion(
            tripName: _tripNameController.text,
            destination: _destinationController.text,
            departureDate: _departureDate,
            departureTime: _departureTime,
            returnDate: _returnDate,
            returnTime: _returnTime,
            adultCount: _adultCount,
            childCount: _childCount,
            transportation: _transportationController.text,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all the fields.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFFA0CDC3),
        title: Text("Create a trip"),
        leading: IconButton(onPressed: _showSaveDiscardDialog, icon: Icon(Icons.arrow_back)),
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
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _tripNameController,
                  decoration: InputDecoration(
                  labelText: 'Trip name',
                  labelStyle: TextStyle(
                    color: Colors.black,
                  )
                  ),
                onChanged: (_) => _checkIfAllFieldsFilled(),
              ),
              SizedBox(height: 16.0,),
              TextFormField(
                controller: _destinationController,
                  decoration: InputDecoration(
                  labelText: 'Destination',
                  labelStyle: TextStyle(
                    color: Colors.black,
                  )
                  ),
                onChanged: (_) => _checkIfAllFieldsFilled(),
              ),
              SizedBox(height: 16.0,),
              Row(
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDepartureDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Departure Date',
                          labelStyle: TextStyle(
                            color: Colors.black,
                          )
                          ),
                        child: Text(_departureDate == null ? 'Select date' : DateFormat('yyyy-MM-dd').format(_departureDate!))
                      ),
                    ),
                  ),
                  SizedBox(width: 16.0,),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDepartureTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Departure Time',
                          labelStyle: TextStyle(
                            color: Colors.black,
                          )
                          ),
                        child: Text(_departureTime == null ? 'Select time' : _departureTime!.format(context)),
                      )
                    ),
                  )
                ]
              ),
              SizedBox(height: 16.0,),
              Row(
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectReturnDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Return Date',
                          labelStyle: TextStyle(
                            color: Colors.black,
                          )
                          ),
                        child: Text(_returnDate == null ? 'Select date' : DateFormat('yyyy-MM-dd').format(_returnDate!))
                      ),
                    ),
                  ),
                  SizedBox(width: 16.0,),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectReturnTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Return Time',
                          labelStyle: TextStyle(
                            color: Colors.black,
                          )
                          ),
                        child: Text(_returnTime == null ? 'Select time' : _returnTime!.format(context)),
                      )
                    ),
                  )
                ]
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Adults'),
                  Row(
                    children: <Widget>[
                      IconButton(onPressed: _decrementAdultCount, icon: Icon(Icons.remove)),
                      Text('$_adultCount'),
                      IconButton(onPressed: _incrementAdultCount, icon: Icon(Icons.add)),
                    ],
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Children'),
                  Row(
                    children: <Widget>[
                      IconButton(onPressed: _decrementChildCount, icon: Icon(Icons.remove)),
                      Text('$_childCount'),
                      IconButton(onPressed: _incrementChildCount, icon: Icon(Icons.add)),
                    ],
                  )
                ],
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _transportationController,
                decoration: InputDecoration(
                  labelText: 'Preferred transportation',
                  labelStyle: TextStyle(
                    color: Colors.black,
                  )
                ),
                onChanged: (_) => _checkIfAllFieldsFilled(),
              ),
              SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: _isNextButtonEnabled ? _navigateToNextPage : null,
                child: const Text('Next'),
              ),
            ],
          )
        ),
      ),
      ),
      ),
    );
  }
}