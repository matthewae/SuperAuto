import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic_header.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox.shrink(),
            const SizedBox(height: 12),
            GFListTile(
              title: const Text('Dark Mode'),
              subTitle: const Text('Aktifkan tema gelap'),
              icon: Switch(
                value: themeMode == ThemeMode.dark,
                onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              ),
            ),
            const SizedBox(height: 12),
            GFButton(
              onPressed: () {
                // TODO: Implement actual logout logic (e.g., clear session, call auth provider)
                context.go('/login');
              },
              text: 'Logout',
              blockButton: true,
              color: GFColors.DANGER,
            ),
          ],
        ),
      ),
    );
  }
}

