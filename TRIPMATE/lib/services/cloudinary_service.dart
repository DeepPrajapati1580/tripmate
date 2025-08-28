// lib/services/cloudinary_service.dart
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryUploader {
  static final cloudinary = CloudinaryPublic(
    'dbdhnrhur',
    'tripmate_preset',    // e.g. "trip_upload"
    cache: false,
  );

  /// Uploads a local image file to Cloudinary
  static Future<Map<String, String>> uploadImage(String filePath) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          resourceType: CloudinaryResourceType.Image,
          folder: "tripmate", // optional
        ),
      );

      return {
        "publicId": response.publicId,
        "secure_url": response.secureUrl, // ⚡ correct key is secure_url
      };
    } catch (e) {
      print("Cloudinary error: $e"); // 👈 will show actual message from Cloudinary
      throw Exception("Cloudinary upload failed: $e");
    }
  }
}
