import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

/// Centralized Image Picker & Uploader for Everyfy
/// Directly connects with Camera ("Take Photo") and Phone Gallery ("Choose from Gallery")
class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Direct dialog to pick image and return File? directly
  static Future<File?> showImageSourceDialog(
    BuildContext context, {
    String title = 'Choose Photo Source',
  }) async {
    ImageSource? selectedSource;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildSourceTile(
                  icon: Icons.camera_alt_rounded,
                  color: const Color(0xFF0D5C3A),
                  title: 'Take Photo',
                  subtitle: 'Use your phone camera to capture photo',
                  onTap: () {
                    selectedSource = ImageSource.camera;
                    Navigator.pop(sheetContext);
                  },
                ),
                const SizedBox(height: 12),
                _buildSourceTile(
                  icon: Icons.photo_library_rounded,
                  color: const Color(0xFF2563EB),
                  title: 'Select from Gallery',
                  subtitle: 'Choose an existing photo from your device',
                  onTap: () {
                    selectedSource = ImageSource.gallery;
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedSource == null) return null;
    try {
      final pickedFile = await _picker.pickImage(
        source: selectedSource!,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (_) {
      return null;
    }
  }

  /// Show modal bottom sheet to pick image from Camera or Gallery
  static Future<void> showImageSourceSheet({
    required BuildContext context,
    required Function(File imageFile, String? uploadedUrl) onImageSelected,
    String folder = 'general',
    bool autoUpload = true,
  }) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Choose Photo Source',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Option 1: Camera
                _buildSourceTile(
                  icon: Icons.camera_alt_rounded,
                  color: const Color(0xFF0D5C3A),
                  title: 'Take Photo',
                  subtitle: 'Use your phone camera to capture photo',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _pickAndHandle(
                      context: context,
                      source: ImageSource.camera,
                      folder: folder,
                      autoUpload: autoUpload,
                      onImageSelected: onImageSelected,
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Option 2: Gallery
                _buildSourceTile(
                  icon: Icons.photo_library_rounded,
                  color: const Color(0xFF2563EB),
                  title: 'Select from Gallery',
                  subtitle: 'Choose an existing photo from your device',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _pickAndHandle(
                      context: context,
                      source: ImageSource.gallery,
                      folder: folder,
                      autoUpload: autoUpload,
                      onImageSelected: onImageSelected,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildSourceTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  static Future<void> _pickAndHandle({
    required BuildContext context,
    required ImageSource source,
    required String folder,
    required bool autoUpload,
    required Function(File imageFile, String? uploadedUrl) onImageSelected,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final File file = File(pickedFile.path);

      if (!autoUpload) {
        onImageSelected(file, file.path);
        return;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Uploading selected photo...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      final res = await ApiService.uploadImage(file, folder: folder);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (res['success'] == true && res['data'] != null) {
        final url =
            res['data']['url']?.toString() ?? res['data']['path']?.toString();
        onImageSelected(file, url);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully!'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Fall back to local file path so user doesn't get blocked
        onImageSelected(file, file.path);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Selected photo set locally (${res['message'] ?? 'server saved local'})'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
