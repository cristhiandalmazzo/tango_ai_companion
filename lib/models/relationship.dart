/// Model class for a relationship between two users
class Relationship {
  /// Unique identifier for the relationship
  final String id;
  
  /// ID of the first user in the relationship
  final String user1Id;
  
  /// ID of the second user in the relationship
  final String user2Id;
  
  /// Type of relationship (e.g. 'romantic', 'friendship', 'family')
  final String type;
  
  /// Status of the relationship (e.g. 'active', 'pending', 'ended')
  final String status;
  
  /// Date the relationship started
  final String? anniversaryDate;
  
  /// Unique code for inviting a partner to join the relationship
  final String? inviteCode;
  
  /// Partner's status in the relationship (e.g. 'joined', 'pending')
  final String? partnerStatus;
  
  /// Score for communication quality (0-100)
  final int? communicationScore;
  
  /// Score for understanding quality (0-100)
  final int? understandingScore;
  
  /// Insights about the relationship
  final String? insights;
  
  /// Additional data stored as JSON
  final Map<String, dynamic>? additionalData;
  
  const Relationship({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.type,
    required this.status,
    this.anniversaryDate,
    this.inviteCode,
    this.partnerStatus,
    this.communicationScore,
    this.understandingScore,
    this.insights,
    this.additionalData,
  });

  /// Create a copy of this Relationship with some updated properties
  Relationship copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    String? type,
    String? status,
    String? anniversaryDate,
    String? inviteCode,
    String? partnerStatus,
    int? communicationScore,
    int? understandingScore,
    String? insights,
    Map<String, dynamic>? additionalData,
  }) {
    return Relationship(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      type: type ?? this.type,
      status: status ?? this.status,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      inviteCode: inviteCode ?? this.inviteCode,
      partnerStatus: partnerStatus ?? this.partnerStatus,
      communicationScore: communicationScore ?? this.communicationScore,
      understandingScore: understandingScore ?? this.understandingScore,
      insights: insights ?? this.insights,
      additionalData: additionalData ?? this.additionalData,
    );
  }
} 