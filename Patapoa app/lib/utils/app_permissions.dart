import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class AppPermissions {
  static Future<bool> requestLocationPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        await _showSettingsDialog(
          context,
          title: 'Location Permission Required',
          message:
              'Location access is required for rider tracking and delivery navigation. Please enable it in Settings.',
        );
      }
      return false;
    }

    if (permission == LocationPermission.denied) {
      return false;
    }

    return true;
  }

  static Future<bool> requestBackgroundLocationPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse) {
      if (context.mounted) {
        final shouldRequest = await _showConfirmDialog(
          context,
          title: 'Background Location Required',
          message:
              'To track deliveries while the app is in the background, please allow "All the time" location access.',
        );
        if (shouldRequest) {
          permission = await Geolocator.requestPermission();
        }
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        await _showSettingsDialog(
          context,
          title: 'Location Permission Required',
          message: 'Background location is required for active deliveries. Please enable it in Settings.',
        );
      }
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(
          context,
          title: 'Camera Permission Required',
          message: 'Camera access is needed to take product photos. Please enable it in Settings.',
        );
      }
      return false;
    }

    return status.isGranted;
  }

  static Future<bool> requestPhotosPermission(BuildContext context) async {
    final status = await Permission.photos.request();

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(
          context,
          title: 'Photos Permission Required',
          message: 'Photo library access is needed to upload product images. Please enable it in Settings.',
        );
      }
      return false;
    }

    return status.isGranted || status.isLimited;
  }

  static Future<bool> requestStoragePermission(BuildContext context) async {
    final status = await Permission.storage.request();

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(
          context,
          title: 'Storage Permission Required',
          message: 'Storage access is needed to save and upload images. Please enable it in Settings.',
        );
      }
      return false;
    }

    return status.isGranted;
  }

  static Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.request();

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(
          context,
          title: 'Notification Permission Required',
          message: 'Push notifications are needed for order updates and delivery alerts. Please enable them in Settings.',
        );
      }
      return false;
    }

    return status.isGranted;
  }

  static Future<bool> requestPhonePermission(BuildContext context) async {
    final status = await Permission.phone.request();

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(
          context,
          title: 'Phone Permission Required',
          message: 'Phone access is needed to call riders and merchants. Please enable it in Settings.',
        );
      }
      return false;
    }

    return status.isGranted;
  }

  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    final status = await Permission.microphone.request();

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(
          context,
          title: 'Microphone Permission Required',
          message: 'Microphone access is needed for voice chat with riders. Please enable it in Settings.',
        );
      }
      return false;
    }

    return status.isGranted;
  }

  static Future<bool> requestAllRiderPermissions(BuildContext context) async {
    final results = await Future.wait([
      requestLocationPermission(context),
      requestNotificationPermission(context),
      requestPhonePermission(context),
    ]);

    return results.every((r) => r);
  }

  static Future<bool> requestAllMerchantPermissions(BuildContext context) async {
    final results = await Future.wait([
      requestCameraPermission(context),
      requestPhotosPermission(context),
      requestNotificationPermission(context),
      requestPhonePermission(context),
    ]);

    return results.every((r) => r);
  }

  static Future<bool> requestAllCustomerPermissions(BuildContext context) async {
    final results = await Future.wait([
      requestLocationPermission(context),
      requestNotificationPermission(context),
      requestPhonePermission(context),
    ]);

    return results.every((r) => r);
  }

  static Future<void> _showSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
