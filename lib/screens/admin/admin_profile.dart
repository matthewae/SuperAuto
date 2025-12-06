import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Placeholder for an authentication service
class AuthService extends StateNotifier<bool> {
  AuthService() : super(true); // true means logged in

  void logout() {
    state = false; // Set state to logged out
    print('Admin logged out');
  }
}

final authServiceProvider = StateNotifierProvider<AuthService, bool>((ref) {
  return AuthService();
});

class AdminProfilePage extends ConsumerWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            GFButton(
              onPressed: () {
                ref.read(authServiceProvider.notifier).logout();
                context.go('/login');
              },
              text: 'Logout Admin',
              blockButton: true,
              color: GFColors.DANGER,
            ),
          ],
        ),
      ),
    );
  }
}
