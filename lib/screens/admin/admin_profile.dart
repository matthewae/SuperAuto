import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../core/theme.dart';

class AuthService extends StateNotifier<bool> {
  AuthService() : super(true);

  void logout() {
    state = false;
    print('Admin logged out');
  }
}

final authServiceProvider = StateNotifierProvider<AuthService, bool>((ref) {
  return AuthService();
});

class AdminProfilePage extends ConsumerWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer(
              builder: (context, ref, child) {
                final currentUser = ref.read(authProvider.notifier).currentUser;
                if (currentUser == null) {
                  return const Text('Tidak ada admin yang login.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat datang, ${currentUser.name}!',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: ${currentUser.email}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      value: ref.watch(themeModeProvider) == ThemeMode.dark,
                      onChanged: (value) {
                        ref.read(themeModeProvider.notifier).toggle();
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(authServiceProvider.notifier).logout();
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Logout Admin'),
            ),
          ],
        ),
      ),
    );
  }
}
