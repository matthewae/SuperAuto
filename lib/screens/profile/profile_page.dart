import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic_header.dart';
import '../../providers/app_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(userStateProvider);

    return Scaffold(
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
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
                  // ... rest of the widgets
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
    );
  }
}
