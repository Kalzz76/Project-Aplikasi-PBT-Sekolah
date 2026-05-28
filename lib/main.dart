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
  bool _hasSeenSplash = false;
  bool _splashAnimationFinished = false;

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
        if (mounted) {
          setState(() {
            _selectedRole = null;
            _hasSeenSplash = true; // Pastikan skip splash saat logout
            _splashAnimationFinished = true;
          });
        }
      });
    }

    // 1. Jika sudah login dan animasi splash pembuka selesai
    if (provider.isLoggedIn && _splashAnimationFinished) {
      return const MainLayout();
    }

    // 2. Jika belum pilih role, atau masih menunggu animasi splash pembuka
    if (_selectedRole == null || (provider.isLoggedIn && !_splashAnimationFinished)) {
      return SplashScreen(
        skipAnimation: _hasSeenSplash,
        onFinished: () {
          if (mounted) {
            setState(() {
              _splashAnimationFinished = true;
            });
          }
        },
        onRoleSelected: (role) {
          setState(() {
            _selectedRole = role;
            _hasSeenSplash = true;
            _splashAnimationFinished = true;
          });
        },
      );
    }

    // 3. Jika sudah pilih role tapi belum login, tampilkan Portal Login
    return LoginView(
      selectedRole: _selectedRole!,
      onBack: () => setState(() => _selectedRole = null),
    );
  }
}
