import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../widgets/circular_avatar.dart';
import '../providers/user_provider.dart';

class CompanionCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const CompanionCard({super.key, required this.data});

  @override
  State<CompanionCard> createState() => _CompanionCardState();
}

class _CompanionCardState extends State<CompanionCard> {
  bool isRequested = false;
  bool isMember = false;

  @override
  void initState() {
    super.initState();
    checkGroupStatus();
  }

  Future<void> checkGroupStatus() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.id;
    final groupId = widget.data['groupId'];
    if (userId == null || groupId == null) return;

    final groupUrl = 'https://sportface-f9594-default-rtdb.firebaseio.com/groups/$groupId.json';

    final res = await http.get(Uri.parse(groupUrl));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List members = data['members'] ?? [];
      final Map requests = data['requests'] ?? {};

      setState(() {
        isMember = members.contains(userId);
        isRequested = requests.containsKey(userId);
      });
    }
  }

  Future<void> sendJoinRequest() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.id;
    final groupId = widget.data['groupId'];
    if (userId == null || groupId == null) return;

    final url = Uri.parse('https://sportface-f9594-default-rtdb.firebaseio.com/groups/$groupId/requests/$userId.json');

    final res = await http.put(url, body: jsonEncode(true));
    if (res.statusCode == 200) {
      setState(() {
        isRequested = true;
      });
    }
  }

  String getSportImage(String sport) {
    final lowerSport = sport.toLowerCase();
    final sportMap = {
      'cricket': 'assets/images/cricket.png',
      'football': 'assets/images/football.png',
      'badminton': 'assets/images/badminton.png',
      'tennis': 'assets/images/tennis.png',
      'basketball': 'assets/images/basketball.png',
    };
    return sportMap[lowerSport] ?? 'assets/images/default_sport.png';
  }

  @override
  Widget build(BuildContext context) {
    final organiserId = widget.data['createdBy'] ?? '';
    final sport = widget.data['sport'] ?? 'Unknown';
    final city = widget.data['city'] ?? 'Unknown City';
    final groupName = widget.data['groupName'] ?? 'Unnamed Group';
    final date = widget.data['date'] ?? 'N/A';
    final gender = widget.data['gender'] ?? 'N/A';
    final age = widget.data['ageLimit'] ?? 'N/A';
    final type = widget.data['type'] ?? 'N/A';
    final venue = widget.data['eventVenue'] ?? 'N/A';

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Stack(
          children: [
            // Avatar top right
            Positioned(
              top: 0,
              right: 0,
              child: CircularAvatar(imageUrl: '', userId: organiserId),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sport image top left
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        getSportImage(sport),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        groupName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _buildInfoChip(Icons.sports, sport),
                    _buildInfoChip(Icons.location_on, city),
                    _buildInfoChip(Icons.group, gender),
                    _buildInfoChip(Icons.cake, age),
                    _buildInfoChip(Icons.attach_money, type),
                    _buildInfoChip(Icons.calendar_today, date),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Venue: $venue",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                if (!isMember)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: isRequested ? null : sendJoinRequest,
                      icon: const Icon(Icons.send),
                      label: Text(isRequested ? "Requested" : "Request"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                else
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "You're a member",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
      avatar: Icon(icon, size: 16, color: Colors.black54),
      backgroundColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
