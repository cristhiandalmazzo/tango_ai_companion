import 'package:flutter/material.dart';
import '../models/relationship.dart';
import '../models/note.dart';

/// Provider for relationship state and operations
class RelationshipProvider extends ChangeNotifier {
  /// The current active relationship
  Relationship? _relationship;
  
  /// List of notes for the current relationship
  List<Note> _notes = [];
  
  /// Whether data is currently being loaded
  bool _isLoading = false;
  
  /// Get the current relationship
  Relationship? get relationship => _relationship;
  
  /// Get the list of notes
  List<Note> get notes => _notes;
  
  /// Check if data is being loaded
  bool get isLoading => _isLoading;

  /// Load relationship data by ID
  Future<void> loadRelationship(String relationshipId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // In a real implementation, this would load data from a database or API
      await Future.delayed(const Duration(milliseconds: 500));
      
      _relationship = Relationship(
        id: relationshipId,
        user1Id: 'user1',
        user2Id: 'user2',
        type: 'romantic',
        status: 'active',
        partnerStatus: 'joined',
        communicationScore: 70,
        understandingScore: 65,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update the anniversary date
  Future<void> updateAnniversary(String relationshipId, String date) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // In a real implementation, this would update data in a database or API
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (_relationship != null) {
        _relationship = _relationship!.copyWith(anniversaryDate: date);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Add a new note to the relationship
  Future<Note> addNote(String relationshipId, String title, String content) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // In a real implementation, this would add data to a database or API
      await Future.delayed(const Duration(milliseconds: 300));
      
      final newNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        relationshipId: relationshipId,
        title: title,
        content: content,
        createdAt: DateTime.now().toIso8601String(),
      );
      
      _notes.add(newNote);
      
      _isLoading = false;
      notifyListeners();
      
      return newNote;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a note by ID
  Future<void> deleteNote(String noteId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // In a real implementation, this would delete data from a database or API
      await Future.delayed(const Duration(milliseconds: 300));
      
      _notes.removeWhere((note) => note.id == noteId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
} 