import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../services/notification_service.dart';
import '../../data/dummy_data.dart';
import '../../widgets/neumorphic_header.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController(text: 'user@example.com');
    final passwordController = TextEditingController(text: 'password');
    return Scaffold(
      appBar: GFAppBar(title: const Text('Login / Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NeumorphicHeader(title: 'Selamat datang', subtitle: 'Masuk untuk mulai menggunakan SuperAuto'),
            const SizedBox(height: 16),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            GFButton(
              color: const Color(0xFF1E88E5),
              fullWidthButton: true,
              onPressed: () async {
                loginDummy(ref, email: emailController.text);
                await NotificationService().init();
                seedDummyData(ref);
                if (context.mounted) context.go('/home');
              },
              child: const Text('Masuk'),
            ),
            const SizedBox(height: 16),
            GFButton(
              type: GFButtonType.outline,
              fullWidthButton: true,
              onPressed: () async {
                loginDummy(ref, email: emailController.text);
                await NotificationService().init();
                seedDummyData(ref);
                if (context.mounted) context.go('/home');
              },
              child: const Text('Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}
