import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static const String _profilePictureBucket = 'profilepictures';
  
  /// Upload a profile picture and return the URL
  static Future<String?> uploadProfilePicture(dynamic imageSource) async {
    debugPrint('StorageService: uploadProfilePicture called');
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('StorageService: Not logged in');
        throw Exception('User not logged in');
      }
      
      String? filePath;
      Uint8List? fileBytes;
      String fileName = '';
      String mimeType = 'image/jpeg'; // Default MIME type
      
      // Handle different image sources (File for mobile, Uint8List for web)
      if (imageSource is File) {
        filePath = imageSource.path;
        fileName = path.basename(filePath);
        
        // Try to determine MIME type from extension
        if (fileName.toLowerCase().endsWith('.png')) {
          mimeType = 'image/png';
        } else if (fileName.toLowerCase().endsWith('.gif')) {
          mimeType = 'image/gif';
        }
      } else if (imageSource is XFile) {
        filePath = imageSource.path;
        fileName = path.basename(filePath);
        if (kIsWeb) {
          fileBytes = await imageSource.readAsBytes();
          
          // For web, try to use the mimeType from XFile
          mimeType = imageSource.mimeType ?? mimeType;
        }
      } else if (imageSource is Uint8List) {
        fileBytes = imageSource;
        fileName = '${const Uuid().v4()}.jpg';
      } else {
        throw Exception('Unsupported image source type: ${imageSource.runtimeType}');
      }
      
      // No need to create bucket - use the existing one
      // Generate a unique file name to avoid conflicts
      final uniqueFileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      debugPrint('StorageService: Uploading file $uniqueFileName to bucket $_profilePictureBucket');
      
      if (kIsWeb && fileBytes != null) {
        // Web upload using bytes
        final options = FileOptions(
          contentType: mimeType,
          upsert: true,
        );
        
        // The API might vary between versions, try both approaches
        try {
          await Supabase.instance.client.storage
              .from(_profilePictureBucket)
              .uploadBinary(uniqueFileName, fileBytes, fileOptions: options);
        } catch (e) {
          debugPrint('StorageService: Error with fileOptions, trying without: $e');
          // Try older API
          await Supabase.instance.client.storage
              .from(_profilePictureBucket)
              .uploadBinary(uniqueFileName, fileBytes);
        }
            
        debugPrint('StorageService: Web upload successful');
      } else if (filePath != null) {
        // Mobile upload using file path
        final options = FileOptions(
          contentType: mimeType,
          upsert: true,
        );
        
        // The API might vary between versions, try both approaches
        try {
          await Supabase.instance.client.storage
              .from(_profilePictureBucket)
              .upload(uniqueFileName, File(filePath), fileOptions: options);
        } catch (e) {
          debugPrint('StorageService: Error with fileOptions, trying without: $e');
          // Try older API
          await Supabase.instance.client.storage
              .from(_profilePictureBucket)
              .upload(uniqueFileName, File(filePath));
        }
            
        debugPrint('StorageService: Mobile upload successful');
      } else {
        throw Exception('No valid file to upload');
      }
      
      // Get public URL
      final String publicUrl = Supabase.instance.client.storage
          .from(_profilePictureBucket)
          .getPublicUrl(uniqueFileName);
          
      debugPrint('StorageService: Uploaded profile picture, URL: $publicUrl');
      
      return publicUrl;
    } catch (e) {
      debugPrint('StorageService: Error uploading profile picture: $e');
      return null;
    }
  }
  
  /// Delete a profile picture by URL
  static Future<bool> deleteProfilePicture(String fileUrl) async {
    debugPrint('StorageService: deleteProfilePicture called');
    
    try {
      // Extract file name from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.isEmpty) {
        debugPrint('StorageService: Invalid file URL');
        return false;
      }
      
      final fileName = pathSegments.last;
      
      // Delete the file
      await Supabase.instance.client.storage
          .from(_profilePictureBucket)
          .remove([fileName]);
          
      debugPrint('StorageService: Deleted profile picture: $fileName');
      return true;
    } catch (e) {
      debugPrint('StorageService: Error deleting profile picture: $e');
      return false;
    }
  }
} 