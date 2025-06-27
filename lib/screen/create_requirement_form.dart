import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_dropdown.dart';
import '../providers/user_provider.dart';
import '../model/user_model.dart';

class CreateRequirementScreen extends StatefulWidget {
  const CreateRequirementScreen({Key? key}) : super(key: key);

  @override
  State<CreateRequirementScreen> createState() => _CreateRequirementScreenState();
}

class _CreateRequirementScreenState extends State<CreateRequirementScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _sportController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _eventVenueController = TextEditingController();
  final TextEditingController _meetVenueController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  String? _selectedDescription;
  String? _selectedGender;
  String? _selectedAge;
  String? _selectedType;
  DateTime? _selectedDate;
  double _timerHours = 1;

  final List<String> descriptionOptions = [
    'Looking for professional companion',
    'Looking for a solo companion',
    'Looking for an online companion',
    'Looking for multiple companions'
  ];

  final List<String> genderOptions = ['All', 'Male', 'Female'];
  final List<String> ageOptions = ['18-25', '26-33', '34-40', '40+'];
  final List<String> typeOptions = ['Paid', 'Unpaid'];

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      controller.text = picked.format(context);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _showAlert(String title, String message) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
      ),
    );
  }

  Future<void> _submitForm() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;

    if (user == null) {
      await _showAlert("Error", "User is not logged in. Please login or register first.");
      return;
    }

    if (_formKey.currentState!.validate() &&
        _selectedDescription != null &&
        _selectedGender != null &&
        _selectedAge != null &&
        _selectedType != null &&
        _selectedDate != null &&
        _startTimeController.text.isNotEmpty &&
        _endTimeController.text.isNotEmpty) {
      
      final timestamp = DateTime.now().toIso8601String();
      final requirementId = DateTime.now().millisecondsSinceEpoch.toString();

      final data = {
        "sport": _sportController.text.trim(),
        "groupName": _groupNameController.text.trim(),
        "eventVenue": _eventVenueController.text.trim(),
        "meetVenue": _meetVenueController.text.trim(),
        "city": _cityController.text.trim(),
        "description": _selectedDescription,
        "gender": _selectedGender,
        "ageLimit": _selectedAge,
        "type": _selectedType,
        "date": DateFormat('yyyy-MM-dd').format(_selectedDate!),
        "startTime": _startTimeController.text,
        "endTime": _endTimeController.text,
        "timer": _timerHours.toInt(),
        "createdBy": user.id,
        "timestamp": timestamp,
        "sportImageUrl": ""
      };

      final url = Uri.parse("https://sportface-f9594-default-rtdb.firebaseio.com/requirements/$requirementId.json");
      final groupUrl = Uri.parse("https://sportface-f9594-default-rtdb.firebaseio.com/groups/$requirementId.json");

      try {
        final response1 = await http.put(url, body: jsonEncode(data));
        if (response1.statusCode != 200) {
          await _showAlert("Requirement Upload Failed", "Status: ${response1.statusCode}\n${response1.body}");
          return;
        }

        final response2 = await http.put(groupUrl, body: jsonEncode({
          "groupName": data["groupName"],
          "createdBy": user.id,
          "members": [user.id],
          "requests": {}
        }));

        if (response2.statusCode != 200) {
          await _showAlert("Group Creation Failed", "Status: ${response2.statusCode}\n${response2.body}");
          return;
        }

        await _showAlert("Success", "Requirement and Group Created Successfully.");
        Navigator.pop(context);

      } catch (e) {
        await _showAlert("Exception", e.toString());
      }
    } else {
      await _showAlert("Form Incomplete", "Please fill all fields properly.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Requirement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _sportController,
                decoration: const InputDecoration(labelText: 'Sport'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _eventVenueController,
                decoration: const InputDecoration(labelText: 'Event Venue'),
              ),
              TextFormField(
                controller: _meetVenueController,
                decoration: const InputDecoration(labelText: 'Meet Venue'),
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              CustomDropdown(
                label: "Description",
                items: descriptionOptions,
                value: _selectedDescription,
                onChanged: (val) => setState(() => _selectedDescription = val),
              ),
              CustomDropdown(
                label: "Gender",
                items: genderOptions,
                value: _selectedGender,
                onChanged: (val) => setState(() => _selectedGender = val),
              ),
              CustomDropdown(
                label: "Age Limit",
                items: ageOptions,
                value: _selectedAge,
                onChanged: (val) => setState(() => _selectedAge = val),
              ),
              CustomDropdown(
                label: "Type",
                items: typeOptions,
                value: _selectedType,
                onChanged: (val) => setState(() => _selectedType = val),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_selectedDate != null
                    ? "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}"
                    : "Select Date"),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              TextFormField(
                controller: _startTimeController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Start Time'),
                onTap: () => _selectTime(_startTimeController),
              ),
              TextFormField(
                controller: _endTimeController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'End Time'),
                onTap: () => _selectTime(_endTimeController),
              ),
              const SizedBox(height: 16),
              Text("Card Duration (hours): ${_timerHours.toInt()}"),
              Slider(
                value: _timerHours,
                min: 1,
                max: 72,
                divisions: 71,
                label: _timerHours.toInt().toString(),
                onChanged: (value) {
                  setState(() {
                    _timerHours = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.send),
                label: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
