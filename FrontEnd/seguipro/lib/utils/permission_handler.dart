import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  static Future<bool> requestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> requestMediaPermission() async {
    // Para Android 13+ (API 33+)
    if (await Permission.photos.isGranted) {
      return true;
    }

    final status = await Permission.photos.request();
    return status.isGranted;
  }

  static Future<bool> requestAllFilePermissions() async {
    // Solicitar permisos de almacenamiento
    final storageGranted = await requestStoragePermission();

    // Solicitar permisos de medios
    final mediaGranted = await requestMediaPermission();

    return storageGranted || mediaGranted;
  }

  static Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permisos Requeridos'),
          content: const Text(
            'Esta aplicación necesita acceso al almacenamiento para adjuntar archivos. '
            'Por favor, otorga los permisos necesarios en la configuración de la aplicación.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Configuración'),
            ),
          ],
        );
      },
    );
  }
}
