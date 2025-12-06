import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwidget/components/appbar/gf_appbar.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/getwidget.dart'; // Added this import
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Added this import
import '../../providers/app_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    nameController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Daftar Akun"),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Center(
              child: Container(
                width: constraints.maxWidth > 600 ? 400 : double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SvgPicture.asset('assets/logo.svg', height: 100),
                    const SizedBox(height: 24),
                    Text(
                      'Daftar Akun Baru',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buat akun Anda untuk mulai menggunakan SuperAuto',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Nama",
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                        ),
                        prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                        ),
                        prefixIcon: Icon(Icons.email, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                        ),
                        prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    GFButton(
                      color: Theme.of(context).colorScheme.primary,
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

                        if (context.mounted) context.go('/login');

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Registrasi berhasil, silakan login.")),
                        );
                      },
                      child: Text("Buat Akun", style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onPrimary)),
                      size: GFSize.LARGE,
                      shape: GFButtonShape.pills,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}