import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  static Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    }
    final result = await permission.request();
    return result.isGranted;
  }

  static Future<File?> pickImage({
    required ImageSource source,
    required BuildContext context,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      // Solicitar permisos
      if (source == ImageSource.camera) {
        final cameraPermission = await _requestPermission(Permission.camera);
        if (!cameraPermission) {
          throw Exception('Se requiere permiso de cámara');
        }
      } else {
        final storagePermission = await _requestPermission(Permission.storage);
        if (!storagePermission) {
          throw Exception('Se requiere permiso de almacenamiento');
        }
      }

      // Seleccionar imagen
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth ?? 1080,
        maxHeight: maxHeight ?? 1080,
        imageQuality: imageQuality ?? 85,
      );

      if (image == null) return null;

      // Recortar imagen
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar imagen',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Recortar imagen',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
          ),
        ],
      );

      if (croppedFile == null) return null;

      return File(croppedFile.path);
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
      rethrow;
    }
  }
}
