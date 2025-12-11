import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:getwidget/getwidget.dart'; // Added this import
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;
  late final TextEditingController nameController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Error messages for validation
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    nameController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  // Validasi nama
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }

    if (value.length < 3) {
      return 'Nama minimal 3 karakter';
    }

    return null;
  }

  // Validasi email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }

    // Regex untuk validasi email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  // Validasi password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }

    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }

    return null;
  }

  // Validasi konfirmasi password
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }

    if (value != passwordController.text) {
      return 'Password dan konfirmasi password tidak cocok';
    }

    return null;
  }

  // Validasi form sebelum submit
  bool _validateForm() {
    setState(() {
      _nameError = _validateName(nameController.text);
      _emailError = _validateEmail(emailController.text);
      _passwordError = _validatePassword(passwordController.text);
      _confirmPasswordError = _validateConfirmPassword(confirmPasswordController.text);
    });

    return _nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;
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
                    Image.asset('assets/images/Ori.png', height: 100),
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
                        errorText: _nameError,
                      ),
                      onChanged: (value) {
                        // Clear error when user starts typing
                        if (_nameError != null) {
                          setState(() {
                            _nameError = null;
                          });
                        }
                      },
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
                        errorText: _emailError,
                      ),
                      onChanged: (value) {
                        // Clear error when user starts typing
                        if (_emailError != null) {
                          setState(() {
                            _emailError = null;
                          });
                        }
                      },
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
                        errorText: _passwordError,
                      ),
                      obscureText: _obscurePassword,
                      onChanged: (value) {
                        // Clear error when user starts typing
                        if (_passwordError != null) {
                          setState(() {
                            _passwordError = null;
                          });
                        }

                        // Also validate confirm password if it has been entered
                        if (confirmPasswordController.text.isNotEmpty && _confirmPasswordError != null) {
                          setState(() {
                            _confirmPasswordError = _validateConfirmPassword(confirmPasswordController.text);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
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
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        errorText: _confirmPasswordError,
                      ),
                      obscureText: _obscureConfirmPassword,
                      onChanged: (value) {
                        // Clear error when user starts typing
                        if (_confirmPasswordError != null) {
                          setState(() {
                            _confirmPasswordError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    GFButton(
                      color: Theme.of(context).colorScheme.primary,
                      fullWidthButton: true,
                      onPressed: _isLoading ? null : () async {
                        // Validasi form sebelum submit
                        if (!_validateForm()) {
                          return;
                        }

                        setState(() {
                          _isLoading = true;
                        });

                        final auth = ref.read(authServiceProvider);

                        final result = await auth.register(
                          emailController.text,
                          passwordController.text,
                          nameController.text,
                        );

                        if (result != null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result)),
                            );
                          }
                          setState(() {
                            _isLoading = false;
                          });
                          return;
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Registrasi berhasil, silakan login.")),
                          );
                          context.go('/login');
                        }
                      },
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text("Buat Akun", style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onPrimary)),
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