// lib/services/cloudinary_service.dart
import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryUploader {
  static final cloudinary = CloudinaryPublic(
    dotenv.env['CLOUDINARY_CLOUD_NAME']!,
    dotenv.env['CLOUDINARY_UPLOAD_PRESET']!,
    cache: false,
  );

  /// Upload image to Cloudinary (works for both web & mobile)
  static Future<Map<String, String>> uploadImage({
    String? filePath,       // for mobile/desktop
    Uint8List? fileBytes,   // for web
    String? fileName,       // only for web
  }) async {
    try {
      CloudinaryResponse response;

      if (kIsWeb) {
        if (fileBytes == null || fileName == null) {
          throw Exception("On Web, you must pass fileBytes + fileName");
        }
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(fileBytes, identifier: fileName),
        );
      } else {
        if (filePath == null) {
          throw Exception("On Mobile/Desktop, you must pass filePath");
        }
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            filePath,
            resourceType: CloudinaryResourceType.Image,
            folder: "tripmate",
          ),
        );
      }

      return {
        "publicId": response.publicId,
        "secure_url": response.secureUrl,
      };
    } catch (e) {
      print("Cloudinary error: $e");
      throw Exception("Cloudinary upload failed: $e");
    }
  }
}
