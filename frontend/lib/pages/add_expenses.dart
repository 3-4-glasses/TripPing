import 'package:apacsolchallenge/data/global_trip_data.dart';
import 'package:flutter/material.dart';
import '../data/trip_data.dart';

class AddExpenses extends StatefulWidget {
  const AddExpenses({super.key, required this.tripId});

  final String tripId;

  @override
  State<AddExpenses> createState() => _AddExpensesState();
}

class _AddExpensesState extends State<AddExpenses> {
  final _formKey = GlobalKey<FormState>();
  final _expenseNameController = TextEditingController();
  final _expenseAmountController = TextEditingController();
  late Trip _trip;

  @override
  void initState() {
    super.initState();
    _trip = GlobalTripData.instance.tripData.trips.value.firstWhere((trip) => trip.id == widget.tripId);
  }

  @override
  void dispose() {
    _expenseNameController.dispose();
    _expenseAmountController.dispose();
    super.dispose();
  }

  void _addExpense() {
    if (_formKey.currentState!.validate()) {
      final expenseName = _expenseNameController.text;
      final expenseAmount = double.parse(_expenseAmountController.text);

      // Add new expense. Access the value of the ValueNotifier.
      _trip.variableExpenses.value?.add({
        'item': expenseName,
        'price': expenseAmount,
      });
      //update the ValueNotifier
      _trip.variableExpenses.notifyListeners();

      // Update expensesUsed:  Add to the current value, don't overwrite.
      _trip.expensesUsed.value += expenseAmount; // Add the new amount
      GlobalTripData.instance.notifyListeners();

      setState(() {
        _expenseNameController.clear();
        _expenseAmountController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Expenses')
      ), 
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  controller: _expenseNameController,
                  decoration: InputDecoration(labelText: "Expense Name"),
                  validator: (value) {
                    if (value == null || value.isEmpty){
                      return 'Please enter expense name';
                    }
                    return null; 
                  },
                ),
                TextFormField(
                  controller: _expenseAmountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Total Expense'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter expense amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addExpense,
                  child: const Text('Add Expense'),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}
