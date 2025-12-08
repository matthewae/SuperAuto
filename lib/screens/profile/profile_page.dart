import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/app_providers.dart';
import '../../models/user.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.read(authProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;

    // Listen to auth state changes
    ref.listen<AsyncValue<User?>>(
      authProvider,
          (_, next) {
        next.when(
          data: (user) {
            if (user == null && _isLoggingOut) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.go('/login', extra: {'fromLogout': true});
                }
              });
            }
          },
          error: (error, _) {
            if (mounted) {
              setState(() => _isLoggingOut = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Logout gagal: $error')),
              );
            }
          },
          loading: () {},
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Akun'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Pengguna',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'user@example.com',
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Settings List
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      // Theme Toggle
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            themeMode == ThemeMode.dark
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: const Text('Tema Gelap'),
                        trailing: Switch(
                          value: themeMode == ThemeMode.dark,
                          onChanged: (_) =>
                              ref.read(themeModeProvider.notifier).toggle(),
                        ),
                      ),
                      const Divider(height: 1),

                      // Logout Button
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.logout,
                            color: Colors.red,
                          ),
                        ),
                        title: const Text(
                          'Keluar',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: _isLoggingOut
                            ? null
                            : () async {
                          setState(() => _isLoggingOut = true);
                          try {
                            await authNotifier.logout();
                          } catch (e) {
                            if (mounted) {
                              setState(() => _isLoggingOut = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Logout gagal: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoggingOut)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}