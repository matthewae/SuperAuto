import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
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

    // Listen to auth state changes
    ref.listen<AsyncValue<User?>>(
      authProvider,
          (_, next) {
        next.when(
          data: (user) {
            if (user == null && _isLoggingOut) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  // Use GoRouter's go method with replace: true to prevent going back
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  GFListTile(
                    title: const Text('Dark Mode'),
                    subTitle: const Text('Aktifkan tema gelap'),
                    icon: Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (_) =>
                          ref.read(themeModeProvider.notifier).toggle(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GFButton(
                    onPressed: _isLoggingOut
                        ? null
                        : () async {
                      setState(() => _isLoggingOut = true);
                      try {
                        await authNotifier.logout();
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isLoggingOut = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Logout gagal: $e')),
                          );
                        }
                      }
                    },
                    text: 'Logout',
                    color: GFColors.DANGER,
                    fullWidthButton: true,
                  ),
                ],
              ),
            ),
          ),
          if (_isLoggingOut)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}