import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwidget/components/appbar/gf_appbar.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();

    return Scaffold(
      appBar: GFAppBar(title: const Text("Daftar Akun")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nama")),
            const SizedBox(height: 8),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            GFButton(
              fullWidthButton: true,
              onPressed: () async {
                final auth = ref.read(authServiceProvider);

                final result = await auth.register(
                  emailController.text,
                  passwordController.text,
                  nameController.text,
                );

                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result)),
                  );
                  return;
                }

                if (context.mounted) context.go('/');

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Registrasi berhasil, silakan login.")),
                );
              },
              child: const Text("Buat Akun"),
            ),
          ],
        ),
      ),
    );
  }
}
