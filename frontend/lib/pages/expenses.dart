import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:apacsolchallenge/data/trip_data.dart';
import '../data/global_trip_data.dart';
import '../data/global_user.dart';
import 'package:http/http.dart' as http;


class Expenses extends StatefulWidget {
  const Expenses({super.key, required this.trip});
  final Trip trip;

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  // Access the global TripData instance
  final GlobalTripData tripDataInstance = GlobalTripData.instance;
  final TextEditingController _budgetController = TextEditingController();

  // Function to show the change budget dialog
  Future<void> _showChangeBudgetDialog(BuildContext context) async {
    // Initialize the controller with the current budget value
    _budgetController.text = widget.trip.expensesLimit.value.toString();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Budget'),
          content: TextField(
            controller: _budgetController,
            keyboardType: TextInputType.numberWithOptions(decimal: true), // For numeric input
            decoration: const InputDecoration(
              labelText: 'New Budget',
              hintText: 'Enter new budget amount',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Parse the input value and update the budget
                final newBudget = double.tryParse(_budgetController.text);
                if (newBudget != null) {
                  widget.trip.expensesLimit.value = newBudget; // Update the ValueNotifier
                  Navigator.of(context).pop(); // Close the dialog
                  tripDataInstance.notifyListeners(); // Use the instance directly
                  final res = await http.post(
                    Uri.parse('https://backend-server-412321340776.us-west1.run.app/trip/budget'),
                    headers: <String,String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body:jsonEncode(<String, dynamic>{
                      'userId':UserSession().uid,
                      'tripId':widget.trip.id,
                      'amount':newBudget
                    })
                  );
                  if(res.statusCode==200){
                    _showSnackBar("Budget updated successfully");
                  }else{
                    _showSnackBar(jsonDecode(res.body)['error']);
                  }
                } else {
                  // Show an error message if the input is invalid
                  _showSnackBar(
                      "Invalid budget amount. Please enter a valid number.");
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose(); // Dispose the controller to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFFA0CDC3),
        title: const Text('Expenses'),
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
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              "Budget",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF8F8FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  // Display the budget value
                  ValueListenableBuilder<double>(
                    valueListenable: widget.trip.expensesLimit,
                    builder: (context, budget, child) {
                      return Text("Rp. ${budget.toStringAsFixed(2)}", // Format the output
                          style: const TextStyle(fontSize: 16));
                    },
                  ),
                  const Spacer(),
                  // Open the dialog on button press
                  IconButton(
                    onPressed: () => _showChangeBudgetDialog(context),
                    icon: const Icon(Icons.edit),
                  )
                ],
              ),
            ),
            const Text("Expandables",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF8F8FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ValueListenableBuilder<double>(
                valueListenable: widget.trip.expensesLimit,
                builder: (context, limit, child) {
                  return ValueListenableBuilder<double>(
                    valueListenable: widget.trip.expensesUsed,
                    builder: (context, used, child) {
                      return Text(
                        "Rp. ${(limit - used).toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 16),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text('Set expenses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildExpenseList(widget.trip.fixedExpenses.value),
            const SizedBox(height: 20),
            const Text('Variable expenses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildExpenseList(widget.trip.variableExpenses.value),
          ],
        ),
      ),
      ),
      ),
    );
  }

  // Function to build the expense list
  Widget _buildExpenseList(List<Map<String, dynamic>>? expenses) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: (expenses == null || expenses.isEmpty)
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'There are no expenses here.',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        expense['item'] ?? 'Item', // Use 'name' key
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Rp. ${expense['price'].toStringAsFixed(2)}', // Format price
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}