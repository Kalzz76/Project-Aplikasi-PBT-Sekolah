import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/user.dart';

class SplashScreen extends StatefulWidget {
  final Function(UserRole) onRoleSelected;
  const SplashScreen({super.key, required this.onRoleSelected});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _ctrl;

  // --- PHASE 1: SPLASH ---
  late Animation<double> _logoScale;
  late Animation<double> _capOpacity;
  late Animation<double> _capY;
  late Animation<double> _nameOpacity;
  late Animation<double> _nameSpacing;
  late Animation<double> _tagOpacity;
  late Animation<double> _tagY;
  late Animation<double> _progressOpacity;
  late Animation<double> _progressBarWidth;
  late Animation<double> _splashOpacity;

  // --- PHASE 2: WELCOME ---
  late Animation<double> _appContentOpacity;
  late Animation<double> _welcomeTitleOpacity;
  late Animation<double> _welcomeTitleScale;
  late Animation<double> _welcomeGroupY;
  late Animation<double> _welcomeSubtitleOpacity;
  late Animation<double> _welcomeSubtitleY;

  // Cards Intro Animation
  late Animation<double> _card1Opacity;
  late Animation<double> _card1Y;
  late Animation<double> _card2Opacity;
  late Animation<double> _card2Y;
  late Animation<double> _card3Opacity;
  late Animation<double> _card3Y;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 8500));

    // 1. SPLASH ANIMATION
    _logoScale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.0, 0.12, curve: Curves.elasticOut)));
    
    _capOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.07, 0.15, curve: Curves.easeOut)));
    _capY = Tween(begin: 0.0, end: -5.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.07, 0.15, curve: Curves.easeOut)));

    _nameOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.1, 0.2, curve: Curves.easeOut)));
    _nameSpacing = Tween(begin: 0.0, end: 8.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.1, 0.2, curve: Curves.easeOut)));

    _tagOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.12, 0.22, curve: Curves.easeOut)));
    _tagY = Tween(begin: 0.0, end: -10.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.12, 0.22, curve: Curves.easeOut)));

    _progressOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.18, 0.23, curve: Curves.linear)));
    _progressBarWidth = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.23, 0.38, curve: Curves.easeInOut)));

    // 2. EXIT SPLASH
    _splashOpacity = Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.4, 0.48, curve: Curves.easeInOut)));

    // 3. WELCOME TITLE ZOOM IN
    _appContentOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.48, 0.49, curve: Curves.linear)));
    _welcomeTitleOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.49, 0.59, curve: Curves.easeOut)));
    _welcomeTitleScale = Tween(begin: 0.75, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.49, 0.59, curve: Curves.easeOutBack)));

    // 4. WELCOME GROUP MOVE
    _welcomeGroupY = Tween(begin: 0.0, end: -150.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.65, 0.75, curve: Curves.easeInOutExpo)));
    _welcomeSubtitleOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.71, 0.79, curve: Curves.easeOut)));
    _welcomeSubtitleY = Tween(begin: 0.0, end: -5.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.71, 0.79, curve: Curves.easeOut)));

    // 5. CARDS STAGGER
    _card1Opacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.76, 0.84, curve: Curves.easeOutCubic)));
    _card1Y = Tween(begin: 30.0, end: 0.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.76, 0.84, curve: Curves.easeOutCubic)));

    _card2Opacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.81, 0.89, curve: Curves.easeOutCubic)));
    _card2Y = Tween(begin: 30.0, end: 0.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.81, 0.89, curve: Curves.easeOutCubic)));

    _card3Opacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.86, 0.94, curve: Curves.easeOutCubic)));
    _card3Y = Tween(begin: 30.0, end: 0.0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.86, 0.94, curve: Curves.easeOutCubic)));

    // Add a slight delay before starting to prevent initial frame lag
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // MAIN APP CONTENT
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => Opacity(
              opacity: _appContentOpacity.value,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFFF0F7FF),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: Offset(0, _welcomeGroupY.value),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Opacity(
                              opacity: _welcomeTitleOpacity.value,
                              child: Transform.scale(
                                scale: _welcomeTitleScale.value,
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: const TextSpan(
                                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A), fontFamily: 'Inter'),
                                    children: [
                                      TextSpan(text: 'Selamat datang di '),
                                      TextSpan(text: 'Classio', style: TextStyle(color: Color(0xFF2563EB))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Opacity(
                              opacity: _welcomeSubtitleOpacity.value,
                              child: Transform.translate(
                                offset: Offset(0, _welcomeSubtitleY.value),
                                child: const Text(
                                  'Pilih akses masuk Anda untuk memulai',
                                  style: TextStyle(color: Color(0xFF3B82F6), fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: const Offset(0, 70), // Moved up from 180
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            alignment: WrapAlignment.center,
                            children: [
                              _RoleCardWrapper(
                                opacity: _card1Opacity.value,
                                introTranslateY: _card1Y.value,
                                icon: LucideIcons.settings,
                                title: 'Administrator',
                                desc: 'Kelola kurikulum, data sekolah, dan sistem keseluruhan',
                                onTap: () => widget.onRoleSelected(UserRole.admin),
                              ),
                              _RoleCardWrapper(
                                opacity: _card2Opacity.value,
                                introTranslateY: _card2Y.value,
                                icon: LucideIcons.bookOpen,
                                title: 'Guru Pengajar',
                                desc: 'Pantau perkembangan siswa dan kelola materi belajar',
                                onTap: () => widget.onRoleSelected(UserRole.guru),
                              ),
                              _RoleCardWrapper(
                                opacity: _card3Opacity.value,
                                introTranslateY: _card3Y.value,
                                icon: LucideIcons.user,
                                title: 'Siswa Terdaftar',
                                desc: 'Akses kelas online, tugas, dan raih prestasi terbaikmu',
                                onTap: () => widget.onRoleSelected(UserRole.siswa),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // SPLASH CONTAINER
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => _splashOpacity.value > 0
                ? Opacity(
                    opacity: _splashOpacity.value,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: _logoScale.value,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(LucideIcons.bookOpen, color: Colors.white, size: 96, shadows: [Shadow(color: Color(0x66BFDBFE), blurRadius: 20)]),
                                Positioned(
                                  top: -16,
                                  right: -16,
                                  child: Opacity(
                                    opacity: _capOpacity.value,
                                    child: Transform.translate(
                                      offset: Offset(0, _capY.value),
                                      child: const Icon(LucideIcons.graduationCap, color: Color(0xFF93C5FD), size: 40),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Opacity(
                            opacity: _nameOpacity.value,
                            child: Text(
                              'CLASSIO',
                              style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: _nameSpacing.value),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Opacity(
                            opacity: _tagOpacity.value,
                            child: Transform.translate(
                              offset: Offset(0, _tagY.value),
                              child: const Text('Pendidikan Tanpa Batas', style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 14, letterSpacing: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Opacity(
                            opacity: _progressOpacity.value,
                            child: Container(
                              width: 200,
                              height: 4,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: _progressBarWidth.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF60A5FA),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [BoxShadow(color: const Color(0xFF60A5FA).withOpacity(0.6), blurRadius: 10)],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// Helper Widget for Hover Interaction
class _RoleCardWrapper extends StatefulWidget {
  final double opacity;
  final double introTranslateY;
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _RoleCardWrapper({
    required this.opacity,
    required this.introTranslateY,
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  State<_RoleCardWrapper> createState() => _RoleCardWrapperState();
}

class _RoleCardWrapperState extends State<_RoleCardWrapper> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.opacity,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutQuint,
            transform: Matrix4.translationValues(0, widget.introTranslateY + (_isHovered ? -12.0 : 0.0), 0),
            width: 280,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isHovered ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0).withOpacity(0.8),
                width: _isHovered ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered ? const Color(0xFF2563EB).withOpacity(0.12) : const Color(0x08000000),
                  blurRadius: _isHovered ? 40 : 30,
                  offset: Offset(0, _isHovered ? 20 : 10),
                  spreadRadius: _isHovered ? 0 : -5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuint,
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _isHovered ? const Color(0xFF2563EB).withOpacity(0.1) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.icon, 
                      color: const Color(0xFF2563EB), 
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.title, 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.desc, 
                    textAlign: TextAlign.center, 
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
