import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../widgets/companion_card.dart';
import 'create_requirement_form.dart';
import 'view_groups_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SportMainScreen extends StatefulWidget {
  const SportMainScreen({super.key});

  @override
  State<SportMainScreen> createState() => _SportMainScreenState();
}

class _SportMainScreenState extends State<SportMainScreen> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _sportController = TextEditingController();

  String gender = 'All';
  String age = 'All';
  String type = 'All';
  DateTime? selectedDate;
  double distance = 0;

  List<dynamic> allData = [];
  List<dynamic> filteredData = [];

  bool isDistanceActive = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final url = Uri.parse('https://sportface-f9594-default-rtdb.firebaseio.com/requirements.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final items = data.entries.map((e) => {'id': e.key, ...e.value}).toList();

      setState(() {
        allData = items;
        filteredData = items;
      });
    }
  }

  void applyFilters() {
    List<dynamic> results = List.from(allData);

    if (!isDistanceActive && _cityController.text.trim().isNotEmpty) {
      results = results.where((item) =>
          item['city'] != null &&
          item['city'].toString().toLowerCase().contains(_cityController.text.trim().toLowerCase())).toList();
    }

    if (_sportController.text.trim().isNotEmpty) {
      results = results.where((item) =>
          item['sport'] != null &&
          item['sport'].toString().toLowerCase().contains(_sportController.text.trim().toLowerCase())).toList();
    }

    if (gender != 'All') {
      results = results.where((item) => item['gender'] == gender).toList();
    }

    if (age != 'All') {
      results = results.where((item) => item['ageLimit'] == age).toList();
    }

    if (type != 'All') {
      results = results.where((item) => item['type'] == type).toList();
    }

    if (selectedDate != null) {
      results = results.where((item) =>
          item['date'] != null && item['date'] == DateFormat('yyyy-MM-dd').format(selectedDate!)).toList();
    }

    // (Optional) implement actual geolocation filtering here
    if (isDistanceActive && distance > 0) {
      // Placeholder: no-op, assume all are within range
    }

    setState(() {
      filteredData = results;
    });
  }

  void resetFilters() {
    _cityController.clear();
    _sportController.clear();
    gender = 'All';
    age = 'All';
    type = 'All';
    selectedDate = null;
    distance = 0;
    isDistanceActive = false;

    setState(() {
      filteredData = allData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text("Find Sport Companions"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequirementScreen()));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Create Requirement"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ViewGroupsScreen(
      currentUser: FirebaseAuth.instance.currentUser!.uid,
    ),
  ),
);

                  },
                  icon: const Icon(Icons.group),
                  label: const Text("View Groups"),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Text("Filter Companions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),

          // Filters
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (!isDistanceActive)
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                TextField(
                  controller: _sportController,
                  decoration: const InputDecoration(labelText: 'Sport'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField(
                  value: gender,
                  items: ['All', 'Male', 'Female'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => gender = val!),
                  decoration: const InputDecoration(labelText: 'Gender'),
                ),
                DropdownButtonFormField(
                  value: age,
                  items: ['All', '18-25', '26-33', '34-40', '40+'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => age = val!),
                  decoration: const InputDecoration(labelText: 'Age Limit'),
                ),
                DropdownButtonFormField(
                  value: type,
                  items: ['All', 'Paid', 'Unpaid'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => type = val!),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                ListTile(
                  title: Text(selectedDate != null
                      ? "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}"
                      : "Select Date"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 4),
                Text("Distance: ${distance.toInt()} km"),
                Slider(
                  value: distance,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: "${distance.toInt()} km",
                  onChanged: (val) {
                    setState(() {
                      distance = val;
                      isDistanceActive = val > 0;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: resetFilters,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Reset Filter"),
                    ),
                    ElevatedButton.icon(
                      onPressed: applyFilters,
                      icon: const Icon(Icons.filter_alt),
                      label: const Text("Apply Filter"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cards
                ...filteredData.map((item) => CompanionCard(data: item)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
