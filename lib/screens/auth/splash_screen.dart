import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
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
    await auth.init();
    final session = await sb.Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final user = session.user;
    } else {
    }

    if (isFirstLaunch) {
      await prefs.setBool('first_launch', false);
    }

    final authState = ref.read(authProvider);
    authState.when(
      data: (user) {
        if (mounted) {
          _navigateBasedOnUser(user);
        }
      },
      loading: () {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _checkFirstLaunch();
          }
        });
      },
      error: (error, stack) {
        if (mounted) {
          context.go('/login');
        }
      },
    );
  }

  void _navigateBasedOnUser(User? user) {
    if (user == null) {
      context.go('/login');
    } else if (user.role == 'admin') {
      context.go('/admin');
    } else {
      context.go('/home');
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
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}