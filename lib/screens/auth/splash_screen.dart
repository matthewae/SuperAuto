import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;
    final auth = ref.read(authServiceProvider);
    await auth.init(); // Initialize auth service to load current user
    final user = auth.currentUser();
    ref.read(userStateProvider.notifier).state = user;

    if (isFirstLaunch) {
      await prefs.setBool('first_launch', false);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          if (user != null) {
            if (user.role == 'admin') {
              context.go('/admin');
            } else {
              context.go('/home');
            }
          } else {
            context.go('/login');
          }
        }
      });
    } else {
      if (mounted) {
        if (user != null) {
          if (user.role == 'admin') {
            context.go('/admin');
          } else {
            context.go('/home');
          }
        } else {
          context.go('/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/Ori.png', height: 150),
            const SizedBox(height: 24),
            Text(
              'SuperAuto',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}