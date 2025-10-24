import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/auth_provider.dart';
import 'providers/izin_provider.dart';
import 'providers/presensi_provider.dart';
import 'providers/jadwal_provider.dart';
import 'providers/tukar_shift_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/lembur_provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'data/services/dio_service.dart';
import 'data/services/cache_manager_service.dart';
import 'data/services/firebase_messaging_service.dart';

import 'data/models/tukar_shift_model.dart';

import './pages/auth/login_page.dart' as auth;
import './pages/home_page.dart';
import './pages/profile_page.dart';
import './pages/auth/ganti_password_page.dart';
import './pages/absensi_page.dart';
import './pages/data_absensi_page.dart';
import './pages/jadwal_page.dart';
import './pages/detail_izin_page.dart';
import './pages/detail_lembur_page.dart';
import './pages/notification_page.dart';
import './pages/history_absensi_page.dart';
import './pages/tukar_shift/tukar_shift_detail_page.dart';
import './components/customNavbar.dart';

// Global navigator key untuk navigasi dari background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Initialize DIO Service
  await DioService().initialize();

  // ✅ AUTO CLEANUP CACHE (7 days)
  await CacheManagerService.autoCleanup();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    await FirebaseMessagingService.initialize(navigatorKey: navigatorKey);
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
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
        ChangeNotifierProvider(create: (_) => LemburProvider()),
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
          AppRoutes.historyAbsensi: (context) => const HistoryAbsensiPage(),
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

          if (settings.name == AppRoutes.detailLembur) {
            final lemburId = settings.arguments as int?;
            if (lemburId != null) {
              return MaterialPageRoute(
                builder: (context) => DetailLemburPage(lemburId: lemburId),
              );
            }
          }

          if (settings.name == AppRoutes.detailTukarShift) {
            final tukarShiftId = settings.arguments as int?;
            if (tukarShiftId != null) {
              // Load detail dan tampilkan dalam wrapper yang simple
              return MaterialPageRoute(
                builder: (context) =>
                    _TukarShiftDetailLoader(tukarShiftId: tukarShiftId),
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

    debugPrint('🔄 Initializing auth...');
    await authProvider.initAuth();

    if (!mounted) return;

    // Fade out animation
    await _animationController.reverse();

    if (!mounted) return;

    debugPrint(
      '🎯 Auth state: ${authProvider.isAuthenticated ? "Authenticated" : "Unauthenticated"}',
    );

    if (authProvider.isAuthenticated) {
      debugPrint('✅ User authenticated - navigating to home');
      Navigator.pushReplacementNamed(context, AppRoutes.home);

      // Mark app as ready and process pending notification
      Future.delayed(const Duration(milliseconds: 300), () {
        FirebaseMessagingService.markAppReady();
      });
    } else {
      debugPrint('❌ User not authenticated - navigating to login');
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

class _MainAppState extends State<MainApp>
    with RouteAware, WidgetsBindingObserver {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // ✅ NEW: Track loading states untuk instant shimmer
  bool _isLoadingBeranda = false;
  bool _isLoadingRiwayat = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseMessagingService.markAppReady();
      _refreshCurrentPage();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App resumed - checking auth state');
      _checkAuthState();
    }
  }

  Future<void> _checkAuthState() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final isValid = await authProvider.isTokenValid();

    if (!isValid && authProvider.isAuthenticated) {
      debugPrint('⚠️ Token invalid - logging out');
      await authProvider.logout();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else if (isValid) {
      debugPrint('✅ Token still valid - refreshing data');
      _refreshCurrentPage();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  // ✅ UPDATED: Refresh dengan instant shimmer state
  Future<void> _refreshCurrentPage() async {
    if (!mounted) return;

    if (_currentIndex == 0) {
      // Set loading state IMMEDIATELY untuk instant shimmer
      setState(() => _isLoadingBeranda = true);

      try {
        await Future.wait([
          context.read<PresensiProvider>().loadPresensiData(),
          context.read<NotificationProvider>().loadUnreadCount(),
        ]);
      } finally {
        if (mounted) {
          setState(() => _isLoadingBeranda = false);
        }
      }
    } else if (_currentIndex == 1) {
      setState(() => _isLoadingRiwayat = true);

      try {
        final presensiProvider = context.read<PresensiProvider>();
        await presensiProvider.loadPresensiData();

        // Load statistik untuk data absensi page
        final presensiData = presensiProvider.presensiData;
        if (presensiData?.projectInfo != null) {
          final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
          await presensiProvider.loadStatistikPeriode(currentMonth);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingRiwayat = false);
        }
      }
    }
  }

  // ✅ UPDATED: Tab change dengan instant shimmer
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

    // ✅ ALWAYS refresh on tab change dengan instant shimmer
    _refreshCurrentPage();
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
        children: [
          // ✅ Pass loading state ke HomePage
          HomePage(isForceLoading: _isLoadingBeranda),
          // ✅ Pass loading state ke DataAbsensiPage
          DataAbsensiPage(isForceLoading: _isLoadingRiwayat),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CustomBottomNavBar(
          circleRadius: 50,
          currentIndex: _currentIndex,
          onTabSelected: _onTabTapped,
        ),
      ),
    );
  }
}

// Tambahkan di akhir file main.dart, setelah class _MainAppState
class _TukarShiftDetailLoader extends StatefulWidget {
  final int tukarShiftId;

  const _TukarShiftDetailLoader({required this.tukarShiftId});

  @override
  State<_TukarShiftDetailLoader> createState() =>
      _TukarShiftDetailLoaderState();
}

class _TukarShiftDetailLoaderState extends State<_TukarShiftDetailLoader> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // ✅ Panggil setelah frame pertama selesai build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndNavigate();
    });
  }

  Future<void> _loadAndNavigate() async {
    final provider = Provider.of<TukarShiftProvider>(context, listen: false);

    // Load requests if empty
    if (provider.requests.isEmpty) {
      await provider.loadTukarShiftRequests();
    }

    if (!mounted) return;

    // Find the request
    TukarShiftRequest? request;
    try {
      request = provider.requests.firstWhere(
        (r) => r.id == widget.tukarShiftId,
      );
    } catch (e) {
      request = null;
    }

    if (request != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TukarShiftDetailPage(request: request!),
        ),
      );
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Data tukar shift tidak ditemukan';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 253, 253),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.02,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: screenWidth * 0.045,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Detail Tukar Shift",
                    style: TextStyle(
                      fontSize: screenWidth * 0.048,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(width: screenWidth * 0.1),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : Center(
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.06),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.error.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage ?? 'Data tidak ditemukan',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Kembali'),
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
}
