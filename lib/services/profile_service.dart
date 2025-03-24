import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  static Future<Map<String, dynamic>> fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("Not logged in");
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (response == null) throw Exception("Profile not found");
    return response as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> updates) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("Not logged in");
    final response = await Supabase.instance.client
        .from('profiles')
        .update(updates)
        .eq('id', user.id)
        .select()
        .maybeSingle();
    return response as Map<String, dynamic>?;
  }
}
