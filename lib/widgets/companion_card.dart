import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../widgets/circular_avatar.dart';
import '../providers/user_provider.dart';
import '../screen/profile_screen1.dart'; // 👈 New popup screen

class CompanionCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const CompanionCard({super.key, required this.data});

  @override
  State<CompanionCard> createState() => _CompanionCardState();
}

class _CompanionCardState extends State<CompanionCard> {
  bool isRequested = false;
  bool isMember = false;
  Timer? countdownTimer;
  Duration? remainingTime;
  bool isExpired = false;

  @override
  void initState() {
    super.initState();
    checkGroupStatus();
    startCountdown();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    try {
      final end = DateTime.tryParse(widget.data['endTime'] ?? '');
      if (end == null) return;

      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final diff = end.difference(now);
        if (diff.isNegative) {
          timer.cancel();
          if (mounted) setState(() => isExpired = true);
        } else {
          if (mounted) setState(() => remainingTime = diff);
        }
      });
    } catch (e) {
      debugPrint("❌ Countdown error: $e");
    }
  }

  Future<void> checkGroupStatus() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.id;
    final groupId = widget.data['groupId'];
    if (userId == null || groupId == null) return;

    final groupUrl =
        'https://sportface-f9594-default-rtdb.firebaseio.com/groups/$groupId.json';

    try {
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
    } catch (e) {
      debugPrint("❌ Group status check failed: $e");
    }
  }

  Future<void> sendJoinRequest() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.id;
    final groupId = widget.data['groupId'];
    if (userId == null || groupId == null) return;

    final url = Uri.parse(
        'https://sportface-f9594-default-rtdb.firebaseio.com/groups/$groupId/requests/$userId.json');

    try {
      final res = await http.put(url, body: jsonEncode(true));
      if (res.statusCode == 200) {
        setState(() => isRequested = true);
      }
    } catch (e) {
      debugPrint("❌ Failed to send request: $e");
    }
  }

  Future<void> showOrganiserProfile(BuildContext context, String organiserId) async {
    try {
      debugPrint("📥 Fetching organiser: $organiserId");
      final url = Uri.parse('https://sportface-f9594-default-rtdb.firebaseio.com/users/$organiserId.json');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        debugPrint("✅ Organiser data: $data");

        if (data != null) {
          showDialog(
            context: context,
            builder: (_) => ProfileScreenLite(
              name: data['name'] ?? 'N/A',
              email: data['email'] ?? 'N/A',
              age: data['age']?.toString() ?? 'N/A',
              imageUrl: data['imageUrl'],
            ),
          );
        } else {
          debugPrint("⚠️ No organiser data found");
          _showErrorDialog(context, "User not found.");
        }
      } else {
        debugPrint("❌ HTTP error ${res.statusCode}");
        _showErrorDialog(context, "Failed to fetch user.");
      }
    } catch (e) {
      debugPrint("❌ Exception in organiser fetch: $e");
      _showErrorDialog(context, "Something went wrong.");
    }
  }

  void _showErrorDialog(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  String formatDuration(Duration? d) {
    if (d == null) return '--';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String getSportImage(String sport) {
    final lower = sport.toLowerCase();
    return {
      'cricket': 'assets/images/cricket.jpg',
      'football': 'assets/images/football.jpg',
      'badminton': 'assets/images/badminton.jpg',
      'tennis': 'assets/images/tennis.png',
      'basketball': 'assets/images/basketball.png',
    }[lower] ?? 'assets/images/default_sport.png';
  }

  @override
  Widget build(BuildContext context) {
    if (isExpired) return const SizedBox.shrink();

    final organiserId = widget.data['createdBy'] ?? '';
    final sport = widget.data['sport'] ?? 'Unknown';
    final city = widget.data['city'] ?? 'Unknown City';
    final groupName = widget.data['groupName'] ?? 'Unnamed Group';
    final date = widget.data['date'] ?? 'N/A';
    final gender = widget.data['gender'] ?? 'N/A';
    final age = widget.data['ageLimit']?.toString() ?? 'N/A';
    final type = widget.data['type'] ?? 'N/A';
    final meetVenue = widget.data['meetVenue'] ?? 'N/A';
    final eventVenue = widget.data['eventVenue'] ?? 'N/A';
    final startTime = widget.data['startTime'] ?? 'N/A';

    Duration? duration;
    try {
      final timestamp = DateTime.tryParse(widget.data['timestamp'] ?? '');
      final end = DateTime.tryParse(widget.data['endTime'] ?? '');
      if (timestamp != null && end != null) {
        duration = end.difference(timestamp);
      }
    } catch (_) {}

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Stack(
          children: [
            // 👤 Organiser avatar
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => showOrganiserProfile(context, organiserId),
                child: CircularAvatar(imageUrl: '', userId: organiserId),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    _buildInfoChip(Icons.location_city, city),
                    _buildInfoChip(Icons.group, gender),
                    _buildInfoChip(Icons.cake, age),
                    _buildInfoChip(Icons.attach_money, type),
                    _buildInfoChip(Icons.calendar_today, date),
                    _buildInfoChip(Icons.schedule, "Start: $startTime"),
                    _buildInfoChip(Icons.timelapse, "Duration: ${duration?.inHours ?? '?'} hr"),
                    _buildInfoChip(Icons.timer, "⏱ ${formatDuration(remainingTime)} left"),
                  ],
                ),
                const SizedBox(height: 10),
                Text("📍 Meet Venue: $meetVenue", style: _venueTextStyle()),
                Text("🎯 Event Venue: $eventVenue", style: _venueTextStyle()),
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
                      "✅ You're a member",
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

  TextStyle _venueTextStyle() {
    return const TextStyle(
      fontSize: 14,
      color: Colors.black87,
      fontWeight: FontWeight.w500,
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
