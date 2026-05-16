import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_button.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF3730A3), Color(0xFF1E1B4B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
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
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
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
                        'Edusync',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Silakan login untuk mengakses dashboard',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 40),

                      // Inputs
                      _buildInputField(
                        label: 'Username / ID',
                        controller: _usernameController,
                        icon: LucideIcons.user,
                        hint: 'admin, guru, atau siswa',
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        label: 'Password',
                        controller: _passwordController,
                        icon: LucideIcons.lock,
                        isPassword: true,
                        hint: 'Masukkan password anda',
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                final emailController = TextEditingController();
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  title: const Text('Lupa Password?'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Masukkan email anda untuk meminta reset password kepada admin.'),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: emailController,
                                        decoration: InputDecoration(
                                          hintText: 'Email anda',
                                          prefixIcon: const Icon(LucideIcons.mail, size: 20),
                                          filled: true,
                                          fillColor: AppColors.background,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                                    CustomButton(
                                      onClick: () {
                                        if (emailController.text.isNotEmpty) {
                                          context.read<AppProvider>().requestPasswordReset(emailController.text);
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permintaan reset terkirim ke Admin.')));
                                        }
                                      },
                                      child: const Text('Kirim Permintaan'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text('Lupa Password?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
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
                          );
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Username atau Password salah!'),
                                backgroundColor: AppColors.danger,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const Text('Login ke Akun'),
                      ),
                      
                      const SizedBox(height: 24),
                      const Text(
                        'Demo hint: ketik "admin", "guru", atau "siswa"',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
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
