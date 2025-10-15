import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/auth_provider.dart';
import 'providers/izin_provider.dart';
import 'providers/presensi_provider.dart';
import 'providers/jadwal_provider.dart';
import 'providers/tukar_shift_provider.dart';
import 'providers/notification_provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'data/services/firebase_messaging_service.dart';

import './pages/auth/login_page.dart' as auth;
import './pages/home_page.dart';
import './pages/profile_page.dart';
import './pages/auth/ganti_password_page.dart';
import './pages/absensi_page.dart';
import './pages/data_absensi_page.dart';
import './pages/jadwal_page.dart';
import './pages/tukar_shift/tukar_shift_page.dart';
import './pages/detail_izin_page.dart';
import './pages/notification_page.dart';
import './components/customNavbar.dart';

// Global navigator key untuk navigasi dari background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');

    // Initialize Firebase Messaging dengan navigator key
    await FirebaseMessagingService.initialize(navigatorKey: navigatorKey);
    print('Firebase Messaging initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => IzinProvider()),
        ChangeNotifierProvider(create: (_) => PresensiProvider()),
        ChangeNotifierProvider(create: (_) => JadwalProvider()),
        ChangeNotifierProvider(create: (_) => TukarShiftProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'PT Qiprah Multi Service',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.white,
          fontFamily: 'Roboto',
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        routes: {
          AppRoutes.login: (context) => const auth.LoginPage(),
          AppRoutes.home: (context) => const MainApp(),
          AppRoutes.profile: (context) => const ProfilePage(),
          AppRoutes.changePassword: (context) => const GantiPasswordPage(),
          AppRoutes.absensi: (context) => const AbsensiPage(),
          AppRoutes.jadwal: (context) => const JadwalPage(),
          AppRoutes.notifications: (context) => const NotificationPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.detailIzin) {
            final izinId = settings.arguments as int?;
            if (izinId != null) {
              return MaterialPageRoute(
                builder: (context) => DetailIzinPage(izinId: izinId),
              );
            }
          }
          return null;
        },
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initAuth();

    if (!mounted) return;

    // Fade out animation
    await _animationController.reverse();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);

      // Mark app as ready and process pending notification
      Future.delayed(const Duration(milliseconds: 300), () {
        FirebaseMessagingService.markAppReady();
      });
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppColors.primary.withOpacity(0.05)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _rotateAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotateAnimation.value * 0.5,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.only(top: screenWidth * 0.03),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.business_rounded,
                                  size: 70,
                                  color: AppColors.primary,
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(
                              0.3,
                              0.8,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                    child: const Text(
                      'PT Qiprah Multi Service',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'Sistem Presensi Karyawan',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                      ),
                    ),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with RouteAware {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final Map<int, DateTime> _lastRefreshTime = {};

  @override
  void initState() {
    super.initState();

    // Mark app as ready untuk handle notification navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseMessagingService.markAppReady();
      _refreshCurrentPage();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _shouldRefresh(int index) {
    final lastRefresh = _lastRefreshTime[index];
    if (lastRefresh == null) return true;

    // Refresh jika sudah lebih dari 30 detik
    final now = DateTime.now();
    return now.difference(lastRefresh).inSeconds > 30;
  }

  Future<void> _refreshCurrentPage() async {
    if (!mounted) return;

    _lastRefreshTime[_currentIndex] = DateTime.now();

    if (_currentIndex == 0) {
      // Refresh HomePage data
      context.read<PresensiProvider>().loadPresensiData();
      context.read<NotificationProvider>().loadUnreadCount();
    } else if (_currentIndex == 1) {
      // Refresh DataAbsensiPage data
      context.read<PresensiProvider>().loadPresensiData();
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Auto-refresh data dengan debouncing
    if (_shouldRefresh(index)) {
      _refreshCurrentPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        physics: const NeverScrollableScrollPhysics(),
        children: const [HomePage(), DataAbsensiPage()],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        circleRadius: 50,
        currentIndex: _currentIndex,
        onTabSelected: _onTabTapped,
      ),
    );
  }
}
