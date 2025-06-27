import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';

class CircularAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? userId;

  const CircularAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20.0,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final effectiveUserId = userId ?? user?.id;

    return FutureBuilder<String?>(
      future: _getImage(effectiveUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[300],
            child: const CircularProgressIndicator(),
          );
        }
        final imageUrl = snapshot.data;
        if (imageUrl == null || imageUrl.isEmpty) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, size: radius, color: Colors.grey[600]),
          );
        }
        try {
          if (imageUrl.startsWith('data:image')) {
            // Handle base64 image
            final base64String = imageUrl.split(',').last;
            final imageBytes = base64Decode(base64String);
            return CircleAvatar(
              radius: radius,
              backgroundImage: MemoryImage(imageBytes),
              backgroundColor: Colors.grey[300],
            );
          } else {
            // Fallback for network images (if any legacy data exists)
            return CircleAvatar(
              radius: radius,
              backgroundImage: NetworkImage(imageUrl),
              backgroundColor: Colors.grey[300],
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error loading image: $e');
          }
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.error, size: radius, color: Colors.red),
          );
        }
      },
    );
  }

  Future<String?> _getImage(String? userId) async {
    if (imageUrl != null) return imageUrl;
    if (userId == null) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_${userId}_image');
  }
}
