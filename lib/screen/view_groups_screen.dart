import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../widgets/circular_avatar.dart';
import '../providers/user_provider.dart';
import 'chat_screen.dart';

class ViewGroupsScreen extends StatefulWidget {
  const ViewGroupsScreen({super.key});

  @override
  State<ViewGroupsScreen> createState() => _ViewGroupsScreenState();
}

class _ViewGroupsScreenState extends State<ViewGroupsScreen> {
  List<Map<String, dynamic>> userGroups = [];

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.id;
    if (userId == null) return;

    final url = Uri.parse("https://sportface-f9594-default-rtdb.firebaseio.com/groups.json");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);
      final List<Map<String, dynamic>> filtered = [];

      data.forEach((key, value) {
        if (value['createdBy'] == userId) {
          filtered.add({"id": key, ...value});
        }
      });

      setState(() {
        userGroups = filtered;
      });
    }
  }

  Future<void> renameGroup(String groupId, String newName) async {
    final url = Uri.parse("https://sportface-f9594-default-rtdb.firebaseio.com/groups/$groupId/groupName.json");
    await http.put(url, body: jsonEncode(newName));
    fetchGroups();
  }

  Future<void> updateGroupRequest(String groupId, String userId, bool accept) async {
    final groupRef = "https://sportface-f9594-default-rtdb.firebaseio.com/groups/$groupId";

    await http.delete(Uri.parse("$groupRef/requests/$userId.json"));

    if (accept) {
      final memberRef = Uri.parse("$groupRef/members.json");
      await http.post(memberRef, body: jsonEncode(userId));
    }

    fetchGroups();
  }

  void showRenameDialog(String groupId, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename Group"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Group Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              renameGroup(groupId, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Groups"),
      ),
      body: userGroups.isEmpty
          ? const Center(child: Text("No groups created yet"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: userGroups.length,
              itemBuilder: (ctx, i) {
                final group = userGroups[i];
                final groupId = group['id'];
                final groupName = group['groupName'] ?? 'Unnamed';
                final List<dynamic> members = List.from(group['members'] ?? []);
                final Map<String, dynamic> requests = Map<String, dynamic>.from(group['requests'] ?? {});

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              groupName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => showRenameDialog(groupId, groupName),
                            ),
                          ],
                        ),
                        const Divider(),

                        // Requests
                        if (requests.isNotEmpty) ...[
                          const Text("Join Requests:", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Column(
                            children: requests.keys.map((userId) {
                              return ListTile(
                                leading: CircularAvatar(userId: userId, imageUrl: ''),
                                title: Text("User ID: $userId"),
                                trailing: Wrap(
                                  spacing: 10,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      onPressed: () => updateGroupRequest(groupId, userId, true),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () => updateGroupRequest(groupId, userId, false),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const Divider(),
                        ],

                        // Members
                        const Text("Group Members:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: members.map((uid) => CircularAvatar(userId: uid, imageUrl: '')).toList(),
                        ),

                        const SizedBox(height: 12),

                        // Chat Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    groupId: groupId,
                                    groupName: groupName,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat),
                            label: const Text("Chat"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
