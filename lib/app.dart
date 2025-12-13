import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'providers/app_providers.dart'; // Pastikan ini diimpor

class SuperAutoApp extends ConsumerWidget {
  const SuperAutoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger the data seeder on app startup.
    // We use `read` because we only want to run it once and don't need to rebuild when its state changes.
    // The `FutureProvider` handles the execution logic (including the SharedPreferences check).

    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SuperAuto',
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}