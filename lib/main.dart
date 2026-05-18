import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_theme.dart';
import 'providers/app_provider.dart';
import 'views/main_layout.dart';
import 'views/splash_screen.dart';
import 'views/login_view.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (e) {
    debugPrint("Initialization error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  UserRole? _selectedRole;
  bool _wasLoggedIn = false; // Flag untuk mendeteksi transisi logout

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // DETEKSI LOGOUT: Hanya reset role jika status berubah dari login -> tidak login
    if (provider.isLoggedIn && !_wasLoggedIn) {
      _wasLoggedIn = true;
    } else if (!provider.isLoggedIn && _wasLoggedIn) {
      _wasLoggedIn = false;
      // Gunakan delay agar tidak terjadi setState saat build
      Future.delayed(Duration.zero, () {
        if (mounted) setState(() => _selectedRole = null);
      });
    }

    // 1. Jika sudah login, tampilkan Dashboard
    if (provider.isLoggedIn) {
      return const MainLayout();
    }

    // 2. Jika belum pilih role, tampilkan Splash + Role Selection
    if (_selectedRole == null) {
      return SplashScreen(
        onRoleSelected: (role) => setState(() => _selectedRole = role),
      );
    }

    // 3. Jika sudah pilih role tapi belum login, tampilkan Portal Login
    return LoginView(
      selectedRole: _selectedRole!,
      onBack: () => setState(() => _selectedRole = null),
    );
  }
}
