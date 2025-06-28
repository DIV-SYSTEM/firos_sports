import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/circular_avatar.dart';
import '../providers/user_provider.dart';

class ProfileScreenLite extends StatelessWidget {
  const ProfileScreenLite({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return AlertDialog(
      contentPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularAvatar(imageUrl: user?.imageUrl, radius: 50, userId: user?.id),
          const SizedBox(height: 16),
          Text('Name: ${user?.name ?? "N/A"}'),
          const SizedBox(height: 8),
          Text('Email: ${user?.email ?? "N/A"}'),
          const SizedBox(height: 8),
          Text('Age: ${user?.age?.toString() ?? "N/A"}'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('Verified '),
              Text(
                '✅️',
                style: TextStyle(
                  color: Color(0xFF1DA1F2), // Twitter/X blue
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
