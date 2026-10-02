import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/notifications/push_notifications_service.dart';
import 'domain/location_catalog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload the Kenya administrative hierarchy (county → sub-county → ward).
  // Screens and the LocationPicker read from LocationCatalog.instance;
  // this ensures it's ready before the first frame.
  await LocationCatalog.load();

  await PushNotificationsService.initialize();

  runApp(
    const ProviderScope(
      child: AgriCyclesApp(),
    ),
  );
}
