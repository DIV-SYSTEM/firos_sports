import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/circular_avatar.dart';
import '../providers/user_provider.dart';

class CompanionCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const CompanionCard({super.key, required this.data});

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
    final currentUserId = Provider.of<UserProvider>(context).user?.id;
    final organiserId = data['createdBy'] ?? '';
    final sport = data['sport'] ?? 'Unknown';
    final city = data['city'] ?? 'Unknown City';
    final groupName = data['groupName'] ?? 'Unnamed Group';
    final date = data['date'] ?? 'N/A';
    final gender = data['gender'] ?? 'N/A';
    final age = data['ageLimit'] ?? 'N/A';
    final type = data['type'] ?? 'N/A';
    final venue = data['eventVenue'] ?? 'N/A';

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
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement request logic
                      debugPrint('Request sent by $currentUserId to $organiserId');
                    },
                    icon: const Icon(Icons.send),
                    label: const Text("Request"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
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
