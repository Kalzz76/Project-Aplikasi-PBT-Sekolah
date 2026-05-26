import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/app_avatar.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _pendingAvatarPath;
  Uint8List? _webImageBytes;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().currentUser;
    _nameController.text = user.name;
    _usernameController.text = user.username;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && (result.files.single.path != null || result.files.single.bytes != null)) {
      if (kIsWeb) {
        setState(() {
          _webImageBytes = result.files.single.bytes;
        });
      } else {
        setState(() {
          _pendingAvatarPath = result.files.single.path;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profil Saya',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 32),

        // HEADER SECTION
        CustomCard(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: _pendingAvatarPath != null 
                      ? CircleAvatar(radius: 50, backgroundImage: FileImage(File(_pendingAvatarPath!)))
                      : (kIsWeb && _webImageBytes != null)
                        ? CircleAvatar(radius: 50, backgroundImage: MemoryImage(_webImageBytes!))
                        : AppAvatar(radius: 50, fontSize: 32, imageUrl: user.avatar, name: user.name),
                  ),
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(LucideIcons.camera, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('@${user.username}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(user.role.name.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),

        // DATA DIRI SECTION
        const Text('Data Diri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        CustomCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField('Nama Lengkap', _nameController, LucideIcons.user),
              const SizedBox(height: 24),
              _buildField('Username', _usernameController, LucideIcons.user),
              const SizedBox(height: 24),
              _buildField(
                'Password', 
                _passwordController, 
                LucideIcons.lock, 
                isPassword: true,
                suffix: IconButton(
                  icon: Icon(_obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    variant: ButtonVariant.outline,
                    child: const Text('Batalkan'),
                    onClick: () => context.read<AppProvider>().setActiveMenu('dashboard'),
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    child: const Text('Simpan Perubahan'),
                    onClick: () {
                      if (_nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama tidak boleh kosong.')));
                        return;
                      }
                      
                      // Save profile data + avatar to Provider
                      context.read<AppProvider>().updateProfile(
                        name: _nameController.text,
                        username: _usernameController.text,
                        password: _passwordController.text,
                        avatar: _pendingAvatarPath, // Pass the new local path to save permanently
                      );

                      _passwordController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Colors.green),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool isPassword = false, Widget? suffix}) {
    final bool secure = isPassword == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: secure ? (_obscurePassword == true) : false,
          enableSuggestions: !secure,
          autocorrect: !secure,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: suffix,
            hintText: secure ? 'Isi untuk ubah password' : '',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
      ],
    );
  }
}
