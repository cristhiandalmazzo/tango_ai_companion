import 'package:flutter/material.dart';

/// A user avatar widget that displays a user's profile image or a placeholder
class UserAvatar extends StatelessWidget {
  /// The user ID associated with this avatar
  final String userId;
  
  /// The size of the avatar
  final double size;
  
  /// Function to call when the avatar is tapped
  final VoidCallback? onTap;
  
  const UserAvatar({
    Key? key,
    required this.userId,
    this.size = 40.0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userId)}&background=random&size=128'
        ),
        onBackgroundImageError: (_, __) {
          // Fallback for image loading errors
        },
      ),
    );
  }
} 