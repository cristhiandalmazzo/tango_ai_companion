import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_service.dart';
import 'dart:math' as math;

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
      final String partnerBId = relationship['partner_b'];
      
      // Determine which is the current user and which is the partner
      final String currentUserId = user.id;
      String partnerId;
      
      if (partnerAId == currentUserId) {
        partnerId = partnerBId;
      } else {
        partnerId = partnerAId;
      }
      
      // Fetch both partner profiles
      final partnerAProfile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', partnerAId)
          .maybeSingle();
          
      final partnerBProfile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', partnerBId)
          .maybeSingle();
          
      if (partnerAProfile == null || partnerBProfile == null) {
        debugPrint('RelationshipService: One or more partner profiles not found');
        throw Exception("Partner profiles not found");
      }
      
      // Generate default metrics - don't query relationship_metrics table since it doesn't exist
      final defaultMetrics = _generateDefaultMetrics(partnerAProfile, partnerBProfile);
      
      // Compile all data
      return {
        'relationship': relationship,
        'current_user_id': currentUserId,
        'partner_a': partnerAProfile,
        'partner_b': partnerBProfile,
        'metrics': defaultMetrics,
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
} 