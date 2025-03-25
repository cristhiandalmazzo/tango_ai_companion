/// Model class for a note in a relationship
class Note {
  /// Unique identifier for the note
  final String id;
  
  /// ID of the relationship this note belongs to
  final String relationshipId;
  
  /// Title of the note
  final String? title;
  
  /// Content of the note
  final String content;
  
  /// Creation date of the note
  final String createdAt;
  
  /// Last update date of the note
  final String? updatedAt;

  const Note({
    required this.id,
    required this.relationshipId,
    this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create a Note from JSON data
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      relationshipId: json['relationship_id'],
      title: json['title'],
      content: json['content'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  /// Convert this Note to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relationship_id': relationshipId,
      'title': title,
      'content': content,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
} 