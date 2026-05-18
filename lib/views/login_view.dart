import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_button.dart';
import '../models/user.dart';

class LoginView extends StatefulWidget {
  final UserRole selectedRole;
  final VoidCallback onBack;

  const LoginView({
    super.key,
    required this.selectedRole,
    required this.onBack,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  String get _roleName {
    switch (widget.selectedRole) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.guru:
        return 'Guru Pengajar';
      case UserRole.siswa:
        return 'Siswa Terdaftar';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Back Button
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 28),
                onPressed: widget.onBack,
                tooltip: 'Kembali ke Pilihan Akses',
              ),
            ),

            // Decorative circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Container(
                  width: 450,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(LucideIcons.bookOpen, color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Classio',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Portal Login $_roleName',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Silakan masukkan kredensial anda',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 40),

                      // Inputs
                      _buildInputField(
                        label: 'Username / ID',
                        controller: _usernameController,
                        icon: LucideIcons.user,
                        hint: 'Masukkan username anda',
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        label: 'Password',
                        controller: _passwordController,
                        icon: LucideIcons.lock,
                        isPassword: true,
                        hint: 'Masukkan password anda',
                      ),
                      const SizedBox(height: 32),

                      // Login Button
                      CustomButton(
                        width: double.infinity,
                        size: ButtonSize.lg,
                        onClick: () {
                          final success = context.read<AppProvider>().login(
                            _usernameController.text,
                            _passwordController.text,
                            widget.selectedRole,
                          );
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Akses Ditolak: Pastikan Username/Password benar dan anda login sebagai $_roleName'),
                                backgroundColor: AppColors.danger,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const Text('Login ke Akun'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
            suffixIcon: isPassword ? IconButton(
              icon: Icon(_isPasswordVisible ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ) : null,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
