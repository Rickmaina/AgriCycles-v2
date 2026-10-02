import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Minimal, free-tier-friendly FCM bootstrap.
///
/// The app should keep to Firebase Cloud Messaging only for push delivery. We
/// use the standard Firebase APIs without custom push infrastructure so the cost
/// stays near zero unless the project starts receiving large traffic.
class PushNotificationsService {
  PushNotificationsService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;

      if (!kIsWeb) {
        final settings = await messaging.requestPermission();
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          // Token registration is handled by the app receiving the current user.
        }
      }

      FirebaseMessaging.onMessage.listen((message) {
        // Keep this lightweight; the app can surface in-app banners later.
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        // The app can deep-link to the relevant screen here once the real
        // payload contract is finalized.
      });
    } catch (_) {
      // Keep startup resilient when Firebase config is not yet supplied.
    }

    _initialized = true;
  }

  static Future<String?> getToken() async {
    try {
      return FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }
}
