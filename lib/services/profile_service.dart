import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

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
}
