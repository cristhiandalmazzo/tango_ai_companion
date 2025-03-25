import 'package:flutter/material.dart';
import 'user_avatar.dart';

class ConnectedAvatars extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final Map<String, dynamic> partnerProfile;
  final Color? lineStartColor;
  final Color? lineEndColor;
  final Widget? centerWidget;
  final double avatarSize;
  final double lineWidth;
  final double lineHeight;
  
  const ConnectedAvatars({
    super.key,
    required this.userProfile,
    required this.partnerProfile,
    this.lineStartColor,
    this.lineEndColor,
    this.centerWidget,
    this.avatarSize = 80.0,
    this.lineWidth = 0.4,
    this.lineHeight = 4.0,
  });
  
  // Helper function to generate color from user interests
  Color _getColorFromInterests(List<dynamic>? interests) {
    if (interests == null || interests.isEmpty) {
      return Colors.blue;
    }
    
    // Simple hash function to generate a color
    int hash = 0;
    for (final interest in interests) {
      hash = interest.hashCode + ((hash << 5) - hash);
    }
    
    // Convert to RGB
    return Color(0xFF000000 + (hash & 0x00FFFFFF));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Get colors for the connection line
    final startColor = lineStartColor ?? 
        _getColorFromInterests(userProfile['interests'] as List<dynamic>?);
    final endColor = lineEndColor ?? 
        _getColorFromInterests(partnerProfile['interests'] as List<dynamic>?);
    
    // Extract user and partner names and profile pictures
    final String userName = userProfile['name'] ?? 
                           userProfile['full_name'] ?? 
                           userProfile['username'] ?? '';
    final String partnerName = partnerProfile['name'] ?? 
                              partnerProfile['full_name'] ?? 
                              partnerProfile['username'] ?? '';
    final String userImageUrl = userProfile['profile_picture_url'] ?? '';
    final String partnerImageUrl = partnerProfile['profile_picture_url'] ?? '';
    
    // Calculate responsive sizes based on screen width
    final double responsiveAvatarSize = size.width < 400 ? avatarSize * 0.8 : avatarSize;
    final double connectionLineWidth = size.width * 0.2;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current user avatar
              UserAvatar(
                userId: userProfile['id'] ?? '',
                imageUrl: userImageUrl,
                name: userName,
                size: responsiveAvatarSize,
              ),
              
              // Connection between avatars
              SizedBox(
                width: constraints.maxWidth * 0.5,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Connection line
                    Container(
                      height: lineHeight,
                      width: connectionLineWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [startColor, endColor],
                        ),
                        borderRadius: BorderRadius.circular(lineHeight / 2),
                      ),
                    ),
                    
                    // Center widget (optional)
                    if (centerWidget != null) 
                      Center(child: centerWidget),
                  ],
                ),
              ),
              
              // Partner avatar
              UserAvatar(
                userId: partnerProfile['id'] ?? '',
                imageUrl: partnerImageUrl,
                name: partnerName,
                size: responsiveAvatarSize,
              ),
            ],
          );
        }
      ),
    );
  }
} 