import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';

class ProfilePicturePicker extends StatefulWidget {
  final String? currentImageUrl;
  final double size;
  final Function(Map<String, dynamic>) onProfileUpdated;
  final bool isLoading;

  const ProfilePicturePicker({
    super.key,
    this.currentImageUrl,
    this.size = 120.0,
    required this.onProfileUpdated,
    this.isLoading = false,
  });

  @override
  State<ProfilePicturePicker> createState() => _ProfilePicturePickerState();
}

class _ProfilePicturePickerState extends State<ProfilePicturePicker> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Profile picture
        GestureDetector(
          onTap: _showImageSourceActionSheet,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildProfileImage(),
          ),
        ),
        
        // Edit button
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: _isUploading || widget.isLoading
              ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: Padding(
                    padding: EdgeInsets.all(6.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  iconSize: 18,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: _showImageSourceActionSheet,
                ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    if (_isUploading || widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          widget.currentImageUrl!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      );
    }

    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: widget.size / 2,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      child: Icon(
        Icons.person,
        size: widget.size * 0.5,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showImageSourceActionSheet() {
    if (_isUploading || widget.isLoading) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              if (widget.currentImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeProfilePicture();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isUploading = true;
      });

      debugPrint('ProfilePicturePicker: Picking image from ${source.toString()}');
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        debugPrint('ProfilePicturePicker: Image picked: ${pickedFile.path}');
        
        // Handle image based on platform
        dynamic imageFile;
        if (kIsWeb) {
          // For web, use bytes
          debugPrint('ProfilePicturePicker: Reading image as bytes for web');
          imageFile = await pickedFile.readAsBytes();
          debugPrint('ProfilePicturePicker: Image size: ${imageFile.length} bytes');
        } else {
          // For mobile, use File
          debugPrint('ProfilePicturePicker: Using File for mobile');
          imageFile = File(pickedFile.path);
        }

        // Upload image and update profile
        debugPrint('ProfilePicturePicker: Uploading image...');
        final updatedProfile = await ProfileService.updateProfilePicture(imageFile);
        
        if (updatedProfile != null) {
          debugPrint('ProfilePicturePicker: Profile updated successfully');
          widget.onProfileUpdated(updatedProfile);
        } else {
          debugPrint('ProfilePicturePicker: Failed to update profile picture');
          _showErrorSnackbar('Failed to update profile picture. Please try again.');
        }
      } else {
        debugPrint('ProfilePicturePicker: No image selected');
      }
    } catch (e) {
      debugPrint('ProfilePicturePicker: Error picking image: $e');
      String errorMessage = 'Error selecting image';
      
      if (e.toString().contains('MissingPluginException')) {
        errorMessage = 'Image picker not available. Try restarting the app.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please grant camera/gallery access.';
      }
      
      _showErrorSnackbar(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _removeProfilePicture() async {
    try {
      setState(() {
        _isUploading = true;
      });

      final updates = {
        'profile_picture_url': null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final updatedProfile = await ProfileService.updateProfile(updates);
      
      if (updatedProfile != null) {
        widget.onProfileUpdated(updatedProfile);
      } else {
        _showErrorSnackbar('Failed to remove profile picture');
      }
    } catch (e) {
      debugPrint('Error removing profile picture: $e');
      _showErrorSnackbar('Error removing profile picture: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
} 