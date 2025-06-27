import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/companion_data.dart';
import '../widgets/companion_card.dart';
import '../widgets/circular_avatar.dart';
import '../model/companion_model.dart';
import '../providers/user_provider.dart';
import 'create_requirement_form.dart';
import 'view_groups_screen.dart';
import 'profile_screen.dart';
import '../services/location_filter_service.dart';

class Home_Sport extends StatefulWidget {
  final String initialUser;

  const Home_Sport({super.key, required this.initialUser});

  @override
  State<Home_Sport> createState() => _Home_SportState();
}

class _Home_SportState extends State<Home_Sport> {
  String? selectedCity;
  String? selectedSport;
  String? selectedGender;
  String? selectedAgeLimit;
  String? selectedPaidStatus;
  DateTime? selectedDate;
  double distanceFilterKm = 0;
  late String currentUser;

  List<CompanionModel> filteredData = companionData;
  final LocationFilterService _locationService = LocationFilterService();

  final TextEditingController dateController = TextEditingController();
  final TextEditingController newUserController = TextEditingController();

  final List<String> allCities = {...companionData.map((e) => e.city)}.toList();

  @override
  void initState() {
    super.initState();
    currentUser = widget.initialUser;
    print("HomeScreen: Initialized with currentUser = $currentUser");
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _applyFilter() async {
    setState(() {
      filteredData = companionData;
    });

    final distanceFilteredData = await _locationService.filterByDistance(distanceFilterKm);

    setState(() {
      filteredData = distanceFilteredData.where((item) {
        final matchesCity = distanceFilterKm == 0 ? (selectedCity == null || item.city == selectedCity) : true;
        final matchesSport = selectedSport == null || item.sportName == selectedSport;
        final matchesDate = selectedDate == null || item.date == dateController.text;
        final matchesGender = selectedGender == null || item.gender == selectedGender;
        final matchesAge = selectedAgeLimit == null || item.ageLimit == selectedAgeLimit;
        final matchesPaid = selectedPaidStatus == null || item.paidStatus == selectedPaidStatus;

        return matchesCity && matchesSport && matchesDate && matchesGender && matchesAge && matchesPaid;
      }).toList();

      if (distanceFilterKm > 0) {
        final userLocation = _locationService.getUserLocation();
        userLocation.then((location) {
          if (location == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Location permission denied. Showing all results.")),
            );
          }
        });
      }
    });
  }

  void _resetFilter() {
    setState(() {
      selectedCity = null;
      selectedSport = null;
      selectedDate = null;
      selectedGender = null;
      selectedAgeLimit = null;
      selectedPaidStatus = null;
      distanceFilterKm = 0;
      dateController.clear();
      filteredData = companionData;
    });
  }

  void _createUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create New User"),
        content: TextField(
          controller: newUserController,
          decoration: const InputDecoration(
            labelText: "User Name",
            hintText: "e.g., Amit Sharma",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final newUser = newUserController.text.trim();
              if (newUser.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User name cannot be empty")),
                );
                return;
              }
              if (availableUsers.any((user) => user.toLowerCase() == newUser.toLowerCase())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User name already exists")),
                );
                return;
              }
              setState(() {
                availableUsers.add(newUser);
                currentUser = newUser;
                newUserController.clear();
                print("Created user: $newUser, currentUser: $currentUser");
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("User $newUser created!")),
              );
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _switchUser(String? newUser) {
    if (newUser != null) {
      setState(() {
        currentUser = newUser;
        print("Switched to user: $currentUser");
      });
    }
  }

  Widget _buildDropdown(String label, String? value, List<String> options, Function(String?) onChanged) {
    return SizedBox(
      width: 140,
      child: DropdownButtonFormField<String>(
        value: value,
        items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        ),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }

  Widget _buildDateField() {
    return SizedBox(
      width: 140,
      child: TextField(
        controller: dateController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: "Date",
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        ),
        onTap: _pickDate,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Find Sport Companions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF5E35B1),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularAvatar(imageUrl: user?.imageUrl, userId: user?.id),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _createUser,
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.person_add, size: 18, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "Create User",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: currentUser,
                      items: availableUsers
                          .map((user) => DropdownMenuItem(
                                value: user,
                                child: Text(
                                  user,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ))
                          .toList(),
                      onChanged: _switchUser,
                      isDense: true,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "User",
                        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        prefixIcon: const Icon(Icons.person, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                      ),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateRequirementForm(
                              currentUser: currentUser,
                              onCreate: (CompanionModel newCompanion, GroupModel newGroup) {
                                setState(() {
                                  companionData.add(newCompanion);
                                  groupData.add(newGroup);
                                  filteredData = companionData;
                                  print(
                                      "Added to groupData: ${newGroup.groupId}, Name: ${newGroup.groupName}, Organiser: ${newGroup.organiserName}");
                                  logGroupData("After adding group in home");
                                });
                              },
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5E35B1),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add, size: 18, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "Create Requirement",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ViewGroupsScreen(
                              key: UniqueKey(),
                              currentUser: currentUser,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF546E7A),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.group, size: 18, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "View Group",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Filter Companions",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDropdown("City", selectedCity, allCities, (val) => setState(() => selectedCity = val)),
                          const SizedBox(width: 8),
                          _buildDropdown(
                              "Sport",
                              selectedSport,
                              ["Football", "Cricket", "Badminton", "Chess", "Carrom", "PUBG"],
                              (val) => setState(() => selectedSport = val)),
                          const SizedBox(width: 8),
                          _buildDropdown("Gender", selectedGender, ["All", "Male", "Female"],
                              (val) => setState(() => selectedGender = val)),
                          const SizedBox(width: 8),
                          _buildDropdown("Age Limit", selectedAgeLimit, ["18-25", "26-33", "34-40", "40+"],
                              (val) => setState(() => selectedAgeLimit = val)),
                          const SizedBox(width: 8),
                          _buildDropdown("Type", selectedPaidStatus, ["Paid", "Unpaid"],
                              (val) => setState(() => selectedPaidStatus = val)),
                          const SizedBox(width: 8),
                          _buildDateField(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Distance: ${distanceFilterKm.toStringAsFixed(0)} km",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                          ),
                          Slider(
                            value: distanceFilterKm,
                            min: 0,
                            max: 100,
                            divisions: 100,
                            label: "${distanceFilterKm.toStringAsFixed(0)} km",
                            activeColor: const Color(0xFF1976D2),
                            inactiveColor: Colors.grey[300],
                            onChanged: (value) {
                              setState(() {
                                distanceFilterKm = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _applyFilter,
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "Apply Filter",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _resetFilter,
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "Reset Filter",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (filteredData.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      "No companions match your filters.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                )
              else
                ListView.builder(
                  itemCount: filteredData.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final companion = filteredData[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: CompanionCard(
                        data: companion,
                        currentUser: currentUser,
                        onReadMorePressed: () {},
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
