import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawtastic/config/supabase_config.dart';
import 'package:pawtastic/services/image_service.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static Future<String?> uploadImage({
    required File imageFile,
    required String bucket,
    required String folder,
  }) async {
    try {
      // Validar que el archivo existe
      if (!await imageFile.exists()) {
        throw Exception('El archivo no existe');
      }

      // Validar el tamaño del archivo (max 10MB)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('La imagen es demasiado grande (máximo 10MB)');
      }

      // Generar nombre único para el archivo
      final fileExt = path.extension(imageFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = '$folder/$fileName';

      debugPrint('Subiendo imagen a Supabase: $filePath');

      // Subir el archivo
      final bytes = await imageFile.readAsBytes();
      final response = await SupabaseConfig.client.storage
          .from(bucket)
          .uploadBinary(filePath, bytes);

      if (response.isEmpty) {
        throw Exception('Error al subir la imagen');
      }

      // Obtener la URL pública
      final imageUrl =
          SupabaseConfig.client.storage.from(bucket).getPublicUrl(filePath);

      debugPrint('Imagen subida exitosamente: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      rethrow;
    }
  }

  static Future<String?> pickAndUploadImage({
    required BuildContext context,
    required String bucket,
    required String folder,
    required ImageSource source,
  }) async {
    try {
      // Seleccionar y procesar imagen
      final File? pickedImage = await ImageService.pickImage(
        source: source,
        context: context,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedImage == null) {
        debugPrint('No se seleccionó ninguna imagen');
        return null;
      }

      // Subir imagen a Supabase
      final imageUrl = await uploadImage(
        imageFile: pickedImage,
        bucket: bucket,
        folder: folder,
      );

      return imageUrl;
    } catch (e) {
      debugPrint('Error en pickAndUploadImage: $e');
      rethrow;
    }
  }

  static Future<bool> deleteImage({
    required String bucket,
    required String path,
  }) async {
    try {
      await SupabaseConfig.client.storage.from(bucket).remove([path]);
      return true;
    } catch (e) {
      debugPrint('Error al eliminar imagen: $e');
      return false;
    }
  }
}
