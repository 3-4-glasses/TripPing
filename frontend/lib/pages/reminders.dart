import 'package:flutter/material.dart';
import '../data/global_trip_data.dart';
import '../data/trip_data.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key, required this.trip, this.onReminderAdded});

  final Trip trip;
  final VoidCallback? onReminderAdded;

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  //final ReminderService _reminderService = ReminderService();  <--  NO LONGER USED
  //late List<Reminder> _displayedReminders;  <-- NO LONGER USED
  late List<String> _displayedItems; // Use this to hold the item names.
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  void _loadReminders() {
    setState(() {
      _isLoading = true;
    });
    //_reminderService.loadReminders();  <--  NO LONGER USED
    _displayedItems = List.from(widget.trip.items.value); // Get from the Trip
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void didUpdateWidget(covariant RemindersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadReminders(); //  Always reload when the widget updates.
  }

  // Add item to the trip's items list
  Future<void> _addItem(String text) async {
    if (text.trim().isEmpty) return;

    // IMPORTANT:  Update the Trip's ValueNotifier<List<String>>
    List<String> currentItems = List.from(widget.trip.items.value); // Get a copy
    currentItems.add(text.trim()); // Add the new item
    widget.trip.items.value = currentItems; // Update the ValueNotifier

    //  Persist the change (if needed)  <--  You might have your own persistence.
    // await _saveTripItems();  //  <--  Adapt this if you have custom saving.

    GlobalTripData.instance.notifyListeners(); // Notify
    _loadReminders(); // Keep UI in sync.
  }

  // Delete item from trip's items list
  Future<void> _deleteItem(String itemText) async {
    // IMPORTANT: Update the Trip's ValueNotifier<List<String>>
    List<String> currentItems = List.from(widget.trip.items.value);
    currentItems.remove(itemText);
    widget.trip.items.value = currentItems;

    // Persist the change (if needed)
    // await _saveTripItems();  // <-- Adapt
    GlobalTripData.instance.notifyListeners();
    _loadReminders();
  }

  // Save trip items.  You'll need to adapt this to your persistence mechanism.
  // Future<void> _saveTripItems() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final tripItemsJson = jsonEncode(widget.trip.items.value); //  <--  Use jsonEncode
  //   await prefs.setString('trip_items_${widget.trip.id}', tripItemsJson); //  <--  Key by trip ID
  // }

  @override
  Widget build(BuildContext context) {
    //_displayedReminders = _reminderService.getRemindersForTrip(widget.tripId);  <-- NO
    //_displayedReminders = _reminderService.reminders;  <-- NO
    //_displayedItems = List.from(widget.trip.items.value); // Get from Trip  <-- YES, in initState

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Reminders'),
        actions: [
          // No Clear Completed.
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                  child: Text(
                    'Reminders for Trip: ${widget.trip.name.value}', // Show trip name
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _displayedItems.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No reminders yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _displayedItems.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _displayedItems[index];
                            return ReminderListItem( //  Use the adapted one.
                              itemText: item,
                              onDelete: () {
                                _deleteItem(item); //  Use the new _deleteItem
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Show a dialog to get the new reminder text.
          final result = await showDialog<String>(
            context: context,
            builder: (context) => const AddReminderDialog(),
          );

          if (result != null && result.trim().isNotEmpty) {
            _addItem(result); //  Use the new _addItem
            widget.onReminderAdded?.call();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Add new reminder',
      ),
    );
  }
}

// Adapted Reminder List Item
class ReminderListItem extends StatelessWidget {
  const ReminderListItem({
    super.key,
    required this.itemText,
    required this.onDelete,
  });

  final String itemText;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(itemText), // Use itemText as the key
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDelete();
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.check_circle_outline), //  No checkbox.
        title: Text(
          itemText,
          style: const TextStyle(
            fontSize: 16.0,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
          ),
          onPressed: onDelete,
        ),
      ),
    );
  }

  // No date formatting needed.
}

// Add Reminder Dialog
class AddReminderDialog extends StatefulWidget {
  const AddReminderDialog({super.key});

  @override
  _AddReminderDialogState createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Reminder'),
      content: TextField(
        controller: _textEditingController,
        decoration: const InputDecoration(
          labelText: 'What do you need to remember?',
          border: OutlineInputBorder(),
          hintText: 'Enter your reminder here',
        ),
        maxLines: 3,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) {
          Navigator.of(context).pop(_textEditingController.text);
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_textEditingController.text);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}