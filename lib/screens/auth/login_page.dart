import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwidget/components/appbar/gf_appbar.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/getwidget.dart'; // Added this import
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Added this import
import '../../providers/app_providers.dart';
import '../../services/notification_service.dart';
import '../../data/dummy_data.dart';
import '../../widgets/neumorphic_header.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Login / Register'),
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
                    Image.asset('assets/images/Ori.png', height: 100),
                    const SizedBox(height: 24),
                    Text(
                      'Selamat datang',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masuk untuk mulai menggunakan SuperAuto',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
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
                        labelText: 'Password',
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
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                    ),
                    const SizedBox(height: 24),
                    GFButton(
                      color: Theme.of(context).colorScheme.primary,
                      fullWidthButton: true,
                      // In login_page.dart, update the onPressed handler:
                      onPressed: () async {
                        final email = emailController.text;
                        final password = passwordController.text;

                        print('Starting login process for: $email');

                        try {
                          final user = await ref.read(authProvider.notifier).login(email, password);
                          print('Login result - User: ${user?.email}');

                          if (user != null) {
                            print('Login successful, initializing notifications...');
                            await NotificationService().init();
                            print('Notifications initialized, seeding dummy data...');
                            seedDummyData(ref);

                            if (context.mounted) {
                              print('Navigating to home page...');
                              if (user.role == 'admin') {
                                print('Admin user detected, going to admin panel');
                                context.go('/admin');
                              } else {
                                print('Regular user, going to splash screen');
                                context.go('/home');
                              }
                            } else {
                              print('Context not mounted after login');
                            }
                          } else {
                            print('Login failed: Invalid credentials');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Email atau password salah')),
                              );
                            }
                          }
                        } catch (e, stack) {
                          print('Login error: $e\n$stack');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Login gagal: $e')),
                            );
                          }
                        }
                      },
                      child: Text('Masuk', style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onPrimary)),
                      size: GFSize.LARGE,
                      shape: GFButtonShape.pills,
                    ),
                    const SizedBox(height: 16),
                    GFButton(
                      type: GFButtonType.outline,
                      fullWidthButton: true,
                      onPressed: () {
                        context.push('/register');
                      },
                      child: Text('Daftar', style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary)),
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