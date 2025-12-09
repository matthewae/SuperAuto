import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../providers/app_providers.dart';
import '../../widgets/neumorphic_header.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {

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
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: NeumorphicHeader(title: 'Profil', subtitle: 'Kelola akun Anda'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.onPrimaryContainer),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ListTile(
                        leading: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        title: Text('Edit Profil', style: Theme.of(context).textTheme.titleMedium),
                        trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 16),
                        onTap: () {
                          context.push('/edit-profile');
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        title: Text('Dark Mode', style: Theme.of(context).textTheme.titleMedium),
                        trailing: Switch(
                          value: themeMode == ThemeMode.dark,
                          onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement actual logout logic (e.g., clear session, call auth provider)
                          context.go('/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Logout', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onError)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoggingOut)
            Container(
              color: Colors.black.withAlpha((255 * 0.5).round()),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
