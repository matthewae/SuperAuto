// main.dart (updated)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'data/db/app_database.dart';
import 'providers/app_providers.dart';
import 'package:intl/date_symbol_data_local.dart';

// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final database = AppDatabase.instance;
  final db = await database.database;

  // Initialize notifications
  await NotificationService().init();
  await initializeDateFormatting('id_ID', null);
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const SuperAutoApp(),
    ),
  );
}