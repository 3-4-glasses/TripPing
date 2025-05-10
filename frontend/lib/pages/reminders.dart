import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Enhanced Reminder data class
class Reminder {
  final String id;
  final String text;
  final DateTime createdAt;
  bool isCompleted;

  Reminder({
    required this.id,
    required this.text,
    required this.createdAt,
    this.isCompleted = false,
  });

  // Convert reminder to a Map for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  // Create a Reminder from JSON
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

// Reminder service to manage state
class ReminderService {
  static const String _storageKey = 'reminders';
  List<Reminder> _reminders = [];

  // Singleton pattern
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  List<Reminder> get reminders => _reminders;

  // Load reminders from local storage
  Future<void> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList(_storageKey);
    
    if (remindersJson != null) {
      _reminders = remindersJson
          .map((item) => Reminder.fromJson(jsonDecode(item)))
          .toList();
    } else {
      // Default reminders for first launch
      _reminders = [
        Reminder(id: '1', text: 'Book flight', createdAt: DateTime.now()),
        Reminder(id: '2', text: 'Pack passport', createdAt: DateTime.now()),
        Reminder(id: '3', text: 'Reserve hotel', createdAt: DateTime.now()),
      ];
      await _saveReminders();
    }
  }

  // Save reminders to local storage
  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = _reminders
        .map((reminder) => jsonEncode(reminder.toJson()))
        .toList();
    
    await prefs.setStringList(_storageKey, remindersJson);
  }

  // Add a new reminder
  Future<void> addReminder(String text) async {
    final newReminder = Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      createdAt: DateTime.now(),
    );
    
    _reminders.add(newReminder);
    await _saveReminders();
  }

  // Delete a reminder
  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((reminder) => reminder.id == id);
    await _saveReminders();
  }

  // Toggle reminder completion status
  Future<void> toggleCompletion(String id) async {
    final index = _reminders.indexWhere((reminder) => reminder.id == id);
    if (index != -1) {
      _reminders[index].isCompleted = !_reminders[index].isCompleted;
      await _saveReminders();
    }
  }

  // Clear all completed reminders
  Future<void> clearCompleted() async {
    _reminders.removeWhere((reminder) => reminder.isCompleted);
    await _saveReminders();
  }
}

// Main App
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load reminders before starting the app
  final reminderService = ReminderService();
  await reminderService.loadReminders();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminders App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const RemindersPage(),
    );
  }
}

// Enhanced Reminders Page
class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final ReminderService _reminderService = ReminderService();
  
  @override
  Widget build(BuildContext context) {
    // Get all reminders
    final displayedReminders = _reminderService.reminders;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          // Clear completed button
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: () async {
              final hasCompleted = _reminderService.reminders
                  .any((reminder) => reminder.isCompleted);
              
              if (hasCompleted) {
                await _reminderService.clearCompleted();
                setState(() {});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Completed reminders cleared'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            tooltip: 'Clear completed',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title above the list
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              'Added items',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // List of reminders
          Expanded(
            child: displayedReminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
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
                  itemCount: displayedReminders.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final reminder = displayedReminders[index];
                    return ReminderListItem(
                      reminder: reminder,
                      onDelete: () async {
                        await _reminderService.deleteReminder(reminder.id);
                        setState(() {});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reminder deleted'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      onToggle: () async {
                        await _reminderService.toggleCompletion(reminder.id);
                        setState(() {});
                      },
                    );
                  },
                ),
            ),
          ],
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to the AddReminderPage and wait for a result
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => const AddReminderPage(),
            ),
          );
          
          // If a reminder was added, refresh the UI
          if (result == true) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Add new reminder',
      ),
    );
  }
}

// Enhanced Reminder List Item
class ReminderListItem extends StatelessWidget {
  const ReminderListItem({
    super.key,
    required this.reminder,
    required this.onDelete,
    required this.onToggle,
  });

  final Reminder reminder;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(reminder.id),
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
        leading: Checkbox(
          value: reminder.isCompleted,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          reminder.text,
          style: TextStyle(
            fontSize: 16.0,
            decoration: reminder.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: reminder.isCompleted ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text(
          'Created: ${_formatDate(reminder.createdAt)}',
          style: const TextStyle(fontSize: 12),
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

  // Format the date in a more readable format
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Enhanced Add Reminder Page
class AddReminderPage extends StatefulWidget {
  const AddReminderPage({super.key});

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final TextEditingController _textEditingController = TextEditingController();
  final ReminderService _reminderService = ReminderService();
  final FocusNode _textFocusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Automatically focus the text field when the page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addReminder() async {
    final text = _textEditingController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder text cannot be empty'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _reminderService.addReminder(text);
      
      if (context.mounted) {
        Navigator.of(context).pop(true); // Return true to indicate a reminder was added
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder added'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Reminder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textEditingController,
              focusNode: _textFocusNode,
              decoration: const InputDecoration(
                labelText: 'What do you need to remember?',
                border: OutlineInputBorder(),
                hintText: 'Enter your reminder here',
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addReminder(),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _addReminder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}