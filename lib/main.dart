import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'data/db/app_database.dart';
import 'providers/app_providers.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> testSupabaseConnection() async {
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('cars').select().limit(1);
    print('✅ Berhasil terhubung ke Supabase!');
    print('Data contoh: $response');
  } catch (e) {
    print('❌ Gagal terhubung ke Supabase:');
    print(e.toString());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final database = AppDatabase.instance;
  final db = await database.database;

  await NotificationService().init();
  await initializeDateFormatting('id_ID', null);
  await Supabase.initialize(
    url: 'https://julsnwsljkiaantaonbx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1bHNud3NsamtpYWFudGFvbmJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ5ODk3NDYsImV4cCI6MjA4MDU2NTc0Nn0.qObeATDAfOd3vDyA3r4mwEggkhl3behvWc8XOzgjd3k',
  );
  
  await testSupabaseConnection();
  
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const SuperAutoApp(),
    ),
  );
}