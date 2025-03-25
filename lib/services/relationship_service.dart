import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_service.dart';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';

class RelationshipService {
  // Fetch relationship data including both partners
  static Future<Map<String, dynamic>> fetchRelationshipData() async {
    debugPrint('RelationshipService: fetchRelationshipData() called');
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('RelationshipService: fetchRelationshipData() failed - Not logged in');
      throw Exception("Not logged in");
    }
    
    try {
      // Fetch current user profile
      final userProfile = await ProfileService.fetchProfile();
      final relationshipId = userProfile['relationship_id'];
      
      if (relationshipId == null || relationshipId == 'self') {
        debugPrint('RelationshipService: No relationship found or user is in self mode');
        throw Exception("No relationship found");
      }
      
      debugPrint('RelationshipService: Looking up relationship with ID: $relationshipId');
      
      // Get the relationship data
      final relationship = await Supabase.instance.client
          .from('relationships')
          .select()
          .eq('id', relationshipId)
          .maybeSingle();
          
      if (relationship == null) {
        debugPrint('RelationshipService: Relationship not found');
        throw Exception("Relationship not found");
      }
      
      // Get both partner IDs
      final String partnerAId = relationship['partner_a'];
      final dynamic partnerBId = relationship['partner_b']; // Use dynamic to handle null
      bool isPartnerBSignedUp = false;
      
      // Determine which is the current user and which is the partner
      final String currentUserId = user.id;
      String? partnerId; // Make this nullable
      
      if (partnerAId == currentUserId) {
        partnerId = partnerBId as String?; // Cast to nullable String
      } else {
        partnerId = partnerAId;
      }
      
      // Fetch partner A profile (this should always exist)
      final partnerAProfile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', partnerAId)
          .maybeSingle();
          
      if (partnerAProfile == null) {
        debugPrint('RelationshipService: Partner A profile not found');
        throw Exception("Partner A profile not found");
      }
      
      // Create default partner B profile in case they haven't signed up
      Map<String, dynamic> partnerBProfile = {
        'id': null,
        'name': 'Waiting for Partner',
        'bio': 'Your partner has not signed up yet.',
        'interests': [],
        'personality_traits': []
      };
      
      // Only fetch partner B profile if they have signed up
      if (partnerBId != null && partnerBId.toString().isNotEmpty) {
        debugPrint('RelationshipService: Partner B has signed up, fetching profile');
        isPartnerBSignedUp = true;
        
        final fetchedPartnerBProfile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', partnerBId)
            .maybeSingle();
            
        if (fetchedPartnerBProfile != null) {
          partnerBProfile = fetchedPartnerBProfile;
        } else {
          debugPrint('RelationshipService: Partner B profile not found even though ID exists');
        }
      } else {
        debugPrint('RelationshipService: Partner B has not signed up yet');
      }
      
      // Generate default metrics
      final defaultMetrics = _generateDefaultMetrics(partnerAProfile, partnerBProfile);
      
      // Compile all data
      return {
        'relationship': relationship,
        'current_user_id': currentUserId,
        'partner_a': partnerAProfile,
        'partner_b': partnerBProfile,
        'metrics': defaultMetrics,
        'is_partner_b_signed_up': isPartnerBSignedUp
      };
    } catch (e) {
      debugPrint('RelationshipService: Error fetching relationship data: $e');
      rethrow;
    }
  }
  
  // Generate default metrics based on partner profiles
  static Map<String, dynamic> _generateDefaultMetrics(
    Map<String, dynamic> partnerA, 
    Map<String, dynamic> partnerB
  ) {
    // Get shared interests to calculate compatibility
    final List<dynamic> partnerAInterests = partnerA['interests'] ?? [];
    final List<dynamic> partnerBInterests = partnerB['interests'] ?? [];
    
    final partnerAInterestStrings = partnerAInterests.map((i) => i.toString().toLowerCase()).toList();
    final partnerBInterestStrings = partnerBInterests.map((i) => i.toString().toLowerCase()).toList();
    
    final commonInterests = partnerAInterestStrings
      .where((interest) => partnerBInterestStrings.contains(interest))
      .toList();
    
    // Calculate strength based on common interests and other factors
    int strengthScore = 65; // Base score
    
    // Adjust score based on common interests
    if (partnerAInterests.isNotEmpty && partnerBInterests.isNotEmpty) {
      final maxPossibleCommon = math.min(partnerAInterests.length, partnerBInterests.length);
      if (maxPossibleCommon > 0) {
        // Add up to 15 points for shared interests
        strengthScore += (commonInterests.length / maxPossibleCommon * 15).round();
      }
    }
    
    // Generate other metrics
    final communicationScore = 60 + (strengthScore - 65);  // Base communication related to strength
    final understandingScore = 55 + (strengthScore - 65);  // Base understanding related to strength
    
    // Create insight message based on scores
    String insight = 'Your relationship shows potential. Continue using Tango to strengthen your connection.';
    
    if (commonInterests.isNotEmpty) {
      insight = 'You share ${commonInterests.length} interests with your partner. Build on these common areas to strengthen your connection.';
    }
    
    if (strengthScore >= 75) {
      insight = 'Your relationship is strong. Keep nurturing your connection through regular communication.';
    } else if (strengthScore <= 55) {
      insight = 'Your relationship has room to grow. Try using the AI chat to improve communication.';
    }
    
    return {
      'strength': strengthScore,
      'communication': communicationScore,
      'understanding': understandingScore,
      'insight': insight,
      'common_interests_count': commonInterests.length,
    };
  }
  
  // Update relationship metrics - currently a placeholder since the table doesn't exist
  static Future<Map<String, dynamic>?> updateRelationshipMetrics(
    String relationshipId, 
    Map<String, dynamic> metrics
  ) async {
    debugPrint('RelationshipService: updateRelationshipMetrics called (placeholder)');
    
    // Simply return the metrics that were passed in, since we can't store them
    return metrics;
  }
  
  // Update relationship data
  static Future<bool> updateRelationship(Map<String, dynamic> updates) async {
    debugPrint('RelationshipService: updateRelationship called with: $updates');
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('RelationshipService: updateRelationship failed - Not logged in');
      throw Exception("Not logged in");
    }
    
    try {
      // Get the current user's relationship ID
      final userProfile = await ProfileService.fetchProfile();
      final relationshipId = userProfile['relationship_id'];
      
      if (relationshipId == null || relationshipId == 'self') {
        debugPrint('RelationshipService: No relationship found or user is in self mode');
        throw Exception("No relationship found");
      }
      
      // Update the relationship in the database
      await Supabase.instance.client
          .from('relationships')
          .update(updates)
          .eq('id', relationshipId);
          
      debugPrint('RelationshipService: Relationship updated successfully');
      return true;
    } catch (e) {
      debugPrint('RelationshipService: Error updating relationship: $e');
      return false;
    }
  }

  /// Creates a new relationship for a user
  static Future<String> createNewRelationship(String userId) async {
    int maxRetries = 3;
    int currentRetry = 0;
    
    while (currentRetry < maxRetries) {
      final newRelationshipId = const Uuid().v4();
      
      try {
        // Check if relationship already exists
        final existingRelationship = await Supabase.instance.client
            .from('relationships')
            .select()
            .eq('id', newRelationshipId)
            .maybeSingle();
            
        if (existingRelationship != null) {
          debugPrint('RelationshipService: Relationship ID $newRelationshipId already exists, retrying...');
          currentRetry++;
          continue;
        }
        
        // Create new relationship
        await Supabase.instance.client
            .from('relationships')
            .insert({
              'id': newRelationshipId,
              'partner_a': userId,
              'partner_b': null,
              'start_date': DateTime.now().toIso8601String(),
              'status': 'active',
              'active': true,
              'additional_data': {
                'notes': [],
                'strength': 0,
                'insights': [],
              }
            });
        
        debugPrint('RelationshipService: Created new relationship with ID: $newRelationshipId');
        return newRelationshipId;
      } catch (e) {
        debugPrint('RelationshipService: Error creating relationship: $e');
        currentRetry++;
        
        if (currentRetry >= maxRetries) {
          throw Exception('Failed to create relationship after $maxRetries attempts');
        }
      }
    }
    
    throw Exception('Failed to create relationship after $maxRetries attempts');
  }
} 