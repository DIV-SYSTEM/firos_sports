import 'package:flutter/material.dart';
import '../model/companion_model.dart';
import '../data/companion_data.dart';

class CompanionCard extends StatelessWidget {
  final CompanionModel data;
  final VoidCallback onReadMorePressed;
  final String currentUser;

  const CompanionCard({
    Key? key,
    required this.data,
    required this.onReadMorePressed,
    required this.currentUser,
  }) : super(key: key);

  void _requestToJoin(BuildContext context) {
    print("RequestToJoin: currentUser=$currentUser, organiserName=${data.organiserName}");
    GroupModel? group;
    for (var g in groupData) {
      if (g.eventId == data.id) {
        group = g;
        break;
      }
    }
    if (group == null) {
      group = GroupModel(
        groupId: "group${groupData.length + 1}",
        eventId: data.id,
        groupName: "${data.sportName} Group by ${data.organiserName}",
        organiserName: data.organiserName,
        members: [data.organiserName],
      );
      groupData.add(group);
      print("Created new group: ${group.groupId} for event: ${group.eventId}");
      logGroupData("After group creation in request");
    }
    if (currentUser.toLowerCase() == data.organiserName.toLowerCase()) {
      if (!group.members.contains(currentUser)) {
        group.members.add(currentUser);
        print("Auto-added organiser $currentUser to group: ${group.groupId}");
        logGroupData("After auto-adding organiser");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You are the organiser of this group!")),
      );
      return;
    }
    pendingRequests.add(PendingRequest(
      userName: currentUser,
      groupId: group.groupId,
    ));
    print("Added request for user: $currentUser to group: ${group.groupId}");
    logGroupData("After adding request");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request sent to organiser!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateColor = Colors.teal[700];
    final tagColor = Colors.deepOrange[800];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                data.logoPath,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image, size: 60),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.sportName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.indigo[900],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "by ${data.organiserName}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${data.venue}, ${data.city}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${data.date} at ${data.time}",
                    style: TextStyle(
                      fontSize: 13,
                      color: dateColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.description,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildInfoTag("Gender: ${data.gender}", tagColor),
                      _buildInfoTag("Type: ${data.paidStatus}", tagColor),
                      _buildInfoTag("Age Limit: ${data.ageLimit}", tagColor),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: onReadMorePressed,
                        child: const Text(
                          "Read More",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _requestToJoin(context),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                        child: const Text("Request"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(String text, Color? color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1) ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color ?? Colors.black87),
      ),
    );
  }
}
