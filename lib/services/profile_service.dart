import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class ProfileService {
  static Future<Map<String, dynamic>> fetchProfile() async {
    debugPrint('ProfileService: fetchProfile() called');
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('ProfileService: fetchProfile() failed - Not logged in');
      throw Exception("Not logged in");
    }
    
    debugPrint('ProfileService: Fetching profile for user ${user.id}');
    
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
          
      if (response == null) {
        debugPrint('ProfileService: Profile not found for user ${user.id}');
        throw Exception("Profile not found");
      }
      
      debugPrint('ProfileService: Successfully fetched profile for user ${user.id}');
      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ProfileService: Error fetching profile: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> updates) async {
    debugPrint('ProfileService: updateProfile() called with updates: ${updates.keys.join(", ")}');
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('ProfileService: updateProfile() failed - Not logged in');
      throw Exception("Not logged in");
    }
    
    debugPrint('ProfileService: Updating profile for user ${user.id}');
    
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', user.id)
          .select()
          .maybeSingle();
          
      debugPrint('ProfileService: Successfully updated profile for user ${user.id}');
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('ProfileService: Error updating profile: $e');
      rethrow;
    }
  }
  
  // Fetch partner profile based on the relationship_id
  static Future<Map<String, dynamic>?> fetchPartnerProfile() async {
    debugPrint('ProfileService: fetchPartnerProfile() called');
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('ProfileService: fetchPartnerProfile() failed - Not logged in');
      throw Exception("Not logged in");
    }
    
    try {
      // First, get the current user's profile to get the relationship_id
      final userProfile = await fetchProfile();
      final relationshipId = userProfile['relationship_id'];
      
      if (relationshipId == null || relationshipId == 'self') {
        debugPrint('ProfileService: No relationship found or user is in self mode');
        return null;
      }
      
      debugPrint('ProfileService: Looking up relationship with ID: $relationshipId');
      
      // Get the relationship to find the partner ID
      final relationship = await Supabase.instance.client
          .from('relationships')
          .select()
          .eq('id', relationshipId)
          .maybeSingle();
          
      if (relationship == null) {
        debugPrint('ProfileService: Relationship not found');
        return null;
      }
      
      // Determine which user is the partner (not the current user)
      final String partnerId;
      if (relationship['partner_a'] == user.id) {
        partnerId = relationship['partner_b'];
      } else {
        partnerId = relationship['partner_a'];
      }
      
      if (partnerId == null) {
        debugPrint('ProfileService: No partner found in relationship');
        return null;
      }
      
      debugPrint('ProfileService: Fetching partner profile with ID: $partnerId');
      
      // Fetch the partner's profile
      final partnerProfile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', partnerId)
          .maybeSingle();
          
      if (partnerProfile == null) {
        debugPrint('ProfileService: Partner profile not found');
        return null;
      }
      
      debugPrint('ProfileService: Successfully fetched partner profile');
      return partnerProfile as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ProfileService: Error fetching partner profile: $e');
      return null;
    }
  }

  // Update profile picture and return the updated profile
  static Future<Map<String, dynamic>?> updateProfilePicture(dynamic imageSource) async {
    debugPrint('ProfileService: updateProfilePicture() called');
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('ProfileService: updateProfilePicture() failed - Not logged in');
      throw Exception("Not logged in");
    }
    
    try {
      // 1. Get current profile to check if there's an existing picture
      final currentProfile = await fetchProfile();
      final currentPictureUrl = currentProfile['profile_picture_url'];
      
      // 2. Upload new picture
      final newPictureUrl = await StorageService.uploadProfilePicture(imageSource);
      
      if (newPictureUrl == null) {
        debugPrint('ProfileService: Failed to upload profile picture');
        return null;
      }
      
      // 3. Delete old picture if it exists
      if (currentPictureUrl != null && currentPictureUrl.isNotEmpty) {
        await StorageService.deleteProfilePicture(currentPictureUrl);
      }
      
      // 4. Update profile with new picture URL
      final updates = {
        'profile_picture_url': newPictureUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      return await updateProfile(updates);
    } catch (e) {
      debugPrint('ProfileService: Error updating profile picture: $e');
      return null;
    }
  }
}
