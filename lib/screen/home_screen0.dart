import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../widgets/companion_card.dart';
import 'create_requirement_form.dart';
import 'view_groups_screen.dart';
import '../providers/user_provider.dart';

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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    print("INIT: SportMainScreen started");
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    print("FETCHING DATA from Firebase...");

    try {
      final url = Uri.parse('https://sportface-f9594-default-rtdb.firebaseio.com/requirements.json');
      final response = await http.get(url);
      print("HTTP Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("Decoded JSON: $decoded");

        if (decoded != null && decoded is Map<String, dynamic>) {
          final items = decoded.entries.map((e) => {'id': e.key, ...e.value}).toList();
          print("Parsed ${items.length} requirement items");

          setState(() {
            allData = items;
            filteredData = items;
          });
        } else {
          print("Firebase response empty or not a Map.");
          setState(() {
            allData = [];
            filteredData = [];
          });
        }
      } else {
        throw Exception('Failed to fetch: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to fetch requirements: $e")));
      setState(() {
        allData = [];
        filteredData = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
      print("FETCH DONE: isLoading = false");
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
        item['date'] != null &&
        item['date'] == DateFormat('yyyy-MM-dd').format(selectedDate!)).toList();
    }

    print("FILTERS APPLIED: ${results.length} items after filtering");

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
    print("BUILD: SportMainScreen UI rendering...");
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      appBar: AppBar(title: const Text("Find Sport Companions")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateRequirementScreen()),
                          );
                          await fetchData();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Create Requirement"),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ViewGroupsScreen()),
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
                        items: ['All', 'Male', 'Female']
                            .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                            .toList(),
                        onChanged: (val) => setState(() => gender = val!),
                        decoration: const InputDecoration(labelText: 'Gender'),
                      ),
                      DropdownButtonFormField(
                        value: age,
                        items: ['All', '18-25', '26-33', '34-40', '40+']
                            .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                            .toList(),
                        onChanged: (val) => setState(() => age = val!),
                        decoration: const InputDecoration(labelText: 'Age Limit'),
                      ),
                      DropdownButtonFormField(
                        value: type,
                        items: ['All', 'Paid', 'Unpaid']
                            .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                            .toList(),
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
                            setState(() => selectedDate = picked);
                          }
                        },
                      ),
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

                      if (filteredData.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: Text("No companions found")),
                        )
                      else
                        ...filteredData.map((item) {
                          print("RENDERING ITEM: ${item['groupName']} (${item['sport']})");
                          return CompanionCard(data: item);
                        }).toList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
