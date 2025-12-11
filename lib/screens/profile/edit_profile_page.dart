import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic_header.dart';
import '../../providers/app_providers.dart';
import 'package:superauto/models/user.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  bool _isChangingPassword = false;
  String? _errorMessage;
  bool _showPasswordWarning = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    try {
      final user = ref.read(authProvider).value;
      if (user != null) {
        setState(() {
          _nameController = TextEditingController(text: user.name);
          _emailController = TextEditingController(text: user.email);
          _currentPasswordController = TextEditingController();
          _newPasswordController = TextEditingController();
          _confirmPasswordController = TextEditingController();
        });
      }
    } catch (e) {
      _handleAuthError(e);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _handleAuthError(dynamic error) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().contains('Password saat ini tidak benar')
            ? 'Password saat ini tidak benar. Silakan coba lagi.'
            : 'Terjadi kesalahan. Silakan coba lagi.';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showPasswordWarning = false;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);

      if (!_isValidEmail(_emailController.text)) {
        throw Exception('Format email tidak valid');
      }

      if (_isChangingPassword) {
        if (_currentPasswordController.text.isEmpty ||
            _newPasswordController.text.isEmpty ||
            _confirmPasswordController.text.isEmpty) {
          throw Exception('Semua field password harus diisi');
        }

        if (_newPasswordController.text != _confirmPasswordController.text) {
          throw Exception('Password baru dan konfirmasi tidak cocok');
        }

        // Check if current password is correct
        final user = ref.read(authProvider).value;
        if (user != null) {
          final isPasswordCorrect = await ref.read(userDaoProvider).verifyPassword(
            user.id,
            _currentPasswordController.text,
          );

          if (!isPasswordCorrect) {
            setState(() {
              _showPasswordWarning = true;
              _isLoading = false;
            });
            return; // Don't proceed with update
          }
        }

        await authNotifier.updateProfile(
          name: _nameController.text,
          email: _emailController.text,
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );
      } else {
        await authNotifier.updateProfile(
          name: _nameController.text,
          email: _emailController.text,
        );
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil berhasil diperbarui!")),
      );

      // Navigate back to profile page instead of login
      if (mounted) {
        context.go('/profile');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().contains('Password saat ini tidak benar')
            ? 'Password saat ini tidak benar. Silakan coba lagi.'
            : 'Terjadi kesalahan. Silakan coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show error dialog if there's an error
    if (_errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(_errorMessage!),
            actions: [
              TextButton(
                onPressed: () {
                  if (mounted) {
                    setState(() => _errorMessage = null);
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }

    return authState.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Use GoRouter instead of Navigator
              context.go('/login');
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildContent(user);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(authProvider.notifier).logout();
            // Use GoRouter instead of Navigator
            context.go('/login');
          }
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildContent(User user) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
        title: const Text('Edit Profil'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: NeumorphicHeader(
              title: 'Edit Profil',
              subtitle: 'Perbarui informasi akun Anda',
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: const OutlineInputBorder(),
                      errorText: _emailController.text.isNotEmpty && !_isValidEmail(_emailController.text)
                          ? 'Format email tidak valid'
                          : null,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Ubah Password',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Switch(
                        value: _isChangingPassword,
                        onChanged: (value) {
                          setState(() {
                            _isChangingPassword = value;
                            _showPasswordWarning = false;
                            if (!value) {
                              _currentPasswordController.clear();
                              _newPasswordController.clear();
                              _confirmPasswordController.clear();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isChangingPassword) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password Saat Ini',
                        border: const OutlineInputBorder(),
                        errorText: _showPasswordWarning
                            ? 'Password saat ini tidak benar. Silakan coba lagi.'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password Baru',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        border: const OutlineInputBorder(),
                        errorText: _confirmPasswordController.text.isNotEmpty &&
                            _newPasswordController.text.isNotEmpty &&
                            _confirmPasswordController.text != _newPasswordController.text
                            ? 'Password baru dan konfirmasi tidak cocok'
                            : null,
                      ),
                    ),
                    if (_showPasswordWarning) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Password saat ini tidak benar. Silakan periksa kembali password Anda.',
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Simpan Perubahan'),
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