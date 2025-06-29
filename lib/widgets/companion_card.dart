import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../widgets/circular_avatar.dart';
import '../providers/user_provider.dart';
import '../screen/profile_screen1.dart';

class CompanionCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const CompanionCard({super.key, required this.data});

  @override
  State<CompanionCard> createState() => _CompanionCardState();
}

class _CompanionCardState extends State<CompanionCard> {
  bool isRequested = false;
  bool isMember = false;
  bool isExpired = false;
  Timer? countdownTimer;
  Duration? remainingTime;
  List<String> debugLogs = [];
  bool showLogs = false;

  void log(String msg) {
    debugPrint(msg);
    setState(() {
      debugLogs.add("[${DateTime.now().toIso8601String().split('T')[1].split('.').first}] $msg");
      if (debugLogs.length > 50) debugLogs.removeAt(0);
    });
  }

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
  }

  Future<void> checkGroupStatus() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.id;
    final groupId = widget.data['groupId'];
    if (userId == null || groupId == null) return;

    final url = Uri.parse(
        'https://sportface-f9594-default-rtdb.firebaseio.com/groups/$groupId.json');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final members = List.from(data['members'] ?? []);
        final requests = Map<String, dynamic>.from(data['requests'] ?? {});

        setState(() {
          isMember = members.contains(userId);
          isRequested = requests.containsKey(userId);
        });

        log("✅ Group status: member=$isMember, requested=$isRequested");
      } else {
        log("❌ Failed to fetch group status (${res.statusCode})");
      }
    } catch (e) {
      log("❌ Error checking group status: $e");
    }
  }

  Future<void> sendJoinRequest() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.id;
    final groupId = widget.data['groupId'];
    final organiserId = widget.data['createdBy'];

    if (userId == null || groupId == null || organiserId == null) return;

    if (userId == organiserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You are the organiser.")),
      );
      return;
    }

    final url = Uri.parse(
        'https://sportface-f9594-default-rtdb.firebaseio.com/groups/$groupId/requests/$userId.json');

    try {
      final res = await http.put(url, body: jsonEncode(true));
      if (res.statusCode == 200) {
        setState(() => isRequested = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request sent to the organiser.")),
        );
        log("✅ Join request sent successfully.");
      } else {
        log("❌ Failed to send request: ${res.statusCode}");
      }
    } catch (e) {
      log("❌ Exception during request: $e");
    }
  }

  String formatDuration(Duration? d) {
    if (d == null) return "--:--:--";
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
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

    final data = widget.data;
    final organiserId = data['createdBy'] ?? '';
    final sport = data['sport'] ?? 'Unknown';
    final groupName = data['groupName'] ?? 'Unnamed Group';
    final city = data['city'] ?? 'Unknown';
    final gender = data['gender'] ?? '';
    final age = data['ageLimit']?.toString() ?? '';
    final type = data['type'] ?? '';
    final date = data['date'] ?? '';
    final startTime = data['startTime'] ?? '';
    final eventVenue = data['eventVenue'] ?? '';
    final meetVenue = data['meetVenue'] ?? '';
    Duration? duration;
    try {
      final timestamp = DateTime.tryParse(data['timestamp'] ?? '');
      final end = DateTime.tryParse(data['endTime'] ?? '');
      if (timestamp != null && end != null) {
        duration = end.difference(timestamp);
      }
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(getSportImage(sport),
                      width: 60, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    groupName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse(
                        'https://sportface-f9594-default-rtdb.firebaseio.com/users/$organiserId.json');
                    final res = await http.get(url);
                    if (res.statusCode == 200) {
                      final organiser = jsonDecode(res.body);
                      showDialog(
                        context: context,
                        builder: (_) => ProfileScreenLite(
                          name: organiser['name'] ?? '',
                          email: organiser['email'] ?? '',
                          age: organiser['age']?.toString() ?? '',
                          imageUrl: organiser['imageUrl'],
                        ),
                      );
                    }
                  },
                  child: CircularAvatar(userId: organiserId),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _chip(Icons.sports, sport),
                _chip(Icons.location_city, city),
                _chip(Icons.group, gender),
                _chip(Icons.cake, age),
                _chip(Icons.attach_money, type),
                _chip(Icons.date_range, date),
                _chip(Icons.timer, "⏱ ${formatDuration(remainingTime)}"),
                _chip(Icons.schedule, "Start: $startTime"),
                _chip(Icons.timelapse, "Duration: ${duration?.inHours ?? '?'} hr"),
              ],
            ),
            const SizedBox(height: 10),
            Text("📍 Meet Venue: $meetVenue", style: _venueStyle()),
            Text("🎯 Event Venue: $eventVenue", style: _venueStyle()),
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
                child: Text("✅ You're a member", style: TextStyle(color: Colors.green)),
              ),
            GestureDetector(
              onTap: () => setState(() => showLogs = !showLogs),
              child: const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: Text("🔽 Toggle Logs", style: TextStyle(color: Colors.blue)),
              ),
            ),
            if (showLogs)
              Container(
                padding: const EdgeInsets.all(6),
                color: Colors.grey.shade200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: debugLogs
                      .map((e) => Text(e, style: const TextStyle(fontSize: 11)))
                      .toList(),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.black54),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      backgroundColor: Colors.grey.shade200,
    );
  }

  TextStyle _venueStyle() => const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
}
