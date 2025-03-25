import 'package:flutter/material.dart';

/// A user avatar widget that displays a user's profile image or a placeholder
class UserAvatar extends StatelessWidget {
  /// The user ID associated with this avatar
  final String userId;
  
  /// The size of the avatar
  final double size;
  
  /// The profile picture URL
  final String? imageUrl;
  
  /// Name of the user for placeholder generation
  final String? name;
  
  /// Function to call when the avatar is tapped
  final VoidCallback? onTap;
  
  const UserAvatar({
    Key? key,
    required this.userId,
    this.size = 40.0,
    this.imageUrl,
    this.name,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use name for placeholder generation if provided, otherwise use userId
    final String displayName = name ?? userId;
    
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
            ? NetworkImage(imageUrl!)
            : NetworkImage(
                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=random&size=128'
              ),
        onBackgroundImageError: (_, __) {
          // Fallback for image loading errors
        },
      ),
    );
  }
} 